import 'dart:convert';
import 'dart:io';
import '../crypto/cli_crypto.dart';
import 'vault_models.dart';

class VaultLoader {
  /// 发现 vault 文件路径（按优先级）
  static Future<String?> discoverVaultPath() async {
    // 1. 环境变量
    final envPath = Platform.environment['HEDGE_VAULT_PATH'];
    if (envPath != null && await File(envPath).exists()) {
      return envPath;
    }

    // 2. 配置文件 ~/.hedge/cli-config.json
    final configPath = _expandHome('~/.hedge/cli-config.json');
    if (await File(configPath).exists()) {
      try {
        final content = await File(configPath).readAsString();
        final config = jsonDecode(content) as Map<String, dynamic>;
        final path = config['vault_path'] as String?;
        if (path != null && await File(path).exists()) {
          return path;
        }
      } catch (_) {}
    }

    // 3. Linux 旧路径迁移兼容 (~/.local/share/hedge/vault.db)
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final oldLinuxPath = '$home/.local/share/hedge/vault.db';
        if (await File(oldLinuxPath).exists()) {
          return oldLinuxPath;
        }
      }
    }

    // 4. 统一默认路径 ~/.hedge/vault.db（macOS/Linux/Windows）
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final defaultPath = '$home/.hedge/vault.db';
      if (await File(defaultPath).exists()) {
        return defaultPath;
      }
    }

    // 4. macOS iCloud Drive（保持兼容）
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final icloudPath =
            '$home/Library/Mobile Documents/com~apple~CloudDocs/Hedge/vault.db';
        if (await File(icloudPath).exists()) {
          return icloudPath;
        }
      }
    }

    return null;
  }

  /// 加载并解密 vault
  static Future<Vault?> loadVault(String path, String password) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final data = await file.readAsBytes();
    final json = await CliCryptoService.decryptJson(data, password);
    if (json == null) return null;

    return Vault.fromJson(json);
  }

  static String _expandHome(String path) {
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home${path.substring(1)}';
    }
    return path;
  }
}
