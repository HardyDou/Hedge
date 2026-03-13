import 'dart:io';
import '../services/webdav_sync_service.dart';

/// hedge sync - WebDAV 同步命令
class SyncCommand {
  final WebDavSyncService _syncService = WebDavSyncService();

  Future<int> execute({
    bool showStatus = false,
    bool forceUpload = false,
    bool forceDownload = false,
    List<String> args = const [],
  }) async {
    // Handle --help from args for backward compatibility
    if (args.isNotEmpty && (args.contains('--help') || args.contains('-h'))) {
      _printHelp();
      return 0;
    }

    if (showStatus) {
      return await _showStatus();
    }

    if (forceUpload) {
      return await _forceUpload();
    }

    if (forceDownload) {
      return await _forceDownload();
    }

    // 默认：智能同步
    return await _sync();
  }

  Future<int> _showStatus() async {
    final status = await _syncService.getSyncStatus();
    if (status == null) {
      print('❌ Failed to get sync status. Please check WebDAV configuration.');
      return 1;
    }

    print('\nSync Status:');
    print('  Remote: ${status['remote_url']}${status['remote_path']}');

    if (status['local_modified'] != null) {
      final localTime = DateTime.parse(status['local_modified']);
      print('  Local:  ${_formatDateTime(localTime)}');
    } else {
      print('  Local:  No local vault found');
    }

    if (status['remote_modified'] != null) {
      final remoteTime = DateTime.parse(status['remote_modified']);
      print('  Remote: ${_formatDateTime(remoteTime)}');
    } else {
      print('  Remote: No remote vault found');
    }

    print('');
    return 0;
  }

  Future<int> _forceUpload() async {
    print('🔄 Uploading vault to WebDAV...');

    final localPath = await _syncService.getLocalVaultPath();
    if (localPath == null) {
      print('❌ No local vault found');
      return 1;
    }

    if (!await _syncService.connect()) {
      print('❌ Failed to connect to WebDAV server');
      return 1;
    }

    final success = await _syncService.uploadVault(localPath);
    _syncService.disconnect();

    if (success) {
      print('✓ Upload complete');
      return 0;
    } else {
      print('❌ Upload failed');
      return 1;
    }
  }

  Future<int> _forceDownload() async {
    print('🔄 Downloading vault from WebDAV...');

    if (!await _syncService.connect()) {
      print('❌ Failed to connect to WebDAV server');
      return 1;
    }

    final localPath = await _syncService.getLocalVaultPath();
    if (localPath == null) {
      // 使用默认路径
      final home = Platform.environment['HOME'] ?? '';
      final vaultPath = '$home/.hedge/vault.db';
      final result = await _syncService.downloadVault(vaultPath);
      _syncService.disconnect();

      if (result != null) {
        print('✓ Download complete: $result');
        return 0;
      } else {
        print('❌ Download failed');
        return 1;
      }
    } else {
      // 创建冲突备份
      final backupPath = '$localPath.backup.${DateTime.now().millisecondsSinceEpoch}';
      await File(localPath).copy(backupPath);
      print('✓ Backup created: $backupPath');

      final result = await _syncService.downloadVault(localPath);
      _syncService.disconnect();

      if (result != null) {
        print('✓ Download complete: $result');
        return 0;
      } else {
        print('❌ Download failed');
        return 1;
      }
    }
  }

  Future<int> _sync() async {
    print('🔄 Connecting to WebDAV...');

    if (!await _syncService.connect()) {
      print('❌ Failed to connect to WebDAV server');
      print('\nPlease configure WebDAV using: hedge config webdav');
      return 1;
    }

    final localPath = await _syncService.getLocalVaultPath();
    final localMod = await _syncService.getLocalModifiedTime();
    final remoteMod = await _syncService.getRemoteModifiedTime();

    if (localPath == null && remoteMod == null) {
      print('❌ No vault found locally or remotely');
      _syncService.disconnect();
      return 1;
    }

    if (localPath == null && remoteMod != null) {
      // 只有远程有，执行下载
      print('📥 Downloading vault from remote...');
      final home = Platform.environment['HOME'] ?? '';
      final vaultPath = '$home/.hedge/vault.db';
      final result = await _syncService.downloadVault(vaultPath);
      _syncService.disconnect();

      if (result != null) {
        print('✓ Synced successfully (downloaded)');
        return 0;
      } else {
        print('❌ Sync failed');
        return 1;
      }
    }

    if (localPath != null && remoteMod == null) {
      // 只有本地有，执行上传
      print('📤 Uploading vault to remote...');
      final success = await _syncService.uploadVault(localPath);
      _syncService.disconnect();

      if (success) {
        print('✓ Synced successfully (uploaded)');
        return 0;
      } else {
        print('❌ Sync failed');
        return 1;
      }
    }

    // 两者都有，比较时间
    if (localMod != null && remoteMod != null && localPath != null) {
      final diff = localMod.difference(remoteMod);

      if (diff.isNegative) {
        // 远程更新，下载
        print('📥 Remote is newer. Downloading...');
        final backupPath = '$localPath.backup.${DateTime.now().millisecondsSinceEpoch}';
        await File(localPath).copy(backupPath);
        print('✓ Backup created: $backupPath');

        final result = await _syncService.downloadVault(localPath);
        _syncService.disconnect();

        if (result != null) {
          print('✓ Synced successfully (downloaded)');
          return 0;
        } else {
          print('❌ Sync failed');
          return 1;
        }
      } else if (diff.inSeconds > 1) {
        // 本地更新，上传
        print('📤 Local is newer. Uploading...');
        final success = await _syncService.uploadVault(localPath);
        _syncService.disconnect();

        if (success) {
          print('✓ Synced successfully (uploaded)');
          return 0;
        } else {
          print('❌ Sync failed');
          return 1;
        }
      } else {
        // 已同步
        print('✓ Already in sync');
        _syncService.disconnect();
        return 0;
      }
    }

    _syncService.disconnect();
    return 0;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  void _printHelp() {
    print('''
hedge sync - Sync vault via WebDAV

Usage: hedge sync [options]

Options:
  --status           Show sync status
  --force-upload     Force upload local vault to remote (overwrites remote)
  --force-download   Force download remote vault to local (overwrites local)

Examples:
  hedge sync             # Smart sync (download newer or upload newer)
  hedge sync --status    # Show sync status
  hedge sync --force-upload   # Force upload
''');
  }
}
