import 'dart:io';
import 'package:note_password/services/sync_service.dart';
import 'package:note_password/platform/ios_sync_service.dart';
import 'package:note_password/platform/android_sync_service.dart';

class SyncServiceFactory {
  static SyncService? _service;
  
  static SyncService getService() {
    if (_service != null) return _service!;
    
    if (Platform.isIOS || Platform.isMacOS) {
      _service = IOSSyncService();
    } else if (Platform.isAndroid) {
      _service = AndroidSyncService();
    } else {
      // Fallback for other platforms - no sync
      _service = _DummySyncService();
    }
    
    return _service!;
  }
  
  static void dispose() {
    (_service as dynamic)?.dispose();
    _service = null;
  }
}

class _DummySyncService implements SyncService {
  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {}
  
  @override
  Future<void> stopWatching() async {}
  
  @override
  Stream<FileChangeEvent> get onFileChanged => const Stream.empty();
  
  @override
  Future<SyncStatus> getSyncStatus() async => SyncStatus.synced;
  
  @override
  Future<bool> hasConflict(String vaultPath) async => false;
  
  @override
  Future<void> createConflictBackup(String vaultPath) async {}
}
