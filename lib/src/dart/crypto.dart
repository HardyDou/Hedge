import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';

class _DeriveKeyParams {
  final String password;
  final Uint8List salt;
  _DeriveKeyParams({required this.password, required this.salt});
}

class _EncryptParams {
  final Uint8List data;
  final Uint8List key;
  _EncryptParams({required this.data, required this.key});
}

class _DecryptParams {
  final Uint8List encryptedData;
  final Uint8List key;
  _DecryptParams({required this.encryptedData, required this.key});
}

Future<Uint8List> _deriveKeyIsolate(_DeriveKeyParams params) async {
  final algorithm = crypto.Pbkdf2(
    macAlgorithm: crypto.Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  final secretKey = await algorithm.deriveKey(
    secretKey: crypto.SecretKey(utf8.encode(params.password)),
    nonce: params.salt,
  );
  return Uint8List.fromList(await secretKey.extractBytes());
}

Uint8List _encryptDataIsolate(_EncryptParams params) {
  final cipher = encrypt.AES(encrypt.Key(params.key), mode: encrypt.AESMode.gcm, padding: null);
  final encrypter = encrypt.Encrypter(cipher);
  final iv = encrypt.IV.fromSecureRandom(12);
  final encrypted = encrypter.encryptBytes(params.data, iv: iv);
  
  final result = Uint8List(12 + encrypted.bytes.length);
  result.setAll(0, iv.bytes);
  result.setAll(12, encrypted.bytes);
  return result;
}

Uint8List _decryptDataIsolate(_DecryptParams params) {
  final iv = encrypt.IV(params.encryptedData.sublist(0, 12));
  final ciphertext = params.encryptedData.sublist(12);
  final cipher = encrypt.AES(encrypt.Key(params.key), mode: encrypt.AESMode.gcm, padding: null);
  final encrypter = encrypt.Encrypter(cipher);
  final decrypted = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
  return Uint8List.fromList(decrypted);
}

class CryptoService {
  static Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    return compute(_deriveKeyIsolate, _DeriveKeyParams(password: password, salt: salt));
  }

  static Future<Uint8List> _encryptData(Uint8List data, Uint8List key) async {
    return compute(_encryptDataIsolate, _EncryptParams(data: data, key: key));
  }

  static Future<Uint8List> _decryptData(Uint8List encryptedData, Uint8List key) async {
    return compute(_decryptDataIsolate, _DecryptParams(encryptedData: encryptedData, key: key));
  }

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<Uint8List> encryptJson(Map<String, dynamic> json, String password, Uint8List salt) async {
    final key = await _deriveKey(password, salt);
    final data = utf8.encode(jsonEncode(json));
    final encrypted = await _encryptData(Uint8List.fromList(data), key);
    
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
      final decrypted = await _decryptData(ciphertext, key);
      return jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
