# WebDAV 同步实施指南

**版本**: 1.0
**日期**: 2026-03-01
**优先级**: P2 (中)

---

## 1. 概述

本文档提供 NotePassword 实现 WebDAV 同步的详细技术实施步骤，作为跨平台同步的可选方案。

### 1.1 目标

- ✅ 支持用户自建 WebDAV 服务器同步
- ✅ 跨平台支持（iOS/Android/macOS/Linux/Windows）
- ✅ 符合"Local-First"理念
- ✅ 提供简单的配置界面

### 1.2 适用场景

- 用户拥有 Nextcloud/Synology NAS/ownCloud 等 WebDAV 服务
- 需要 iOS 和 Android 跨平台同步
- 不希望依赖 iCloud 或 Google Drive
- 技术敏感型用户

### 1.3 技术栈

- **Dart 包**: `webdav_client: ^1.2.5`
- **协议**: WebDAV (HTTP/HTTPS)
- **认证**: Basic Auth / Digest Auth

---

## 2. 实施步骤

### 步骤 1: 添加依赖

**文件路径**: `pubspec.yaml`

```yaml
dependencies:
  webdav_client: ^1.2.5
  http: ^1.2.0
```

运行:
```bash
fvm flutter pub get
```

### 步骤 2: 创建 WebDAV 配置模型

**文件路径**: `lib/domain/entities/webdav_config.dart`

```dart
class WebDAVConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath; // 远程文件路径，如 /Hedge/vault.db
  final bool enabled;

  WebDAVConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remotePath = '/Hedge/vault.db',
    this.enabled = false,
  });

  // 验证配置是否完整
  bool get isValid {
    return serverUrl.isNotEmpty &&
           username.isNotEmpty &&
           password.isNotEmpty &&
           remotePath.isNotEmpty;
  }

  // 序列化（用于安全存储）
  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password, // 注意：实际应该加密存储
      'remotePath': remotePath,
      'enabled': enabled,
    };
  }

  // 反序列化
  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    return WebDAVConfig(
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      remotePath: json['remotePath'] as String? ?? '/Hedge/vault.db',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  WebDAVConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
    bool? enabled,
  }) {
    return WebDAVConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      enabled: enabled ?? this.enabled,
    );
  }
}
```

### 步骤 3: 创建 WebDAV 同步服务

**文件路径**: `lib/platform/webdav_sync_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:hedge/services/sync_service.dart';
import 'package:hedge/domain/entities/webdav_config.dart';

class WebDAVSyncService implements SyncService {
  webdav.Client? _client;
  WebDAVConfig? _config;
  Timer? _pollTimer;
  String? _vaultPath;
  DateTime? _lastRemoteModification;
  final _eventController = StreamController<FileChangeEvent>.broadcast();

  // 初始化客户端
  Future<void> initialize(WebDAVConfig config) async {
    _config = config;

    if (!config.isValid) {
      throw Exception('Invalid WebDAV configuration');
    }

    _client = webdav.newClient(
      config.serverUrl,
      user: config.username,
      password: config.password,
      debug: false,
    );

    // 测试连接
    try {
      await _client!.ping();
      print('[WebDAV] Connection successful');
    } catch (e) {
      print('[WebDAV] Connection failed: $e');
      throw Exception('Failed to connect to WebDAV server: $e');
    }

    // 确保远程目录存在
    await _ensureRemoteDirectory();
  }

  // 确保远程目录存在
  Future<void> _ensureRemoteDirectory() async {
    if (_client == null || _config == null) return;

    final remotePath = _config!.remotePath;
    final directory = remotePath.substring(0, remotePath.lastIndexOf('/'));

    try {
      await _client!.mkdir(directory);
      print('[WebDAV] Created remote directory: $directory');
    } catch (e) {
      // 目录可能已存在，忽略错误
      print('[WebDAV] Directory might already exist: $e');
    }
  }

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    _vaultPath = vaultPath;

    // 获取初始远程修改时间
    try {
      _lastRemoteModification = await _getRemoteModificationTime();
    } catch (e) {
      print('[WebDAV] Failed to get initial remote modification time: $e');
    }

    // 启动轮询（每 30 秒检查一次）
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkForRemoteChanges());

    print('[WebDAV] Started watching: $vaultPath');
  }

  @override
  Future<void> stopWatching() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _vaultPath = null;
    print('[WebDAV] Stopped watching');
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _eventController.stream;

  // 上传本地文件到 WebDAV
  Future<void> uploadFile(String localPath) async {
    if (_client == null || _config == null) {
      throw Exception('WebDAV not initialized');
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist: $localPath');
    }

    try {
      final bytes = await file.readAsBytes();
      await _client!.write(_config!.remotePath, bytes);
      print('[WebDAV] Uploaded file: ${_config!.remotePath}');

      // 更新最后修改时间
      _lastRemoteModification = await _getRemoteModificationTime();
    } catch (e) {
      print('[WebDAV] Upload failed: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // 从 WebDAV 下载文件
  Future<void> downloadFile(String localPath) async {
    if (_client == null || _config == null) {
      throw Exception('WebDAV not initialized');
    }

    try {
      final bytes = await _client!.read(_config!.remotePath);
      final file = File(localPath);

      // 确保本地目录存在
      await file.parent.create(recursive: true);

      await file.writeAsBytes(bytes);
      print('[WebDAV] Downloaded file: $localPath');

      // 更新最后修改时间
      _lastRemoteModification = await _getRemoteModificationTime();
    } catch (e) {
      print('[WebDAV] Download failed: $e');
      throw Exception('Failed to download file: $e');
    }
  }

  // 检查远程文件是否存在
  Future<bool> remoteFileExists() async {
    if (_client == null || _config == null) return false;

    try {
      final list = await _client!.readDir(_config!.remotePath);
      return list.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 获取远程文件修改时间
  Future<DateTime?> _getRemoteModificationTime() async {
    if (_client == null || _config == null) return null;

    try {
      final list = await _client!.readDir(_config!.remotePath);
      if (list.isNotEmpty) {
        return list.first.mTime;
      }
    } catch (e) {
      print('[WebDAV] Failed to get remote modification time: $e');
    }
    return null;
  }

  // 检查远程变化
  Future<void> _checkForRemoteChanges() async {
    if (_vaultPath == null) return;

    try {
      final currentRemoteMod = await _getRemoteModificationTime();

      if (currentRemoteMod != null &&
          _lastRemoteModification != null &&
          currentRemoteMod.isAfter(_lastRemoteModification!)) {
        print('[WebDAV] Remote file changed, notifying...');

        _lastRemoteModification = currentRemoteMod;

        _eventController.add(FileChangeEvent(
          type: ChangeType.modified,
          timestamp: currentRemoteMod,
          filePath: _vaultPath,
        ));
      }
    } catch (e) {
      print('[WebDAV] Failed to check remote changes: $e');
    }
  }

  @override
  Future<SyncStatus> getSyncStatus() async {
    if (_client == null || _config == null) {
      return SyncStatus.unknown;
    }

    try {
      await _client!.ping();
      return SyncStatus.synced;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    // WebDAV 冲突检测：比较本地和远程修改时间
    if (_vaultPath == null) return false;

    try {
      final localFile = File(vaultPath);
      if (!await localFile.exists()) return false;

      final localMod = await localFile.lastModified();
      final remoteMod = await _getRemoteModificationTime();

      if (remoteMod == null) return false;

      // 如果本地和远程都在最近修改过，可能存在冲突
      final timeDiff = localMod.difference(remoteMod).abs();
      return timeDiff.inSeconds < 60; // 1 分钟内的修改视为潜在冲突
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    final file = File(vaultPath);
    if (!await file.exists()) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = vaultPath.replaceAll('.db', '_webdav_conflict_$timestamp.db');

    await file.copy(backupPath);
    print('[WebDAV] Created conflict backup: $backupPath');
  }

  // 测试连接
  static Future<bool> testConnection(WebDAVConfig config) async {
    try {
      final client = webdav.newClient(
        config.serverUrl,
        user: config.username,
        password: config.password,
      );

      await client.ping();
      return true;
    } catch (e) {
      print('[WebDAV] Connection test failed: $e');
      return false;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _eventController.close();
  }
}
```

### 步骤 4: 集成到 VaultProvider

**文件路径**: `lib/presentation/providers/vault_provider.dart`

添加 WebDAV 配置管理：

```dart
class VaultState {
  // ... 现有字段
  final WebDAVConfig? webdavConfig;
  final bool isWebDAVSyncing;

  VaultState({
    // ... 现有参数
    this.webdavConfig,
    this.isWebDAVSyncing = false,
  });

  VaultState copyWith({
    // ... 现有参数
    WebDAVConfig? webdavConfig,
    bool? isWebDAVSyncing,
  }) {
    return VaultState(
      // ... 现有字段
      webdavConfig: webdavConfig ?? this.webdavConfig,
      isWebDAVSyncing: isWebDAVSyncing ?? this.isWebDAVSyncing,
    );
  }
}

class VaultNotifier extends StateNotifier<VaultState> {
  // ... 现有代码
  WebDAVSyncService? _webdavService;

  // 配置 WebDAV
  Future<bool> configureWebDAV(WebDAVConfig config) async {
    try {
      // 测试连接
      final isConnected = await WebDAVSyncService.testConnection(config);
      if (!isConnected) {
        state = state.copyWith(error: 'Failed to connect to WebDAV server');
        return false;
      }

      // 保存配置（加密存储）
      final configJson = config.toJson();
      await _storage.write(key: 'webdav_config', value: jsonEncode(configJson));

      // 初始化服务
      _webdavService = WebDAVSyncService();
      await _webdavService!.initialize(config);

      state = state.copyWith(webdavConfig: config);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'WebDAV configuration failed: $e');
      return false;
    }
  }

  // 启用/禁用 WebDAV 同步
  Future<void> toggleWebDAVSync(bool enabled) async {
    final config = state.webdavConfig;
    if (config == null) return;

    final updatedConfig = config.copyWith(enabled: enabled);
    await configureWebDAV(updatedConfig);

    if (enabled && state.vaultPath != null) {
      // 启动监听
      await _webdavService?.startWatching(state.vaultPath!);

      // 监听远程变化
      _webdavService?.onFileChanged.listen((event) async {
        print('[WebDAV] Remote file changed, reloading...');
        await _handleRemoteChange();
      });
    } else {
      await _webdavService?.stopWatching();
    }
  }

  // 手动同步到 WebDAV
  Future<void> syncToWebDAV() async {
    if (_webdavService == null || state.vaultPath == null) {
      return;
    }

    state = state.copyWith(isWebDAVSyncing: true);

    try {
      // 检查远程文件是否存在
      final remoteExists = await _webdavService!.remoteFileExists();

      if (remoteExists) {
        // 检查冲突
        final hasConflict = await _webdavService!.hasConflict(state.vaultPath!);

        if (hasConflict) {
          // 创建冲突备份
          await _webdavService!.createConflictBackup(state.vaultPath!);
          print('[WebDAV] Conflict detected, backup created');
        }
      }

      // 上传本地文件
      await _webdavService!.uploadFile(state.vaultPath!);
      print('[WebDAV] Sync completed');

      state = state.copyWith(isWebDAVSyncing: false);
    } catch (e) {
      print('[WebDAV] Sync failed: $e');
      state = state.copyWith(
        isWebDAVSyncing: false,
        error: 'WebDAV sync failed: $e',
      );
    }
  }

  // 从 WebDAV 下载
  Future<void> downloadFromWebDAV() async {
    if (_webdavService == null || state.vaultPath == null) {
      return;
    }

    state = state.copyWith(isWebDAVSyncing: true);

    try {
      // 下载远程文件
      await _webdavService!.downloadFile(state.vaultPath!);
      print('[WebDAV] Download completed');

      // 重新加载 vault
      await _reloadVault();

      state = state.copyWith(isWebDAVSyncing: false);
    } catch (e) {
      print('[WebDAV] Download failed: $e');
      state = state.copyWith(
        isWebDAVSyncing: false,
        error: 'WebDAV download failed: $e',
      );
    }
  }

  // 处理远程变化
  Future<void> _handleRemoteChange() async {
    // 下载并重新加载
    await downloadFromWebDAV();
  }

  // 重新加载 vault
  Future<void> _reloadVault() async {
    if (state.currentPassword == null || state.vaultPath == null) {
      return;
    }

    try {
      final vault = await VaultService.loadVault(
        state.vaultPath!,
        state.currentPassword!,
      );

      state = state.copyWith(
        vault: vault,
        filteredVaultItems: SortService.sort(vault.items),
      );
    } catch (e) {
      print('[Vault] Failed to reload: $e');
    }
  }
}
```

### 步骤 5: 创建 WebDAV 设置页面

**文件路径**: `lib/presentation/pages/shared/webdav_settings_page.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/domain/entities/webdav_config.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';

class WebDAVSettingsPage extends ConsumerStatefulWidget {
  const WebDAVSettingsPage({super.key});

  @override
  ConsumerState<WebDAVSettingsPage> createState() => _WebDAVSettingsPageState();
}

class _WebDAVSettingsPageState extends ConsumerState<WebDAVSettingsPage> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController(text: '/Hedge/vault.db');

  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    final config = ref.read(vaultProvider).webdavConfig;
    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _remotePathController.text = config.remotePath;
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final config = WebDAVConfig(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remotePath: _remotePathController.text.trim(),
    );

    final success = await WebDAVSyncService.testConnection(config);

    setState(() {
      _isTesting = false;
      _testResult = success ? 'Connection successful!' : 'Connection failed';
    });
  }

  Future<void> _saveConfig() async {
    final config = WebDAVConfig(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remotePath: _remotePathController.text.trim(),
      enabled: true,
    );

    final success = await ref.read(vaultProvider.notifier).configureWebDAV(config);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('WebDAV Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Configure your WebDAV server for cross-platform sync',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),

            // Server URL
            CupertinoTextField(
              controller: _serverUrlController,
              placeholder: 'Server URL',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.globe, size: 20),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: https://cloud.example.com/remote.php/dav/files/username/',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),

            const SizedBox(height: 16),

            // Username
            CupertinoTextField(
              controller: _usernameController,
              placeholder: 'Username',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.person, size: 20),
              ),
              autocorrect: false,
            ),

            const SizedBox(height: 16),

            // Password
            CupertinoTextField(
              controller: _passwordController,
              placeholder: 'Password',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.lock, size: 20),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 16),

            // Remote Path
            CupertinoTextField(
              controller: _remotePathController,
              placeholder: 'Remote Path',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.folder, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            // Test Connection Button
            CupertinoButton.filled(
              onPressed: _isTesting ? null : _testConnection,
              child: _isTesting
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Test Connection'),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _testResult!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _testResult!.contains('successful')
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Save Button
            CupertinoButton.filled(
              onPressed: _saveConfig,
              child: const Text('Save & Enable'),
            ),

            if (vaultState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                vaultState.error!,
                style: const TextStyle(color: CupertinoColors.systemRed),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }
}
```

---

## 3. 测试步骤

### 3.1 准备测试环境

**选项 A: 使用 Nextcloud**
1. 注册免费 Nextcloud 账号: https://nextcloud.com/signup/
2. 获取 WebDAV 地址: `https://your-instance.nextcloud.com/remote.php/dav/files/username/`

**选项 B: 本地测试服务器**
```bash
# 使用 Docker 运行 Nextcloud
docker run -d -p 8080:80 nextcloud
```

### 3.2 功能测试

1. **配置测试**
   - 打开 WebDAV 设置页面
   - 输入服务器信息
   - 点击"Test Connection"
   - 验证连接成功

2. **上传测试**
   - 创建几个密码条目
   - 点击"Sync to WebDAV"
   - 在 WebDAV 服务器上验证文件存在

3. **下载测试**
   - 在另一台设备上配置相同的 WebDAV
   - 点击"Download from WebDAV"
   - 验证数据同步成功

4. **自动同步测试**
   - 在设备 A 修改数据并上传
   - 等待 30 秒
   - 在设备 B 上验证自动下载

---

## 4. 用户文档

### 4.1 支持的 WebDAV 服务

- ✅ Nextcloud
- ✅ ownCloud
- ✅ Synology NAS
- ✅ QNAP NAS
- ✅ Box.com
- ✅ 坚果云

### 4.2 配置示例

**Nextcloud**:
```
Server URL: https://your-instance.nextcloud.com/remote.php/dav/files/username/
Username: your-username
Password: your-password or app-password
Remote Path: /Hedge/vault.db
```

**Synology NAS**:
```
Server URL: https://your-nas-ip:5006/
Username: your-username
Password: your-password
Remote Path: /Hedge/vault.db
```

**坚果云**:
```
Server URL: https://dav.jianguoyun.com/dav/
Username: your-email
Password: app-password (需在坚果云网页端生成)
Remote Path: /Hedge/vault.db
```

---

## 5. 安全建议

### 5.1 密码存储

当前实现将 WebDAV 密码存储在 FlutterSecureStorage 中，建议：

1. **使用应用密码**：不要使用主账号密码，使用服务提供的应用专用密码
2. **加密存储**：在保存前对密码进行额外加密
3. **定期更换**：建议用户定期更换 WebDAV 密码

### 5.2 传输安全

1. **强制 HTTPS**：拒绝 HTTP 连接
2. **证书验证**：验证服务器 SSL 证书
3. **超时设置**：设置合理的连接超时

---

## 6. 后续优化

- [ ] 支持 OAuth 认证（Nextcloud/ownCloud）
- [ ] 增量同步（仅传输变更部分）
- [ ] 断点续传
- [ ] 多文件同步（附件支持）
- [ ] 同步冲突智能合并
- [ ] 同步日志和历史记录

---

**实施完成标准**:
- ✅ 配置页面完成
- ✅ 上传/下载功能正常
- ✅ 自动同步工作正常
- ✅ 冲突检测和备份功能正常
- ✅ 至少支持 3 种 WebDAV 服务测试通过
