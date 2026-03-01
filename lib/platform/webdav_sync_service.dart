import 'dart:async';
import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:hedge/services/sync_service.dart';

class WebDAVSyncService implements SyncService {
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  webdav.Client? _client;
  Timer? _pollTimer;
  String? _vaultPath;
  String? _remotePath;
  DateTime? _lastRemoteModification;

  /// 初始化 WebDAV 客户端
  Future<void> initialize({
    required String serverUrl,
    required String username,
    required String password,
    String remotePath = 'Hedge/vault.db',
  }) async {
    _remotePath = remotePath;

    // 创建 WebDAV 客户端
    _client = webdav.newClient(
      serverUrl,
      user: username,
      password: password,
      debug: true,
    );

    // 测试连接
    try {
      await _client!.ping();
      print('[WebDAV] Connection successful: $serverUrl');
    } catch (e) {
      print('[WebDAV] Connection failed: $e');
      throw Exception('WebDAV connection failed: $e');
    }

    // 确保远程目录存在
    await _ensureRemoteDirectory();
  }

  /// 确保远程目录存在
  Future<void> _ensureRemoteDirectory() async {
    if (_client == null || _remotePath == null) return;

    try {
      final lastSlashIndex = _remotePath!.lastIndexOf('/');

      // 如果路径中没有 /，说明文件在根目录，不需要创建目录
      if (lastSlashIndex == -1) {
        print('[WebDAV] File is in root directory, no need to create directory');
        return;
      }

      final dirPath = _remotePath!.substring(0, lastSlashIndex);

      // 如果目录路径为空，说明文件在根目录
      if (dirPath.isEmpty) {
        print('[WebDAV] File is in root directory, no need to create directory');
        return;
      }

      // 递归创建所有父目录
      await _createDirectoryRecursive(dirPath);
      print('[WebDAV] Ensured remote directory exists: $dirPath');
    } catch (e) {
      print('[WebDAV] Failed to ensure directory: $e');
      // 不抛出异常，继续尝试上传
    }
  }

  /// 递归创建目录
  Future<void> _createDirectoryRecursive(String path) async {
    if (_client == null || path.isEmpty) return;

    try {
      // 尝试创建目录
      await _client!.mkdir(path);
      print('[WebDAV] Created directory: $path');
    } catch (e) {
      // 如果失败，可能是父目录不存在，先创建父目录
      final lastSlashIndex = path.lastIndexOf('/');
      if (lastSlashIndex > 0) {
        final parentPath = path.substring(0, lastSlashIndex);
        await _createDirectoryRecursive(parentPath);
        // 再次尝试创建当前目录
        try {
          await _client!.mkdir(path);
          print('[WebDAV] Created directory: $path');
        } catch (e2) {
          // 目录可能已存在，忽略
          print('[WebDAV] Directory might already exist: $path');
        }
      } else {
        // 已经是顶级目录，忽略错误
        print('[WebDAV] Directory might already exist: $path');
      }
    }
  }

  /// 上传文件到 WebDAV
  Future<void> uploadVault(String localPath) async {
    if (_client == null || _remotePath == null) {
      throw Exception('WebDAV not initialized');
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Local vault file not found: $localPath');
      }

      final bytes = await file.readAsBytes();
      await _client!.write(_remotePath!, bytes);

      _lastRemoteModification = DateTime.now();
      print('[WebDAV] Uploaded vault: $_remotePath (${bytes.length} bytes)');
    } catch (e) {
      print('[WebDAV] Upload failed: $e');
      throw Exception('WebDAV upload failed: $e');
    }
  }

  /// 从 WebDAV 下载文件
  Future<void> downloadVault(String localPath) async {
    if (_client == null || _remotePath == null) {
      throw Exception('WebDAV not initialized');
    }

    try {
      final bytes = await _client!.read(_remotePath!);
      final file = File(localPath);

      // 确保本地目录存在
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await file.writeAsBytes(bytes);
      print('[WebDAV] Downloaded vault: $localPath (${bytes.length} bytes)');
    } catch (e) {
      print('[WebDAV] Download failed: $e');
      throw Exception('WebDAV download failed: $e');
    }
  }

  /// 检查远程文件是否存在
  Future<bool> remoteVaultExists() async {
    if (_client == null || _remotePath == null) return false;

    try {
      await _client!.read(_remotePath!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取远程文件修改时间
  Future<DateTime?> getRemoteModificationTime() async {
    if (_client == null || _remotePath == null) return null;

    try {
      final list = await _client!.readDir(_remotePath!);
      if (list.isNotEmpty) {
        return list.first.mTime;
      }
    } catch (e) {
      print('[WebDAV] Failed to get remote modification time: $e');
    }
    return null;
  }

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    _vaultPath = vaultPath;

    // 获取初始远程修改时间
    _lastRemoteModification = await getRemoteModificationTime();

    // 开始轮询检查远程变化（每 30 秒）
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkRemoteChanges());

    print('[WebDAV] Started watching: $vaultPath');
  }

  /// 检查远程文件是否有变化
  Future<void> _checkRemoteChanges() async {
    if (_vaultPath == null) return;

    try {
      final currentRemoteMod = await getRemoteModificationTime();

      if (currentRemoteMod != null &&
          _lastRemoteModification != null &&
          currentRemoteMod.isAfter(_lastRemoteModification!)) {
        print('[WebDAV] Remote file changed, downloading...');

        // 下载新版本
        await downloadVault(_vaultPath!);
        _lastRemoteModification = currentRemoteMod;

        // 通知文件变化
        _eventController.add(FileChangeEvent(
          type: ChangeType.modified,
          timestamp: currentRemoteMod,
          filePath: _vaultPath,
        ));
      }
    } catch (e) {
      print('[WebDAV] Error checking remote changes: $e');
    }
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

  @override
  Future<SyncStatus> getSyncStatus() async {
    if (_client == null) return SyncStatus.offline;

    try {
      await _client!.ping();
      return SyncStatus.synced;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    // WebDAV 使用服务器端文件作为真实来源
    // 冲突由修改时间比较处理
    return false;
  }

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    final file = File(vaultPath);
    if (!await file.exists()) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = vaultPath.replaceAll('.db', '_conflict_$timestamp.db');

    await file.copy(backupPath);
    print('[WebDAV] Created conflict backup: $backupPath');
  }

  void dispose() {
    stopWatching();
    _eventController.close();
    _client = null;
  }
}
