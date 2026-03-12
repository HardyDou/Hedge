import 'dart:io';
import 'package:args/args.dart';
import 'package:hedge_cli/version.dart';
import '../lib/auth/auth_manager.dart';
import '../lib/commands/get_command.dart';
import '../lib/commands/list_command.dart';
import '../lib/commands/search_command.dart';
import '../lib/commands/lock_command.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version')
    ..addFlag('no-app', negatable: false,
        help: 'Force standalone mode (skip Desktop App, use master password). '
              'Set HEDGE_MASTER_PASSWORD env var for non-interactive use.')
    ..addFlag('no-copy', negatable: false, help: 'Output to stdout instead of clipboard')
    ..addOption('field', help: 'Field to get (username, password, url, notes)');

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

        default:
          _printHelp(parser);
          exitCode = 1;
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

void _printHelp(ArgParser parser) {
  print('''
Hedge Password Manager CLI v$version

Usage: hedge <command> [options]

Commands:
  get <item>       Get password (copies to clipboard by default)
  list             List all vault items
  search <query>   Search vault items
  lock             Lock CLI session

Options:
${parser.usage}

Environment Variables:
  HEDGE_VAULT_PATH          Path to vault file (overrides auto-discovery)
  HEDGE_MASTER_PASSWORD     Master password for --no-app mode (CI/CD use)

Examples:
  hedge get github
  hedge get aws --field username
  hedge list
  hedge search google
  hedge lock

  # CI/CD usage
  export HEDGE_MASTER_PASSWORD="your-password"
  hedge get production-db --no-app --no-copy
''');
}
