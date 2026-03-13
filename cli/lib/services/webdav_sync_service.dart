import 'dart:convert';
import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:dio/dio.dart';
import 'keychain_service.dart';
import 'config_service.dart';
import 'shared_config_reader.dart';
import '../vault/vault_loader.dart';
import '../ipc/ipc_client.dart';

/// WebDAV 同步服务
class WebDavSyncService {
  webdav.Client? _client;
  WebDavConfig? _config;

  /// 加载 WebDAV 配置（按优先级）
  /// 1. 环境变量
  /// 2. IPC（从 Desktop App 获取）
  /// 3. Keychain（与 Desktop App 共享）
  /// 4. CLI 配置文件
  Future<WebDavConfig?> loadConfig() async {
    // 1. 环境变量（最高优先级）
    final envUrl = Platform.environment['HEDGE_WEBDAV_URL'];
    final envUser = Platform.environment['HEDGE_WEBDAV_USERNAME'];
    final envPass = Platform.environment['HEDGE_WEBDAV_PASSWORD'];

    if (envUrl != null && envUser != null && envPass != null) {
      print('✓ Using WebDAV config from environment variables');
      return WebDavConfig(
        serverUrl: envUrl,
        username: envUser,
        password: envPass,
        remotePath: Platform.environment['HEDGE_WEBDAV_PATH'] ?? 'Hedge/vault.db',
      );
    }

    // 2. IPC（从 Desktop App 获取）
    if (IpcClient.isDesktopAppRunning()) {
      try {
        final ipc = IpcClient();
        if (await ipc.connect()) {
          final ipcConfig = await ipc.getWebdavConfig();
          await ipc.disconnect();

          if (ipcConfig != null) {
            final serverUrl = ipcConfig['server_url'] as String?;
            final username = ipcConfig['username'] as String?;
            final password = ipcConfig['password'] as String?;
            final remotePath = ipcConfig['remote_path'] as String?;

            if (serverUrl != null && username != null && password != null) {
              print('✓ Using WebDAV config from Desktop App (IPC)');
              return WebDavConfig(
                serverUrl: serverUrl,
                username: username,
                password: password,
                remotePath: remotePath ?? 'Hedge/vault.db',
              );
            }
          }
        }
      } catch (e) {
        print('⚠️  Failed to get config from IPC: $e');
      }
    }

    // 3. Keychain（与 Desktop App 共享）
    if (await KeychainService.isAvailable()) {
      try {
        final serverUrl = await KeychainService.read('webdav_server_url');
        final username = await KeychainService.read('webdav_username');
        final password = await KeychainService.read('webdav_password');
        final remotePath = await KeychainService.read('webdav_remote_path');

        if (serverUrl != null && username != null && password != null) {
          print('✓ Using WebDAV config from system Keychain');
          return WebDavConfig(
            serverUrl: serverUrl,
            username: username,
            password: password,
            remotePath: remotePath ?? 'Hedge/vault.db',
          );
        }
      } catch (e) {
        print('⚠️  Failed to read from Keychain: $e');
      }
    }

    // 4. CLI 共享加密配置文件（Desktop App 写入）
    final sharedConfig = await SharedConfigReader.readWebdavConfig();
    if (sharedConfig != null) {
      print('✓ Using WebDAV config from shared encrypted file');
      return WebDavConfig(
        serverUrl: sharedConfig['serverUrl']!,
        username: sharedConfig['username']!,
        password: sharedConfig['password']!,
        remotePath: sharedConfig['remotePath'] ?? 'Hedge/vault.db',
      );
    }

    // 5. CLI 配置文件（用户手动配置）
    final cliConfig = await ConfigService.loadWebDavConfig();
    if (cliConfig != null) {
      print('✓ Using WebDAV config from CLI config file');
      return cliConfig;
    }

    return null;
  }

  /// 连接到 WebDAV 服务器
  Future<bool> connect() async {
    _config = await loadConfig();
    if (_config == null) return false;

    try {
      _client = webdav.newClient(
        _config!.serverUrl,
        user: _config!.username,
        password: _config!.password,
      );
      // 测试连接
      await _client!.ping();
      return true;
    } catch (e) {
      print('❌ WebDAV connection failed: $e');
      return false;
    }
  }

  /// 获取本地 vault 路径
  Future<String?> getLocalVaultPath() async {
    return await VaultLoader.discoverVaultPath();
  }

  /// 获取远程 vault 修改时间
  Future<DateTime?> getRemoteModifiedTime() async {
    if (_config == null) return null;

    try {
      final url = _config!.serverUrl.endsWith('/')
          ? '${_config!.serverUrl}${_config!.remotePath}'
          : '${_config!.serverUrl}/${_config!.remotePath}';

      final dio = Dio();
      final credentials = base64Encode(
        '${_config!.username}:${_config!.password}'.codeUnits,
      );
      dio.options.headers['Authorization'] = 'Basic $credentials';

      final response = await dio.head(url);
      final lastModified = response.headers.value('last-modified');

      if (lastModified != null) {
        return HttpDate.parse(lastModified);
      }
      return DateTime.now();
    } catch (e) {
      return null;
    }
  }

  /// 获取本地 vault 修改时间
  Future<DateTime?> getLocalModifiedTime() async {
    final localPath = await getLocalVaultPath();
    if (localPath == null) return null;

    final file = File(localPath);
    if (!await file.exists()) return null;

    final stat = await file.stat();
    return stat.modified;
  }

  /// 同步状态信息
  Future<Map<String, dynamic>?> getSyncStatus() async {
    if (!await connect()) return null;

    final localPath = await getLocalVaultPath();
    final localMod = await getLocalModifiedTime();
    final remoteMod = await getRemoteModifiedTime();

    return {
      'local_path': localPath,
      'local_modified': localMod?.toIso8601String(),
      'remote_modified': remoteMod?.toIso8601String(),
      'remote_url': _config?.serverUrl,
      'remote_path': _config?.remotePath,
    };
  }

  /// 上传 vault 到远程
  Future<bool> uploadVault(String localPath) async {
    if (_client == null || _config == null) return false;

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        print('❌ Local vault file not found: $localPath');
        return false;
      }

      // 确保远程目录存在
      final remoteDir = _config!.remotePath.contains('/')
          ? _config!.remotePath.substring(0, _config!.remotePath.lastIndexOf('/'))
          : '';
      if (remoteDir.isNotEmpty) {
        try {
          await _client!.mkdirAll(remoteDir);
        } catch (_) {}
      }

      // 上传文件
      await _client!.writeFromFile(localPath, _config!.remotePath);
      return true;
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }

  /// 从远程下载 vault
  Future<String?> downloadVault(String localPath) async {
    if (_client == null || _config == null) return null;

    try {
      final data = await _client!.read(_config!.remotePath);
      final file = File(localPath);

      // 确保本地目录存在
      final dir = Directory(file.parent.path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsBytes(data);
      return localPath;
    } catch (e) {
      print('❌ Download failed: $e');
      return null;
    }
  }

  /// 断开连接
  void disconnect() {
    _client = null;
    _config = null;
  }
}
