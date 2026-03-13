import 'dart:io';
import '../services/config_service.dart';
import '../services/keychain_service.dart';

/// hedge config - CLI 配置管理命令
class ConfigCommand {
  /// 执行配置命令
  /// [args] 命令参数列表
  /// [options] 额外的选项（从 ArgParser 解析的）
  Future<int> execute(List<String> args, {Map<String, dynamic>? options}) async {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return 0;
    }

    final subCommand = args[0];

    switch (subCommand) {
      case 'show':
        return await _showConfig();

      case 'webdav':
        return await _configureWebDav(args.skip(1).toList(), options: options);

      case 'delete':
        return await _deleteConfig();

      default:
        print('Unknown command: $subCommand');
        _printHelp();
        return 1;
    }
  }

  Future<int> _showConfig() async {
    print('\nCLI Configuration:');

    // 显示 WebDAV 配置来源
    print('\nWebDAV:');

    // 1. 环境变量
    final envUrl = Platform.environment['HEDGE_WEBDAV_URL'];
    if (envUrl != null) {
      print('  Source: Environment variables');
      print('  URL: ${_maskPassword(envUrl)}');
      print('  User: ${Platform.environment['HEDGE_WEBDAV_USERNAME']}');
      print('  Path: ${Platform.environment['HEDGE_WEBDAV_PATH'] ?? 'Hedge/vault.db'}');
      return 0;
    }

    // 2. Keychain
    if (await KeychainService.isAvailable()) {
      final serverUrl = await KeychainService.read('webdav_server_url');
      if (serverUrl != null) {
        print('  Source: System Keychain');
        print('  URL: ${_maskPassword(serverUrl)}');
        final user = await KeychainService.read('webdav_username');
        print('  User: $user');
        final path = await KeychainService.read('webdav_remote_path');
        print('  Path: ${path ?? 'Hedge/vault.db'}');
        return 0;
      }
    }

    // 3. CLI 配置文件
    final cliConfig = await ConfigService.loadWebDavConfig();
    if (cliConfig != null) {
      print('  Source: CLI config file (~/.hedge/cli-config.json)');
      print('  URL: ${_maskPassword(cliConfig.serverUrl)}');
      print('  User: ${cliConfig.username}');
      print('  Path: ${cliConfig.remotePath}');
      return 0;
    }

    print('  Not configured');
    print('\nTo configure WebDAV, run: hedge config webdav');
    return 0;
  }

  Future<int> _configureWebDav(List<String> args, {Map<String, dynamic>? options}) async {
    // 优先使用 options（从 ArgParser 解析）
    String? url = options?['url'] as String?;
    String? user = options?['user'] as String?;
    String? pass = options?['password'] as String?;
    String? path = options?['path'] as String?;

    // 如果 options 中没有，从 args 中解析
    if (url == null) url = args.contains('--url') ? _getArgValue(args, '--url') : null;
    if (user == null) user = args.contains('--user') ? _getArgValue(args, '--user') : null;
    if (pass == null) pass = args.contains('--password') ? _getArgValue(args, '--password') : null;
    if (path == null) path = args.contains('--path') ? _getArgValue(args, '--path') : null;

    // 如果都没有提供，进入交互式配置
    if (url == null || user == null || pass == null) {
      return await _configureWebDavInteractive();
    }

    if (url == null || user == null || pass == null) {
      print('Error: --url, --user, and --password are required');
      return 1;
    }

    final config = WebDavConfig(
      serverUrl: url,
      username: user,
      password: pass,
      remotePath: path ?? 'Hedge/vault.db',
    );

    await ConfigService.saveWebDavConfig(config);
    print('✓ WebDAV configuration saved to CLI config file');
    return 0;
  }

  Future<int> _configureWebDavInteractive() async {
    print('WebDAV Configuration (press Enter to keep current value):\n');

    // 获取当前配置
    final current = await ConfigService.loadWebDavConfig();

    // URL
    stdout.write('Server URL [${current?.serverUrl ?? 'https://example.com/dav/'}]: ');
    final url = _readLine() ?? current?.serverUrl ?? 'https://example.com/dav/';

    // Username
    stdout.write('Username [${current?.username ?? ''}]: ');
    final user = _readLine() ?? current?.username ?? '';

    // Password
    stdout.write('Password: ');
    String pass;
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      pass = stdin.readLineSync() ?? '';
      stdin.echoMode = true;
      print('');
    } else {
      pass = _readLine() ?? current?.password ?? '';
    }

    // Remote Path
    stdout.write('Remote path [${current?.remotePath ?? 'Hedge/vault.db'}]: ');
    final path = _readLine() ?? current?.remotePath ?? 'Hedge/vault.db';

    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      print('Error: URL, username, and password are required');
      return 1;
    }

    final config = WebDavConfig(
      serverUrl: url,
      username: user,
      password: pass,
      remotePath: path,
    );

    await ConfigService.saveWebDavConfig(config);
    print('\n✓ WebDAV configuration saved');
    return 0;
  }

  String? _getArgValue(List<String> args, String flag) {
    final idx = args.indexOf(flag);
    if (idx == -1 || idx + 1 >= args.length) return null;
    return args[idx + 1];
  }

  String? _readLine() {
    final line = stdin.readLineSync();
    return line?.trim().isEmpty == true ? null : line?.trim();
  }

  Future<int> _deleteConfig() async {
    await ConfigService.deleteAllConfig();
    print('✓ CLI configuration deleted');
    return 0;
  }

  String _maskPassword(String url) {
    // 简单掩码处理
    if (url.contains('@')) {
      // 处理 http://user:pass@host 格式
      final uri = Uri.tryParse(url);
      if (uri != null && uri.userInfo.isNotEmpty) {
        final userInfo = uri.userInfo.split(':');
        if (userInfo.length >= 2) {
          return url.replaceFirst(
            '${userInfo[0]}:${userInfo[1]}@',
            '${userInfo[0]}:****@',
          );
        }
      }
    }
    return url;
  }

  void _printHelp() {
    print('''
hedge config - Manage CLI configuration

Usage: hedge config <command>

Commands:
  show            Show current configuration
  webdav          Configure WebDAV sync
  delete          Delete CLI configuration

Examples:
  hedge config show
  hedge config webdav
  hedge config webdav --url https://dav.example.com --user user --password pass
  hedge config delete
''');
  }
}
