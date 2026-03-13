import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import '../lib/version.dart';
import '../lib/auth/auth_manager.dart';
import '../lib/commands/get_command.dart';
import '../lib/commands/list_command.dart';
import '../lib/commands/search_command.dart';
import '../lib/commands/lock_command.dart';
import '../lib/commands/unlock_command.dart';
import '../lib/commands/sync_command.dart';
import '../lib/commands/config_command.dart';
import '../lib/ipc/ipc_client.dart';
import '../lib/session/session_storage.dart';

void main(List<String> arguments) async {
  final parser = ArgParser(allowTrailingOptions: true)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version')
    ..addFlag('no-app', negatable: false,
        help: 'Force standalone mode (skip Desktop App, use master password). '
              'Set HEDGE_MASTER_PASSWORD env var for non-interactive use.')
    ..addFlag('no-copy', negatable: false, help: 'Output to stdout instead of clipboard')
    ..addFlag('output-token', negatable: false, help: 'Output session token (for unlock command)')
    ..addFlag('native-messaging', negatable: false,
        help: 'Run in Native Messaging mode (for browser extension)')
    ..addFlag('verbose', abbr: 'V', negatable: false, help: 'Enable verbose output')
    ..addOption('field', help: 'Field to get (username, password, url, notes)')
    // Sync options
    ..addFlag('status', help: 'Show sync status')
    ..addFlag('force-upload', help: 'Force upload to remote')
    ..addFlag('force-download', help: 'Force download from remote');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printHelp(parser);
      exit(0);
    }

    if (results['version'] as bool) {
      print('hedge CLI v$version');
      exit(0);
    }

    // Native Messaging mode (browser extension)
    if (results['native-messaging'] as bool) {
      await _runNativeMessaging();
      exit(0);
    }

    final command = results.rest.isNotEmpty ? results.rest[0] : '';
    final authManager = AuthManager();

    try {
      int exitCode = 0;

      switch (command) {
        case 'get':
          if (results.rest.length < 2) {
            print('Usage: hedge get <item>');
            exitCode = 1;
          } else {
            final query = results.rest[1];
            final getCmd = GetCommand(authManager);
            exitCode = await getCmd.execute(
              query,
              field: results['field'] as String?,
              noCopy: results['no-copy'] as bool,
              forceStandalone: results['no-app'] as bool,
            );
          }
          break;

        case 'list':
          final listCmd = ListCommand(authManager);
          exitCode = await listCmd.execute(
            forceStandalone: results['no-app'] as bool,
          );
          break;

        case 'search':
          if (results.rest.length < 2) {
            print('Usage: hedge search <query>');
            exitCode = 1;
          } else {
            final query = results.rest[1];
            final searchCmd = SearchCommand(authManager);
            exitCode = await searchCmd.execute(
              query,
              forceStandalone: results['no-app'] as bool,
            );
          }
          break;

        case 'lock':
          final lockCmd = LockCommand();
          exitCode = await lockCmd.execute();
          break;

        case 'unlock':
          final unlockCmd = UnlockCommand(authManager);
          exitCode = await unlockCmd.execute(
            forceStandalone: results['no-app'] as bool,
            outputToken: results['output-token'] as bool,
          );
          break;

        case 'sync':
          final syncCmd = SyncCommand();
          exitCode = await syncCmd.execute(
            showStatus: results['status'] as bool? ?? false,
            forceUpload: results['force-upload'] as bool? ?? false,
            forceDownload: results['force-download'] as bool? ?? false,
          );
          break;

        case 'config':
          final configCmd = ConfigCommand();
          exitCode = await configCmd.execute(results.rest.skip(1).toList());
          break;

        default:
          _printHelp(parser);
          exitCode = command.isEmpty ? 0 : 1;
      }

      await authManager.dispose();
      exit(exitCode);
    } catch (e) {
      print('Error: $e');
      await authManager.dispose();
      exit(1);
    }
  } catch (e) {
    print('Error parsing arguments: $e');
    _printHelp(parser);
    exit(1);
  }
}

/// Native Messaging mode: stdin/stdout JSON communication (Chrome Native Messaging protocol)
/// Format: [4-byte length LE][JSON payload]
Future<void> _runNativeMessaging() async {
  final ipcClient = IpcClient();
  final session = await SessionStorage.loadSession();

  await for (final request in _readNativeMessages()) {
    Map<String, dynamic> response;

    try {
      final method = request['method'] as String?;
      final params = request['params'] as Map<String, dynamic>? ?? {};

      switch (method) {
        case 'get_password':
          if (!IpcClient.isDesktopAppRunning()) {
            response = _nmError('Desktop App not running. Please open Hedge.');
          } else if (session == null || session.isExpired) {
            response = _nmError('Vault not unlocked. Please unlock Hedge first.');
          } else {
            if (!ipcClient.isConnected) await ipcClient.connect();
            final url = params['url'] as String? ?? '';
            final result = await ipcClient.getPassword(session.tokenId, url);
            if (result != null) {
              response = {'success': true, 'data': result};
            } else {
              response = _nmError('No matching item found for "$url"');
            }
          }
          break;

        case 'list_items':
          if (!IpcClient.isDesktopAppRunning()) {
            response = _nmError('Desktop App not running. Please open Hedge.');
          } else if (session == null || session.isExpired) {
            response = _nmError('Vault not unlocked. Please unlock Hedge first.');
          } else {
            if (!ipcClient.isConnected) await ipcClient.connect();
            final items = await ipcClient.listItems(session.tokenId);
            if (items != null) {
              response = {'success': true, 'items': items};
            } else {
              response = _nmError('Failed to list items');
            }
          }
          break;

        case 'ping':
          response = {'success': true, 'version': version};
          break;

        default:
          response = _nmError('Unknown method: $method');
      }
    } catch (e) {
      response = _nmError('Internal error: $e');
    }

    _writeNativeMessage(response);
  }

  await ipcClient.disconnect();
}

Map<String, dynamic> _nmError(String message) => {'success': false, 'error': message};

Stream<Map<String, dynamic>> _readNativeMessages() async* {
  final input = stdin;
  final buffer = <int>[];

  await for (final chunk in input) {
    buffer.addAll(chunk);

    while (buffer.length >= 4) {
      // Little-endian 4-byte length prefix (Chrome Native Messaging)
      final length = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16) | (buffer[3] << 24);

      if (buffer.length < 4 + length) break;

      final payload = buffer.sublist(4, 4 + length);
      buffer.removeRange(0, 4 + length);

      try {
        final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        yield json;
      } catch (_) {}
    }
  }
}

void _writeNativeMessage(Map<String, dynamic> message) {
  final payload = utf8.encode(jsonEncode(message));
  final length = payload.length;
  final header = [
    length & 0xFF,
    (length >> 8) & 0xFF,
    (length >> 16) & 0xFF,
    (length >> 24) & 0xFF,
  ];
  stdout.add(header);
  stdout.add(payload);
}

void _printHelp(ArgParser parser) {
  print('''
Hedge Password Manager CLI v$version

Usage: hedge <command> [options]

Commands:
  get <item>       Get password (copies to clipboard by default)
  list             List all vault items
  search <query>   Search vault items
  lock             Lock CLI session
  unlock           Unlock CLI session (creates session token)
  sync             Sync vault via WebDAV
  config           Manage CLI configuration

Options:
${parser.usage}

Environment Variables:
  HEDGE_VAULT_PATH          Path to vault file (overrides auto-discovery)
  HEDGE_MASTER_PASSWORD     Master password for --no-app mode (CI/CD use)
  HEDGE_WEBDAV_URL          WebDAV server URL
  HEDGE_WEBDAV_USERNAME     WebDAV username
  HEDGE_WEBDAV_PASSWORD     WebDAV password
  HEDGE_WEBDAV_PATH         WebDAV remote path (default: Hedge/vault.db)

Examples:
  hedge get github
  hedge get aws --field username
  hedge list
  hedge search google
  hedge lock
  hedge unlock
  hedge sync
  hedge sync --status
  hedge config show
  hedge config webdav

  # CI/CD usage
  export HEDGE_MASTER_PASSWORD="your-password"
  hedge get production-db --no-app --no-copy
''');
}
