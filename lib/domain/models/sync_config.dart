/// 同步模式
enum SyncMode {
  local,   // 仅本地存储
  icloud,  // iCloud Drive（仅 iOS/macOS）
  webdav,  // WebDAV（所有平台）
}

/// WebDAV 配置
class WebDAVConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;

  WebDAVConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remotePath = 'Hedge/vault.db',
  });

  Map<String, String> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'remotePath': remotePath,
    };
  }

  factory WebDAVConfig.fromJson(Map<String, String> json) {
    return WebDAVConfig(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      remotePath: json['remotePath'] ?? 'Hedge/vault.db',
    );
  }
}

/// 同步配置
class SyncConfig {
  final SyncMode mode;
  final WebDAVConfig? webdavConfig;

  SyncConfig({
    required this.mode,
    this.webdavConfig,
  });

  bool get isWebDAV => mode == SyncMode.webdav;
  bool get isICloud => mode == SyncMode.icloud;
  bool get isLocal => mode == SyncMode.local;
}
