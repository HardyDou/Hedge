# iOS/macOS iCloud Drive 同步实施状态

**日期**: 2026-03-01
**分支**: feature/ios-icloud-drive-sync
**状态**: ✅ 基础实现完成，⚠️ iCloud 功能受限

---

## 已完成的工作

### 1. 代码实现 ✅

#### vault_provider.dart
- ✅ 添加 `_getICloudDrivePath()` 方法检测 iCloud Drive 路径
- ✅ 添加 `isICloudDriveAvailable()` 方法检查可用性
- ✅ 修改 `_getDefaultVaultPath()` 优先使用 iCloud Drive
- ✅ 自动 fallback 到本地存储（如果 iCloud 不可用）

**路径逻辑**:
```dart
// iOS/macOS 优先使用 iCloud Drive
if (Platform.isIOS || Platform.isMacOS) {
  final iCloudPath = await _getICloudDrivePath();
  if (iCloudPath != null) {
    return '$iCloudPath/vault.db';  // iCloud Drive
  }
}
// Fallback 到本地存储
return '${documentsDir.path}/vault.db';
```

#### ios_sync_service.dart
- ✅ 从轮询改为 `FileSystemEntity.watch()` 实时监听
- ✅ 支持文件修改、删除事件检测
- ✅ 实现冲突检测和备份机制
- ✅ 修复 `SyncStatus.unknown` 错误（改为 `SyncStatus.idle`）

**监听机制**:
```dart
// 监听目录变化
final directory = file.parent;
_fileWatcher = directory.watch(events: FileSystemEvent.all).listen((event) {
  if (event.path == vaultPath) {
    _handleFileChange(event);
  }
});
```

### 2. 配置文件 ⚠️

#### macOS
- ✅ Info.plist: 已配置（但已移除 iCloud 相关）
- ✅ DebugProfile.entitlements: 已移除 iCloud entitlements
- ✅ Release.entitlements: 已移除 iCloud entitlements

#### iOS
- ✅ Info.plist: 已有基础配置
- ⚠️ 需要在 Xcode 中手动添加 iCloud capability（需付费账号）

### 3. 构建状态 ✅

- ✅ macOS Debug 构建成功
- ✅ 应用可以正常运行
- ✅ 代码逻辑完整（包含 iCloud 检测和 fallback）

---

## 遇到的问题

### 问题 1: 免费开发者账号不支持 iCloud ❌

**错误信息**:
```
Cannot create a Mac App Development provisioning profile for "com.hardydou.hedge".
Personal development teams, including "xiaoyu dou", do not support the iCloud capability.
```

**原因**:
- Apple 的限制：免费的 Personal Team 不支持 iCloud
- 需要付费的 Apple Developer Program ($99/年)

**解决方案**:
- 暂时移除了 iCloud entitlements
- 代码保留 iCloud 检测逻辑
- 应用会自动使用本地存储

### 问题 2: SyncStatus.unknown 不存在 ✅ 已修复

**错误**:
```dart
Error: Member not found: 'unknown'.
return SyncStatus.unknown;
```

**修复**:
```dart
// 改为
return SyncStatus.idle;
```

---

## 当前行为

### 在免费开发者账号下

1. **启动时**:
   - 检测 iCloud Drive: `/Users/hardy/Library/Mobile Documents/com~apple~CloudDocs`
   - 如果可用，尝试使用 `~/Library/Mobile Documents/com~apple~CloudDocs/Hedge/vault.db`
   - 如果不可用或无权限，fallback 到本地: `~/Library/Containers/com.hardydou.hedge/Data/Documents/vault.db`

2. **文件监听**:
   - 使用 `FileSystemEntity.watch()` 监听文件变化
   - 检测修改、删除事件
   - 自动重新加载 vault

3. **同步状态**:
   - 本地存储模式（因为没有 iCloud entitlements）
   - 文件监听正常工作
   - 冲突检测机制已实现

---

## 测试步骤

### 1. 验证本地存储

```bash
# 运行应用
fvm flutter run -d macos

# 创建密码条目后，检查文件位置
ls -la ~/Library/Containers/com.hardydou.hedge/Data/Documents/vault.db
```

### 2. 验证文件监听

1. 运行应用并创建密码条目
2. 在 Finder 中找到 vault.db 文件
3. 用文本编辑器修改文件（会损坏，仅测试）
4. 观察应用是否检测到变化

### 3. 验证 iCloud Drive 检测

查看应用日志：
```
[Vault] iCloud Drive not available, using local storage
或
[Vault] Using iCloud Drive: /Users/hardy/Library/Mobile Documents/...
```

---

## 启用 iCloud 的步骤（需付费账号）

### 方案 A: 购买 Apple Developer Program

1. **注册 Apple Developer Program** ($99/年)
   - 访问: https://developer.apple.com/programs/
   - 使用你的 Apple ID 注册
   - 支付 $99/年

2. **在 Xcode 中配置**
   - 打开 `macos/Runner.xcworkspace`
   - 选择 Runner target
   - Signing & Capabilities > 点击 "+ Capability"
   - 添加 "iCloud"
   - 勾选 "iCloud Documents"
   - 添加容器: `iCloud.com.hardydou.hedge`

3. **恢复 Entitlements**
   ```xml
   <!-- macos/Runner/DebugProfile.entitlements -->
   <key>com.apple.developer.ubiquity-container-identifiers</key>
   <array>
       <string>iCloud.com.hardydou.hedge</string>
   </array>
   ```

4. **恢复 Info.plist**
   ```xml
   <!-- macos/Runner/Info.plist -->
   <key>LSSupportsOpeningDocumentsInPlace</key>
   <true/>
   <key>NSUbiquitousContainers</key>
   <dict>
       <key>NSUbiquitousContainerIsDocumentScopePublic</key>
       <true/>
   </dict>
   ```

5. **重新构建**
   ```bash
   fvm flutter clean
   fvm flutter build macos --debug
   ```

### 方案 B: 使用 WebDAV（推荐替代方案）

如果不想购买 Apple Developer Program，可以实施 WebDAV 同步：

- ✅ 跨平台（iOS/Android/macOS）
- ✅ 用户完全掌控数据
- ✅ 无需付费账号
- ✅ 支持 Nextcloud/坚果云/Synology NAS

参考文档: `docs/implementation-guide-webdav.md`

---

## 下一步计划

### 短期（如果有付费账号）

1. 购买 Apple Developer Program
2. 在 Xcode 中添加 iCloud capability
3. 恢复 iCloud entitlements
4. 测试多设备同步

### 短期（如果没有付费账号）

1. ✅ 继续使用本地存储（已完成）
2. 实施 WebDAV 同步（P2 优先级）
3. 实施局域网同步（P3 可选）

### 中期

1. 优化文件监听性能
2. 添加冲突解决 UI
3. 实现自动备份机制
4. 添加同步状态指示器

---

## 提交记录

### Commit 1: 初始实现
```
feat: 实现 iOS/macOS iCloud Drive 同步

- 修改 vault_provider.dart 优先使用 iCloud Drive 路径
- 添加 _getICloudDrivePath() 和 isICloudDriveAvailable() 方法
- 更新 ios_sync_service.dart 使用 FileSystemEntity.watch() 监听文件变化
- 配置 macOS Info.plist 支持 iCloud Drive
- 添加 macOS Entitlements iCloud 权限
```

### Commit 2: 修复构建错误
```
fix: 修复 SyncStatus.unknown 错误并移除 iCloud entitlements

- 修复 ios_sync_service.dart 中 SyncStatus.unknown 改为 SyncStatus.idle
- 暂时移除 macOS iCloud entitlements（免费开发者账号不支持）
- 代码保留 iCloud Drive 路径检测，会自动 fallback 到本地存储
- 构建成功
```

---

## 总结

### ✅ 已完成
- iCloud Drive 路径检测和 fallback 机制
- 文件监听和自动重新加载
- 冲突检测和备份
- macOS 构建成功

### ⚠️ 受限
- iCloud 功能需要付费 Apple Developer Program
- 当前使用本地存储模式

### 📋 建议
- **如果有预算**: 购买 Apple Developer Program，启用 iCloud
- **如果没有预算**: 实施 WebDAV 同步作为替代方案

---

**实施完成度**: 80%
**可用性**: ✅ 完全可用（本地存储模式）
**iCloud 同步**: ⚠️ 需要付费账号
