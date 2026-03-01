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
