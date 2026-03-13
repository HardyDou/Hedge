import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// CLI 共享加密配置文件读取服务
/// 与 Desktop App 共享加密配置，用于读取 Desktop App 写入的配置
class SharedConfigReader {
  /// CLI 共享加密配置文件路径
  static String get _configPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.hedge/shared-config.enc';
  }

  /// 派生解密密钥
  /// HMAC-SHA256(hostname:username, 'hedge-shared-config-v1')
  static Uint8List _deriveKey() {
    final hostname = _getHostname();
    final username = _getUsername();
    final saltBytes = utf8.encode('hedge-shared-config-v1');
    final inputBytes = utf8.encode('$hostname:$username');
    final hmac = Hmac(sha256, saltBytes);
    final digest = hmac.convert(inputBytes);
    return Uint8List.fromList(digest.bytes);
  }

  static String _getHostname() {
    try {
      final result = Process.runSync('hostname', []);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return Platform.localHostname;
  }

  static String _getUsername() {
    return Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        'unknown';
  }

  /// 解密数据
  static Uint8List? _decrypt(Uint8List encryptedData, Uint8List key) {
    try {
      final iv = encrypt.IV(encryptedData.sublist(0, 12));
      final ciphertext = encryptedData.sublist(12);
      final cipher = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm, padding: null);
      final encrypter = encrypt.Encrypter(cipher);
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return null;
    }
  }

  /// 从 CLI 共享加密文件读取 WebDAV 配置
  static Future<Map<String, String>?> readWebdavConfig() async {
    try {
      final file = File(_configPath);
      if (!await file.exists()) return null;

      final encrypted = await file.readAsBytes();
      final key = _deriveKey();
      final decrypted = _decrypt(Uint8List.fromList(encrypted), key);
      if (decrypted == null) return null;

      final jsonStr = utf8.decode(decrypted);
      final config = jsonDecode(jsonStr) as Map<String, dynamic>;
      return config.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }
}
