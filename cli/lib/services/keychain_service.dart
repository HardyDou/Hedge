import 'dart:io';

/// 系统 Keychain 访问服务
/// 读取 Desktop App（flutter_secure_storage）写入的 Keychain 条目
class KeychainService {
  /// 读取 Keychain 中的值
  static Future<String?> read(String key) async {
    if (Platform.isMacOS) {
      return _readFromMacOSKeychain(key);
    } else if (Platform.isLinux) {
      return _readFromLinuxSecretService(key);
    }
    return null;
  }

  /// macOS: 使用 security 命令读取 Keychain
  /// flutter_secure_storage 使用 app bundle ID 作为服务名
  static Future<String?> _readFromMacOSKeychain(String key) async {
    try {
      // flutter_secure_storage 使用 bundle ID 作为服务名
      // 尝试多种可能的服务名格式
      for (final serviceName in [
        'com.hardydou.hedge',           // 当前 app bundle ID
        'com.hedgehog.hedge',           // 旧 bundle ID
        'flutter_secure_storage',        // 默认服务名
      ]) {
        final result = await Process.run('security', [
          'find-generic-password',
          '-s', serviceName,
          '-a', key,
          '-w', // 只输出密码值
        ]);

        if (result.exitCode == 0) {
          final value = result.stdout.toString().trim();
          if (value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Linux: 使用 secret-tool 读取 Secret Service
  static Future<String?> _readFromLinuxSecretService(String key) async {
    try {
      final result = await Process.run('secret-tool', [
        'lookup',
        'service', 'flutter_secure_storage',
        'account', key,
      ]);

      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        if (value.isNotEmpty) return value;
      }
    } catch (_) {}
    return null;
  }

  /// 检查 Keychain 访问是否可用
  static Future<bool> isAvailable() async {
    if (Platform.isMacOS) {
      try {
        final result = await Process.run('security', ['--version']);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    } else if (Platform.isLinux) {
      try {
        final result = await Process.run('which', ['secret-tool']);
        return result.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
