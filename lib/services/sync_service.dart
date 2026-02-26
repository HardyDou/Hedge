import 'dart:async';

enum ChangeType { modified, deleted, created }

class FileChangeEvent {
  final ChangeType type;
  final DateTime timestamp;
  final String? filePath;

  FileChangeEvent({
    required this.type,
    required this.timestamp,
    this.filePath,
  });
}

enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
  offline,
}

abstract class SyncService {
  Future<void> startWatching(String vaultPath, {String? masterPassword});
  Future<void> stopWatching();
  Stream<FileChangeEvent> get onFileChanged;
  Future<SyncStatus> getSyncStatus();
  Future<bool> hasConflict(String vaultPath);
  Future<void> createConflictBackup(String vaultPath);
}
