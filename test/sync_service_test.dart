import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_password/src/dart/vault.dart';
import 'package:note_password/services/sync_service.dart';

class MockSyncService extends SyncService {
  final _controller = StreamController<FileChangeEvent>.broadcast();
  bool _watching = false;
  SyncStatus _status = SyncStatus.idle;
  bool _hasConflict = false;
  final List<String> _backups = [];

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    _watching = true;
    _status = SyncStatus.synced;
  }

  @override
  Future<void> stopWatching() async {
    _watching = false;
    _status = SyncStatus.idle;
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _controller.stream;

  @override
  Future<SyncStatus> getSyncStatus() async => _status;

  @override
  Future<bool> hasConflict(String vaultPath) async => _hasConflict;

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    _backups.add('$vaultPath.backup.${DateTime.now().millisecondsSinceEpoch}');
  }

  void simulateFileChange(ChangeType type) {
    _controller.add(FileChangeEvent(type: type, timestamp: DateTime.now()));
  }

  void setConflict(bool value) {
    _hasConflict = value;
  }

  List<String> get backups => _backups;
  bool get isWatching => _watching;
}

void main() {
  group('SyncService', () {
    late MockSyncService syncService;

    setUp(() {
      syncService = MockSyncService();
    });

    tearDown(() {
      syncService.stopWatching();
    });

    test('starts and stops watching', () async {
      expect(syncService.isWatching, false);
      
      await syncService.startWatching('/test/vault.dat');
      expect(syncService.isWatching, true);
      
      await syncService.stopWatching();
      expect(syncService.isWatching, false);
    });

    test('reports correct sync status', () async {
      expect(await syncService.getSyncStatus(), SyncStatus.idle);
      
      await syncService.startWatching('/test/vault.dat');
      expect(await syncService.getSyncStatus(), SyncStatus.synced);
    });

    test('detects file changes', () async {
      await syncService.startWatching('/test/vault.dat');
      
      final futureEvent = syncService.onFileChanged.first;
      syncService.simulateFileChange(ChangeType.modified);
      
      final event = await futureEvent;
      expect(event.type, ChangeType.modified);
    });

    test('detects conflict', () async {
      syncService.setConflict(true);
      expect(await syncService.hasConflict('/test/vault.dat'), true);
      
      syncService.setConflict(false);
      expect(await syncService.hasConflict('/test/vault.dat'), false);
    });

    test('creates conflict backup', () async {
      await syncService.createConflictBackup('/test/vault.dat');
      expect(syncService.backups.length, 1);
      expect(syncService.backups.first.contains('vault.dat.backup'), true);
    });

    test('multiple backups with different timestamps', () async {
      await syncService.createConflictBackup('/test/vault.dat');
      await Future.delayed(const Duration(milliseconds: 10));
      await syncService.createConflictBackup('/test/vault.dat');
      
      expect(syncService.backups.length, 2);
    });
  });

  group('Vault Sync Integration', () {
    test('vault changes trigger file watch events', () async {
      final syncService = MockSyncService();
      
      final vault = VaultService.createEmptyVault();
      expect(vault.items.length, 0);
      
      await syncService.startWatching('/test/vault.dat');
      
      final eventFuture = syncService.onFileChanged.first;
      syncService.simulateFileChange(ChangeType.modified);
      
      final event = await eventFuture;
      expect(event.type, ChangeType.modified);
      
      await syncService.stopWatching();
    });

    test('vault with conflict detection', () async {
      final syncService = MockSyncService();
      
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Test Item');
      expect(withItem.items.length, 1);
      
      syncService.setConflict(true);
      final hasConflict = await syncService.hasConflict('/test/vault.dat');
      expect(hasConflict, true);
      
      if (hasConflict) {
        await syncService.createConflictBackup('/test/vault.dat');
      }
      expect(syncService.backups.length, 1);
    });
  });

  group('FileChangeEvent', () {
    test('creates file change event', () {
      final event = FileChangeEvent(
        type: ChangeType.modified,
        timestamp: DateTime.now(),
        filePath: '/test/vault.dat',
      );
      expect(event.type, ChangeType.modified);
      expect(event.filePath, '/test/vault.dat');
    });

    test('file change event types', () {
      expect(ChangeType.values.length, 3);
      expect(ChangeType.values.contains(ChangeType.modified), true);
      expect(ChangeType.values.contains(ChangeType.deleted), true);
      expect(ChangeType.values.contains(ChangeType.created), true);
    });
  });

  group('SyncStatus', () {
    test('sync status values', () {
      expect(SyncStatus.values.length, 5);
      expect(SyncStatus.values.contains(SyncStatus.idle), true);
      expect(SyncStatus.values.contains(SyncStatus.syncing), true);
      expect(SyncStatus.values.contains(SyncStatus.synced), true);
      expect(SyncStatus.values.contains(SyncStatus.error), true);
      expect(SyncStatus.values.contains(SyncStatus.offline), true);
    });
  });

  group('iCloud Sync Edge Cases', () {
    late MockSyncService syncService;

    setUp(() {
      syncService = MockSyncService();
    });

    tearDown(() async {
      await syncService.stopWatching();
    });

    test('rapid file changes are handled', () async {
      await syncService.startWatching('/test/vault.db');
      
      final events = <FileChangeEvent>[];
      final subscription = syncService.onFileChanged.listen((event) {
        events.add(event);
      });
      
      // Simulate rapid changes
      syncService.simulateFileChange(ChangeType.modified);
      await Future.delayed(const Duration(milliseconds: 10));
      syncService.simulateFileChange(ChangeType.modified);
      await Future.delayed(const Duration(milliseconds: 10));
      syncService.simulateFileChange(ChangeType.modified);
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(events.length, 3);
      
      await subscription.cancel();
    });

    test('file deleted event is handled', () async {
      await syncService.startWatching('/test/vault.db');
      
      final futureEvent = syncService.onFileChanged.first;
      syncService.simulateFileChange(ChangeType.deleted);
      
      final event = await futureEvent;
      expect(event.type, ChangeType.deleted);
    });

    test('file created event is handled', () async {
      await syncService.startWatching('/test/vault.db');
      
      final futureEvent = syncService.onFileChanged.first;
      syncService.simulateFileChange(ChangeType.created);
      
      final event = await futureEvent;
      expect(event.type, ChangeType.created);
    });

    test('conflict backup has unique timestamps', () async {
      await syncService.createConflictBackup('/test/vault.db');
      await Future.delayed(const Duration(milliseconds: 1100));
      await syncService.createConflictBackup('/test/vault.db');
      
      expect(syncService.backups.length, 2);
      expect(syncService.backups[0] != syncService.backups[1], true);
    });

    test('stop watching multiple times is safe', () async {
      await syncService.startWatching('/test/vault.db');
      await syncService.stopWatching();
      await syncService.stopWatching(); // Should not throw
      
      expect(syncService.isWatching, false);
    });

    test('start watching multiple times is idempotent', () async {
      await syncService.startWatching('/test/vault.db');
      await syncService.startWatching('/test/vault.db');
      await syncService.startWatching('/test/vault.db');
      
      expect(syncService.isWatching, true);
    });
  });
}
