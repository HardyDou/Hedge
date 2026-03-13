import 'dart:convert';
import 'dart:io';

/// WebDAV 配置模型
class WebDavConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;

  WebDavConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.remotePath,
  });

  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      serverUrl: json['server_url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      remotePath: json['remote_path'] as String? ?? 'Hedge/vault.db',
    );
  }

  Map<String, dynamic> toJson() => {
        'server_url': serverUrl,
        'username': username,
        'password': password,
        'remote_path': remotePath,
      };

  @override
  String toString() =>
      'WebDavConfig(url: $serverUrl, user: $username, path: $remotePath)';
}

/// CLI 配置管理服务
/// 管理 ~/.hedge/cli-config.json
class ConfigService {
  static String get _configFilePath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.hedge/cli-config.json';
  }

  /// 加载 CLI 配置文件
  static Future<Map<String, dynamic>?> loadConfig() async {
    final file = File(_configFilePath);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 保存 CLI 配置文件
  static Future<void> saveConfig(Map<String, dynamic> config) async {
    final dir = Directory(File(_configFilePath).parent.path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(_configFilePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
    );

    // 设置文件权限 0600
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', _configFilePath]);
    }
  }

  /// 从配置文件加载 WebDAV 配置
  static Future<WebDavConfig?> loadWebDavConfig() async {
    final config = await loadConfig();
    if (config == null) return null;

    final webdav = config['webdav'] as Map<String, dynamic>?;
    if (webdav == null) return null;

    try {
      return WebDavConfig.fromJson(webdav);
    } catch (_) {
      return null;
    }
  }

  /// 保存 WebDAV 配置到配置文件
  static Future<void> saveWebDavConfig(WebDavConfig config) async {
    final existing = await loadConfig() ?? {};
    existing['webdav'] = config.toJson();
    await saveConfig(existing);
  }

  /// 删除 WebDAV 配置
  static Future<void> deleteWebDavConfig() async {
    final existing = await loadConfig() ?? {};
    existing.remove('webdav');
    if (existing.isEmpty) {
      final file = File(_configFilePath);
      if (await file.exists()) await file.delete();
    } else {
      await saveConfig(existing);
    }
  }

  /// 删除整个配置文件
  static Future<void> deleteAllConfig() async {
    final file = File(_configFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 是否有 WebDAV 配置
  static Future<bool> hasWebDavConfig() async {
    final config = await loadWebDavConfig();
    return config != null;
  }
}
