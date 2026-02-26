import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:note_password/services/sync_service.dart';
import 'package:path_provider/path_provider.dart';

class IOSSyncService implements SyncService {
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  Timer? _pollTimer;
  DateTime? _lastKnownModification;
  String? _vaultPath;
  String? _masterPassword;
  
  IOSSyncService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  static const _channel = MethodChannel('com.hardydou.notePassword/sync');
  
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
    _vaultPath = vaultPath;
    _masterPassword = masterPassword;
    
    // Get initial modification time
    final file = File(vaultPath);
    if (await file.exists()) {
      _lastKnownModification = await file.lastModified();
    }
    
    // Start polling every 2 seconds
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkForChanges());
  }
  
  Future<void> _checkForChanges() async {
    if (_vaultPath == null) return;
    
    final file = File(_vaultPath!);
    if (!await file.exists()) return;
    
    try {
      final currentMod = await file.lastModified();
      if (_lastKnownModification != null && 
          currentMod.difference(_lastKnownModification!).inMilliseconds > 1000) {
        // File has changed - this could be from iCloud sync!
        print('[iCloud Sync] Detected file change: $_vaultPath at $currentMod');
        _lastKnownModification = currentMod;
        
        _eventController.add(FileChangeEvent(
          type: ChangeType.modified,
          timestamp: DateTime.now(),
          filePath: _vaultPath,
        ));
      }
    } catch (e) {
      print('[iCloud Sync] Error checking changes: $e');
    }
  }

  @override
  Future<void> stopWatching() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _vaultPath = null;
    _masterPassword = null;
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _eventController.stream;

  @override
  Future<SyncStatus> getSyncStatus() async {
    return SyncStatus.synced;
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    final file = File(vaultPath);
    final directory = file.parent;
    final fileName = file.path.split('/').last.replaceAll('.db', '');
    
    try {
      final files = directory.listSync();
      return files.any((f) => 
        f.path.contains('${fileName}_') && 
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
    final backupPath = vaultPath.replaceAll('.db', '_$timestamp.db');
    
    await file.copy(backupPath);
  }
  
  void dispose() {
    _pollTimer?.cancel();
    _eventController.close();
  }
}
