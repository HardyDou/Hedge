import 'dart:convert';
import 'dart:io';
import '../crypto/cli_crypto.dart';
import 'cli_session.dart';

/// 会话令牌存储（加密文件 ~/.hedge/cli-session.enc）
class SessionStorage {
  static String get _sessionFilePath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.hedge/cli-session.enc';
  }

  /// 保存会话令牌到加密文件
  static Future<void> saveSession(CliSession session) async {
    final dir = Directory(File(_sessionFilePath).parent.path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final key = CliCryptoService.deriveSessionKey();
    final plaintext = jsonEncode(session.toJson());
    final encrypted = CliCryptoService.encryptString(plaintext, key);

    final file = File(_sessionFilePath);
    await file.writeAsBytes(encrypted);

    // 设置文件权限 0600（仅所有者可读写）
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', _sessionFilePath]);
    }
  }

  /// 从加密文件加载会话令牌
  static Future<CliSession?> loadSession() async {
    final file = File(_sessionFilePath);
    if (!await file.exists()) return null;

    try {
      final encrypted = await file.readAsBytes();
      final key = CliCryptoService.deriveSessionKey();
      final plaintext = CliCryptoService.decryptString(encrypted, key);
      if (plaintext == null) return null;

      final json = jsonDecode(plaintext) as Map<String, dynamic>;
      final session = CliSession.fromJson(json);

      // 过期则删除
      if (session.isExpired) {
        await clearSession();
        return null;
      }

      return session;
    } catch (_) {
      return null;
    }
  }

  /// 清除会话令牌
  static Future<void> clearSession() async {
    final file = File(_sessionFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
