import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:hedge/services/sync_service.dart';

class WebDAVSyncService implements SyncService {
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  webdav.Client? _client;
  Timer? _pollTimer;
  String? _vaultPath;
  String? _remotePath;

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
      debug: false, // 关闭调试日志
    );

    // 测试连接
    try {
      await _client!.ping();
      debugPrint('[WebDAV] Connection successful: $serverUrl');
    } catch (e) {
      debugPrint('[WebDAV] Connection failed: $e');
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
        debugPrint('[WebDAV] File is in root directory, no need to create directory');
        return;
      }

      final dirPath = _remotePath!.substring(0, lastSlashIndex);

      // 如果目录路径为空，说明文件在根目录
      if (dirPath.isEmpty) {
        debugPrint('[WebDAV] File is in root directory, no need to create directory');
        return;
      }

      // 递归创建所有父目录
      await _createDirectoryRecursive(dirPath);
      debugPrint('[WebDAV] Ensured remote directory exists: $dirPath');
    } catch (e) {
      debugPrint('[WebDAV] Failed to ensure directory: $e');
      // 不抛出异常，继续尝试上传
    }
  }

  /// 递归创建目录
  Future<void> _createDirectoryRecursive(String path) async {
    if (_client == null || path.isEmpty) return;

    try {
      // 尝试创建目录
      await _client!.mkdir(path);
      debugPrint('[WebDAV] Created directory: $path');
    } catch (e) {
      // 如果失败，可能是父目录不存在，先创建父目录
      final lastSlashIndex = path.lastIndexOf('/');
      if (lastSlashIndex > 0) {
        final parentPath = path.substring(0, lastSlashIndex);
        await _createDirectoryRecursive(parentPath);
        // 再次尝试创建当前目录
        try {
          await _client!.mkdir(path);
          debugPrint('[WebDAV] Created directory: $path');
        } catch (e2) {
          // 目录可能已存在，忽略
          debugPrint('[WebDAV] Directory might already exist: $path');
        }
      } else {
        // 已经是顶级目录，忽略错误
        debugPrint('[WebDAV] Directory might already exist: $path');
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

      debugPrint('[WebDAV] Uploaded vault: $_remotePath (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('[WebDAV] Upload failed: $e');
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
      debugPrint('[WebDAV] Downloaded vault: $localPath (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('[WebDAV] Download failed: $e');
      throw Exception('WebDAV download failed: $e');
    }
  }

  /// 检查远程文件是否存在
  Future<bool> remoteVaultExists() async {
    // 通过获取修改时间来判断文件是否存在，避免 read() 下载整个文件
    return await getRemoteModificationTime() != null;
  }

  /// 获取远程文件修改时间
  ///
  /// webdav_client 的 readDir/readProps 会对路径调用 fixSlashes()，
  /// 导致文件路径末尾被加上 "/"（如 vault.db/），服务器返回 400。
  /// 正确做法：对父目录调用 readDir，再从结果中找到目标文件。
  Future<DateTime?> getRemoteModificationTime() async {
    if (_client == null || _remotePath == null) return null;

    try {
      final lastSlash = _remotePath!.lastIndexOf('/');
      final dirPath = lastSlash > 0 ? _remotePath!.substring(0, lastSlash) : '/';
      final fileName = lastSlash >= 0
          ? _remotePath!.substring(lastSlash + 1)
          : _remotePath!;

      final entries = await _client!.readDir(dirPath);
      for (final entry in entries) {
        if (entry.name == fileName) {
          return entry.mTime;
        }
      }
    } catch (e) {
      debugPrint('[WebDAV] Failed to get remote modification time: $e');
    }
    return null;
  }

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    _vaultPath = vaultPath;

    // 开始轮询（每 30 秒与远端比较，远端更新则下载）
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkRemoteChanges());

    debugPrint('[WebDAV] Started watching: $vaultPath');
  }

  /// 立即触发一次远端检查（供 app 回到前台时调用）
  @override
  Future<void> triggerCheck() async => _checkRemoteChanges();

  /// 检查远程文件是否比本地更新；若是则下载并通知
  Future<void> _checkRemoteChanges() async {
    if (_vaultPath == null) return;

    try {
      final remoteMtime = await getRemoteModificationTime();
      if (remoteMtime == null) return;

      final localFile = File(_vaultPath!);
      if (!await localFile.exists()) {
        debugPrint('[WebDAV] Local file missing, downloading from remote...');
        await downloadVault(_vaultPath!);
        _eventController.add(FileChangeEvent(
          type: ChangeType.created,
          timestamp: remoteMtime,
          filePath: _vaultPath,
        ));
        return;
      }

      final localMtime = await localFile.lastModified();
      if (remoteMtime.isAfter(localMtime)) {
        debugPrint('[WebDAV] Remote is newer, downloading...');
        await downloadVault(_vaultPath!);
        _eventController.add(FileChangeEvent(
          type: ChangeType.modified,
          timestamp: remoteMtime,
          filePath: _vaultPath,
        ));
      }
    } catch (e) {
      debugPrint('[WebDAV] Error checking remote changes: $e');
    }
  }

  @override
  Future<void> stopWatching() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _vaultPath = null;
    debugPrint('[WebDAV] Stopped watching');
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
    debugPrint('[WebDAV] Created conflict backup: $backupPath');
  }

  void dispose() {
    stopWatching();
    _eventController.close();
    _client = null;
  }
}
