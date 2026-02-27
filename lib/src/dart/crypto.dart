import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryptography/cryptography.dart' as crypto;

class CryptoService {
  static final _algorithm = crypto.Pbkdf2(
    macAlgorithm: crypto.Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final secretKey = await _algorithm.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  static Uint8List _encryptData(Uint8List data, Uint8List key) {
    final cipher = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm, padding: null);
    final encrypter = encrypt.Encrypter(cipher);
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    final result = Uint8List(12 + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(12, encrypted.bytes);
    return result;
  }

  static Uint8List _decryptData(Uint8List encryptedData, Uint8List key) {
    final iv = encrypt.IV(encryptedData.sublist(0, 12));
    final ciphertext = encryptedData.sublist(12);
    final cipher = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm, padding: null);
    final encrypter = encrypt.Encrypter(cipher);
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<Uint8List> encryptJson(Map<String, dynamic> json, String password, Uint8List salt) async {
    final key = await _deriveKey(password, salt);
    final data = utf8.encode(jsonEncode(json));
    final encrypted = _encryptData(Uint8List.fromList(data), key);
    
    final result = Uint8List(16 + encrypted.length);
    result.setAll(0, salt);
    result.setAll(16, encrypted);
    return result;
  }

  static Future<Map<String, dynamic>?> decryptJson(Uint8List encryptedData, String password) async {
    try {
      final salt = encryptedData.sublist(0, 16);
      final ciphertext = encryptedData.sublist(16);
      final key = await _deriveKey(password, salt);
      final decrypted = _decryptData(ciphertext, key);
      return jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
