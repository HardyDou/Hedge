# iCloud Drive 同步实施指南（用户可见文件夹方案）

**版本**: 1.0
**日期**: 2026-03-01
**优先级**: P1 (高)
**方案**: 类似 1Password 7 的 iCloud Drive 实现

---

## 1. 概述

本文档提供使用 **iCloud Drive 用户可见文件夹** 实现跨设备同步的详细技术方案。

### 1.1 方案对比

| 特性 | iCloud Documents（容器） | iCloud Drive（用户可见） |
|------|------------------------|------------------------|
| 用户可见性 | ❌ 不可见 | ✅ 可见（文件 App） |
| 文件管理 | 应用控制 | 用户可管理 |
| 导出/备份 | 需要应用提供 | 用户可直接操作 |
| 实施难度 | 🟡 中等 | 🟢 **简单** |
| 配置复杂度 | 需要 Entitlements | **仅需 Info.plist** |
| 同步速度 | 实时 | 实时 |
| 适用场景 | 应用完全控制 | 用户需要访问文件 |

### 1.2 为什么选择 iCloud Drive？

**优点**:
- ✅ **实施更简单**：无需复杂的 Entitlements 配置
- ✅ **用户可见**：用户可以在"文件"App 中看到和管理 vault.db
- ✅ **易于备份**：用户可以手动导出文件
- ✅ **易于迁移**：用户可以直接复制文件到其他设备
- ✅ **调试友好**：开发时可以直接查看文件

**缺点**:
- ⚠️ **用户可能误删**：文件暴露给用户，可能被误删
- ⚠️ **隐私风险**：文件名可见（但内容加密）

**1Password 7 的选择**: 1Password 7 使用此方案，证明其可行性和用户接受度。

---

## 2. 技术实现

### 2.1 存储路径

**iCloud Drive 路径**:
```
iCloud Drive/
└── Hedge/
    └── vault.db
```

**实际路径**:
```
~/Library/Mobile Documents/com~apple~CloudDocs/Hedge/vault.db
```

**用户视角**（文件 App）:
```
iCloud Drive/
└── Hedge/
    └── vault.db
```

---

## 3. 实施步骤

### 步骤 1: 配置 Info.plist（iOS）

**文件路径**: `ios/Runner/Info.plist`

**已有配置**（保持不变）:
```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UISupportsDocumentBrowser</key>
<true/>
```

**无需额外配置**！iCloud Drive 会自动启用（如果用户登录了 iCloud）。

---

### 步骤 2: 配置 Info.plist（macOS）

**文件路径**: `macos/Runner/Info.plist`

添加以下配置：

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>NSUbiquitousContainers</key>
<dict>
    <key>NSUbiquitousContainerIsDocumentScopePublic</key>
    <true/>
</dict>
```

---

### 步骤 3: 更新 Entitlements（macOS）

**文件路径**: `macos/Runner/Release.entitlements` 和 `macos/Runner/DebugProfile.entitlements`

添加 iCloud Drive 权限：

```xml
<!-- 在现有配置中添加 -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- 可选：如果需要访问 iCloud Drive -->
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
    <string>iCloud.com.hardydou.hedge</string>
</array>
```

**注意**: iOS 不需要 Entitlements 文件，iCloud Drive 会自动工作。

---

### 步骤 4: 实现 iCloud Drive 路径获取（Dart）

**文件路径**: `lib/presentation/providers/vault_provider.dart`

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VaultNotifier extends StateNotifier<VaultState> {
  // ... 现有代码

  /// 获取 iCloud Drive 路径
  static Future<String?> _getICloudDrivePath() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return null;
    }

    try {
      // iOS/macOS iCloud Drive 路径
      final home = Platform.environment['HOME'];
      if (home == null) return null;

      final iCloudDrivePath = '$home/Library/Mobile Documents/com~apple~CloudDocs';
      final iCloudDir = Directory(iCloudDrivePath);

      // 检查 iCloud Drive 是否可用
      if (await iCloudDir.exists()) {
        // 创建应用专属文件夹
        final appFolder = Directory('$iCloudDrivePath/Hedge');
        if (!await appFolder.exists()) {
          await appFolder.create(recursive: true);
        }

        print('[iCloud Drive] Path: ${appFolder.path}');
        return appFolder.path;
      } else {
        print('[iCloud Drive] Not available');
        return null;
      }
    } catch (e) {
      print('[iCloud Drive] Error: $e');
      return null;
    }
  }

  /// 检查 iCloud Drive 是否可用
  static Future<bool> isICloudDriveAvailable() async {
    final path = await _getICloudDrivePath();
    return path != null;
  }

  /// 获取默认 vault 路径（优先使用 iCloud Drive）
  static Future<String> _getDefaultVaultPath() async {
    // iOS/macOS: 优先使用 iCloud Drive
    if (Platform.isIOS || Platform.isMacOS) {
      final iCloudPath = await _getICloudDrivePath();
      if (iCloudPath != null) {
        return '$iCloudPath/vault.db';
      } else {
        print('[Vault] iCloud Drive not available, using local storage');
      }
    }

    // Fallback: 使用本地 Documents 目录
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/vault.db';
  }
}
```

---

### 步骤 5: 实现文件监听（Dart）

**方案**: 使用 Dart 的 `FileSystemEntity.watch()` 监听文件变化

**文件路径**: `lib/platform/ios_sync_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:hedge/services/sync_service.dart';

class IOSSyncService implements SyncService {
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  StreamSubscription? _fileWatcher;
  String? _vaultPath;
  DateTime? _lastModification;

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    _vaultPath = vaultPath;

    final file = File(vaultPath);
    if (await file.exists()) {
      _lastModification = await file.lastModified();
    }

    // 监听文件所在目录的变化
    final directory = file.parent;
    _fileWatcher = directory.watch(events: FileSystemEvent.all).listen((event) {
      if (event.path == vaultPath) {
        _handleFileChange(event);
      }
    });

    print('[iCloud Drive] Started watching: $vaultPath');
  }

  Future<void> _handleFileChange(FileSystemEvent event) async {
    if (_vaultPath == null) return;

    try {
      final file = File(_vaultPath!);

      if (event.type == FileSystemEvent.delete) {
        print('[iCloud Drive] File deleted');
        _eventController.add(FileChangeEvent(
          type: ChangeType.deleted,
          timestamp: DateTime.now(),
          filePath: _vaultPath,
        ));
        return;
      }

      if (!await file.exists()) return;

      final currentMod = await file.lastModified();

      // 检查是否真的修改了（避免重复通知）
      if (_lastModification != null &&
          currentMod.isAfter(_lastModification!)) {
        print('[iCloud Drive] File modified at $currentMod');
        _lastModification = currentMod;

        _eventController.add(FileChangeEvent(
          type: ChangeType.modified,
          timestamp: currentMod,
          filePath: _vaultPath,
        ));
      }
    } catch (e) {
      print('[iCloud Drive] Error handling file change: $e');
    }
  }

  @override
  Future<void> stopWatching() async {
    await _fileWatcher?.cancel();
    _fileWatcher = null;
    _vaultPath = null;
    print('[iCloud Drive] Stopped watching');
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _eventController.stream;

  @override
  Future<SyncStatus> getSyncStatus() async {
    // iCloud Drive 同步状态检测
    if (_vaultPath == null) return SyncStatus.unknown;

    try {
      final file = File(_vaultPath!);
      if (await file.exists()) {
        return SyncStatus.synced;
      }
      return SyncStatus.unknown;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    final file = File(vaultPath);
    final directory = file.parent;
    final fileName = file.path.split('/').last.replaceAll('.db', '');

    try {
      final files = await directory.list().toList();
      return files.any((f) =>
        f.path.contains('${fileName}_conflict_') &&
        f.path.endsWith('.db') &&
        f.path != vaultPath
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    final file = File(vaultPath);
    if (!await file.exists()) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = vaultPath.replaceAll('.db', '_conflict_$timestamp.db');

    await file.copy(backupPath);
    print('[iCloud Drive] Created conflict backup: $backupPath');
  }

  void dispose() {
    stopWatching();
    _eventController.close();
  }
}
```

---

### 步骤 6: 集成到 VaultProvider

**文件路径**: `lib/presentation/providers/vault_provider.dart`

```dart
class VaultNotifier extends StateNotifier<VaultState> {
  // ... 现有代码
  final SyncService _syncService = SyncServiceFactory.getService();
  StreamSubscription? _syncSubscription;

  Future<void> checkInitialStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      // 检查 iCloud Drive 是否可用
      final iCloudAvailable = await isICloudDriveAvailable();

      final path = await _getDefaultVaultPath();
      final exists = await File(path).exists();

      if (exists) {
        final file = File(path);
        _lastKnownModification = await file.lastModified();
      }

      final bioEnabled = await _storage.read(key: 'bio_enabled') == 'true';
      final timeoutStr = await _storage.read(key: 'auto_lock_timeout');
      final timeout = timeoutStr != null ? int.tryParse(timeoutStr) ?? 5 : 5;

      final biometricType = await _detectBiometricType();

      state = state.copyWith(
        hasVaultFile: exists,
        isBiometricsEnabled: bioEnabled,
        vaultPath: path,
        autoLockTimeout: timeout,
        isLoading: false,
        biometricType: biometricType,
        filteredVaultItems: [],
      );

      // 显示 iCloud Drive 状态
      if (iCloudAvailable) {
        print('[Vault] Using iCloud Drive: $path');
      } else {
        print('[Vault] Using local storage: $path');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _startSyncWatch(String path, String masterPassword) async {
    try {
      await _syncService.startWatching(path, masterPassword: masterPassword);

      // 监听远程变化
      _syncSubscription = _syncService.onFileChanged.listen((event) async {
        print('[Sync] Remote file changed, reloading vault...');
        await _handleRemoteChange(masterPassword);
      });
    } catch (e) {
      print('[Sync] Failed to start watching: $e');
    }
  }

  Future<void> _handleRemoteChange(String masterPassword) async {
    if (state.vaultPath == null) return;

    try {
      // 检查冲突
      final hasConflict = await _syncService.hasConflict(state.vaultPath!);
      if (hasConflict) {
        // 创建冲突备份
        await _syncService.createConflictBackup(state.vaultPath!);
        print('[Sync] Conflict detected, backup created');
      }

      // 重新加载 vault
      final vault = await VaultService.loadVault(state.vaultPath!, masterPassword);
      state = state.copyWith(
        vault: vault,
        filteredVaultItems: SortService.sort(vault.items),
      );

      print('[Sync] Vault reloaded successfully');
    } catch (e) {
      print('[Sync] Failed to reload vault: $e');
      state = state.copyWith(error: 'Sync failed: $e');
    }
  }
}
```

---

## 4. 用户体验设计

### 4.1 首次启动（iOS/macOS）

**检测到 iCloud Drive**:
```
┌─────────────────────────────────────┐
│  欢迎使用 Hedge 密码管理器           │
│                                     │
│  [图标] iCloud Drive 同步已启用      │
│                                     │
│  您的密码将自动同步到：              │
│  • iPhone                           │
│  • iPad                             │
│  • Mac                              │
│                                     │
│  您可以在"文件"App 中查看和管理      │
│  密码库文件（vault.db）。            │
│                                     │
│  [ 继续 ]                           │
└─────────────────────────────────────┘
```

**未检测到 iCloud Drive**:
```
┌─────────────────────────────────────┐
│  未检测到 iCloud Drive               │
│                                     │
│  为了在多设备间同步密码，            │
│  请在"设置"中登录 iCloud。           │
│                                     │
│  您也可以选择仅在本地存储密码。      │
│                                     │
│  [ 前往设置 ]  [ 本地存储 ]         │
└─────────────────────────────────────┘
```

---

### 4.2 设置页面

**同步设置**:
```
┌─────────────────────────────────────┐
│  同步设置                            │
├─────────────────────────────────────┤
│  iCloud Drive 同步        [开启 ✓]  │
│  存储位置: iCloud Drive/Hedge/       │
│  最后同步: 2 分钟前                  │
│                                     │
│  [ 在"文件"App 中打开 ]              │
│  [ 导出密码库 ]                      │
│  [ 查看同步日志 ]                    │
│                                     │
│  ⚠️ 注意事项                         │
│  • 请勿手动修改 vault.db 文件        │
│  • 删除文件前请先导出备份            │
│  • 文件内容已加密，无法直接查看      │
└─────────────────────────────────────┘
```

---

### 4.3 文件 App 中的显示

**用户在"文件"App 中看到**:
```
iCloud Drive/
└── Hedge/
    ├── vault.db                    (主文件)
    ├── vault_conflict_2026-03-01.db (冲突备份，如果有)
    └── .DS_Store                   (系统文件)
```

---

## 5. 测试步骤

### 5.1 单设备测试

1. **检查 iCloud Drive 可用性**
   ```bash
   # 在 iOS 模拟器或真机上运行
   fvm flutter run -d iPhone
   ```

2. **验证文件路径**
   - 创建密码条目
   - 检查日志确认使用 iCloud Drive 路径
   - 在 macOS Finder 中打开 `~/Library/Mobile Documents/com~apple~CloudDocs/Hedge/`
   - 确认 `vault.db` 文件存在

3. **验证文件可见性**
   - 在 iOS "文件"App 中打开 iCloud Drive
   - 找到 "Hedge" 文件夹
   - 确认 `vault.db` 文件可见

---

### 5.2 多设备同步测试

1. **在第二台设备上安装应用**
   - 使用相同的 Apple ID 登录
   - 启动应用

2. **验证自动同步**
   - 在设备 A 添加新密码
   - 等待 10-30 秒
   - 在设备 B 上检查是否出现新密码

3. **测试冲突场景**
   - 在两台设备上同时编辑同一条目
   - 验证冲突备份文件是否生成
   - 检查 "文件"App 中是否出现 `vault_conflict_*.db`

---

### 5.3 文件监听测试

1. **手动修改文件**
   - 在 macOS Finder 中找到 `vault.db`
   - 复制一个备份文件
   - 将备份文件重命名为 `vault.db`（覆盖原文件）
   - 检查应用是否检测到变化并重新加载

2. **删除文件测试**
   - 在 "文件"App 中删除 `vault.db`
   - 检查应用是否检测到删除
   - 验证错误提示是否友好

---

## 6. 优势与劣势

### 6.1 优势

✅ **实施简单**
- 无需复杂的 Entitlements 配置
- 无需 MethodChannel 调用原生代码
- 纯 Dart 实现，跨平台代码复用度高

✅ **用户友好**
- 用户可以在 "文件"App 中看到和管理文件
- 易于手动备份和导出
- 易于迁移到其他设备

✅ **调试友好**
- 开发时可以直接查看文件
- 可以手动复制文件进行测试

✅ **透明度高**
- 用户知道文件存储在哪里
- 用户可以随时导出数据

---

### 6.2 劣势

⚠️ **用户可能误删**
- 文件暴露给用户，可能被误删
- 需要提供清晰的警告和恢复机制

⚠️ **隐私风险**
- 文件名可见（`vault.db`）
- 虽然内容加密，但文件存在性可见

⚠️ **冲突处理**
- 需要手动处理冲突文件
- 用户可能不理解冲突备份的含义

---

### 6.3 缓解措施

**防止误删**:
1. 在设置中添加"启用删除保护"选项
2. 定期自动备份到本地 Documents 目录
3. 提供"从备份恢复"功能

**隐私保护**:
1. 文件名使用 UUID（如 `a1b2c3d4.db`）而非 `vault.db`
2. 在应用内显示友好名称
3. 添加 `.nomedia` 文件（Android）

**冲突处理**:
1. 提供冲突文件合并工具
2. 在应用内显示冲突文件列表
3. 提供"选择保留哪个版本"的 UI

---

## 7. 与 iCloud Documents 方案对比

| 特性 | iCloud Drive（本方案） | iCloud Documents |
|------|----------------------|------------------|
| 实施难度 | 🟢 简单 | 🟡 中等 |
| 配置复杂度 | 低（仅 Info.plist） | 高（Entitlements + Xcode） |
| 用户可见性 | ✅ 可见 | ❌ 不可见 |
| 误删风险 | ⚠️ 有 | ✅ 无 |
| 导出便利性 | ✅ 易 | ⚠️ 需应用提供 |
| 调试友好性 | ✅ 易 | ⚠️ 难 |
| 隐私保护 | ⚠️ 文件名可见 | ✅ 完全不可见 |
| 同步速度 | 实时 | 实时 |
| 冲突处理 | 手动 | 系统级 |

**推荐**: 对于密码管理应用，**iCloud Drive 方案更简单**，且 1Password 7 已验证其可行性。

---

## 8. 迁移路径

### 8.1 从本地存储迁移到 iCloud Drive

```dart
Future<void> migrateToICloudDrive() async {
  // 1. 获取当前本地路径
  final localDir = await getApplicationDocumentsDirectory();
  final localPath = '${localDir.path}/vault.db';
  final localFile = File(localPath);

  if (!await localFile.exists()) {
    print('[Migration] No local file to migrate');
    return;
  }

  // 2. 获取 iCloud Drive 路径
  final iCloudPath = await _getICloudDrivePath();
  if (iCloudPath == null) {
    print('[Migration] iCloud Drive not available');
    return;
  }

  final iCloudFile = File('$iCloudPath/vault.db');

  // 3. 检查 iCloud Drive 是否已有文件
  if (await iCloudFile.exists()) {
    print('[Migration] iCloud Drive already has vault.db');
    // 创建冲突备份
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await localFile.copy('$iCloudPath/vault_local_$timestamp.db');
    return;
  }

  // 4. 复制文件到 iCloud Drive
  await localFile.copy(iCloudFile.path);
  print('[Migration] Migrated to iCloud Drive: ${iCloudFile.path}');

  // 5. 更新配置
  await _storage.write(key: 'vault_path', value: iCloudFile.path);
  state = state.copyWith(vaultPath: iCloudFile.path);

  // 6. 可选：删除本地文件（建议保留作为备份）
  // await localFile.delete();
}
```

---

## 9. 后续优化

### 9.1 短期优化（1-2 周）

- [ ] 添加"在文件 App 中打开"按钮
- [ ] 实现冲突文件列表和合并工具
- [ ] 添加删除保护选项
- [ ] 优化文件监听性能

### 9.2 中期优化（1-2 月）

- [ ] 实现自动备份到本地
- [ ] 添加"从备份恢复"功能
- [ ] 支持多密码库（多个 .db 文件）
- [ ] 添加文件完整性校验

### 9.3 长期优化（3-6 月）

- [ ] 实现增量同步（仅同步变更部分）
- [ ] 添加版本历史记录
- [ ] 支持文件压缩
- [ ] 实现智能冲突解决

---

## 10. 常见问题

### Q1: 如果用户删除了 iCloud Drive 中的 vault.db 怎么办？

**A**:
1. 应用检测到文件删除
2. 提示用户："密码库文件已被删除，是否从本地备份恢复？"
3. 如果有本地备份，提供恢复选项
4. 如果没有备份，提示用户重新创建密码库

### Q2: 如何防止用户误删文件？

**A**:
1. 在设置中添加"启用删除保护"选项
2. 定期自动备份到本地 Documents 目录
3. 在 "文件"App 中添加说明文件（README.txt）

### Q3: iCloud Drive 同步速度如何？

**A**:
- 通常在 10-30 秒内完成
- 取决于文件大小和网络状况
- 小文件（< 1MB）通常 < 10 秒

### Q4: 如果用户没有登录 iCloud 怎么办？

**A**:
- 应用自动 fallback 到本地 Documents 目录
- 提示用户登录 iCloud 以启用同步
- 提供"稍后再说"选项

---

## 11. 总结

### 11.1 实施优先级

✅ **推荐立即实施**

**理由**:
1. 实施简单，无需复杂配置
2. 1Password 7 已验证可行性
3. 用户体验友好
4. 调试和维护成本低

### 11.2 关键优势

- 🟢 **实施难度低**：纯 Dart 实现，无需原生代码
- 🟢 **用户友好**：文件可见，易于管理
- 🟢 **透明度高**：用户知道数据存储位置
- 🟢 **调试友好**：开发时易于测试

### 11.3 下一步行动

1. ✅ 修改 `_getDefaultVaultPath()` 使用 iCloud Drive 路径
2. ✅ 实现文件监听（`FileSystemEntity.watch()`）
3. ✅ 测试多设备同步
4. ✅ 添加用户引导和说明

---

**实施完成标准**:
- ✅ iPhone 和 Mac 之间自动同步
- ✅ 用户可以在 "文件"App 中看到 vault.db
- ✅ 冲突自动创建备份文件
- ✅ 文件删除有恢复机制
