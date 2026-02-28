import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hedge/services/sync_service.dart';

class AndroidSyncService implements SyncService {
  static const _channel = MethodChannel('com.hardydou.hedge/sync');
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  
  AndroidSyncService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFileChanged') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final type = args['type'] as String;
      final timestamp = args['timestamp'] as int;
      
      _eventController.add(FileChangeEvent(
        type: type == 'modified' ? ChangeType.modified 
            : type == 'deleted' ? ChangeType.deleted 
            : ChangeType.created,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      ));
    }
  }

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    await _channel.invokeMethod('startWatching', {'path': vaultPath});
  }

  @override
  Future<void> stopWatching() async {
    await _channel.invokeMethod('stopWatching');
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _eventController.stream;

  @override
  Future<SyncStatus> getSyncStatus() async {
    return SyncStatus.synced;
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    return await _channel.invokeMethod('hasConflict', {'path': vaultPath}) ?? false;
  }

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    await _channel.invokeMethod('createConflictBackup', {'path': vaultPath});
  }
  
  void dispose() {
    _eventController.close();
  }
}
