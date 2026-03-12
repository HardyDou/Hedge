// CLI 兼容版加密模块（无 Flutter 依赖）
// 与主应用 lib/src/dart/crypto.dart 保持算法一致
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:crypto/crypto.dart' as dart_crypto;

class CliCryptoService {
  /// 使用 PBKDF2-HMAC-SHA256 派生密钥（与主应用一致）
  static Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    final algorithm = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await algorithm.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  /// 解密 vault 文件（格式：[16字节salt][12字节IV][ciphertext+tag]）
  static Future<Map<String, dynamic>?> decryptJson(
      Uint8List encryptedData, String password) async {
    try {
      final salt = encryptedData.sublist(0, 16);
      final ciphertext = encryptedData.sublist(16);
      final key = await deriveKey(password, salt);
      final decrypted = _decryptAesGcm(ciphertext, key);
      return jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Uint8List _decryptAesGcm(Uint8List encryptedData, Uint8List key) {
    final iv = enc.IV(encryptedData.sublist(0, 12));
    final ciphertext = encryptedData.sublist(12);
    final cipher = enc.AES(enc.Key(key), mode: enc.AESMode.gcm, padding: null);
    final encrypter = enc.Encrypter(cipher);
    final decrypted =
        encrypter.decryptBytes(enc.Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  static Uint8List _encryptAesGcm(Uint8List data, Uint8List key) {
    final cipher = enc.AES(enc.Key(key), mode: enc.AESMode.gcm, padding: null);
    final encrypter = enc.Encrypter(cipher);
    final iv = enc.IV.fromSecureRandom(12);
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    final result = Uint8List(12 + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(12, encrypted.bytes);
    return result;
  }

  /// 派生会话令牌存储密钥
  /// HMAC-SHA256(hostname:username, 'hedge-cli-session-v1')
  static Uint8List deriveSessionKey() {
    final hostname = _getHostname();
    final username = _getUsername();
    final saltBytes = utf8.encode('hedge-cli-session-v1');
    final inputBytes = utf8.encode('$hostname:$username');
    final hmac = dart_crypto.Hmac(dart_crypto.sha256, saltBytes);
    final digest = hmac.convert(inputBytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// 加密字符串（用于会话令牌存储）
  static Uint8List encryptString(String plaintext, Uint8List key) {
    final data = utf8.encode(plaintext);
    return _encryptAesGcm(Uint8List.fromList(data), key);
  }

  /// 解密字符串（用于会话令牌存储）
  static String? decryptString(Uint8List encrypted, Uint8List key) {
    try {
      final decrypted = _decryptAesGcm(encrypted, key);
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
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
}
