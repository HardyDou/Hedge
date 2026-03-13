import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 共享的安全存储配置
/// 用于 Desktop App 和 CLI 之间共享敏感配置（如 WebDAV）
const sharedSecureStorage = FlutterSecureStorage(
  // macOS: 写入用户登录 Keychain（可被 CLI 访问）
  // 需要在 entitlements 文件中添加 keychain-access-groups
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
  // Linux: 使用默认的 secret-service
  lOptions: LinuxOptions(),
  // Windows: 使用默认的凭据管理器
  wOptions: WindowsOptions(),
);

/// 兼容旧版本的存储（App Sandbox，仅 Desktop App 使用）
const appSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);

/// CLI 共享加密配置文件路径
String get cliSharedConfigPath {
  final home = Platform.environment['HOME'] ?? '/Users/hardy';
  return '$home/.hedge/shared-config.enc';
}

/// 派生加密密钥
/// HMAC-SHA256(hostname:username, 'hedge-shared-config-v1')
Uint8List _deriveKey() {
  final hostname = Platform.localHostname;
  final username = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown';
  final saltBytes = utf8.encode('hedge-shared-config-v1');
  final inputBytes = utf8.encode('$hostname:$username');
  final hmac = Hmac(sha256, saltBytes);
  final digest = hmac.convert(inputBytes);
  return Uint8List.fromList(digest.bytes);
}

/// 加密数据
Uint8List _encrypt(Uint8List data, Uint8List key) {
  final cipher = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm, padding: null);
  final encrypter = encrypt.Encrypter(cipher);
  final iv = encrypt.IV.fromSecureRandom(12);
  final encrypted = encrypter.encryptBytes(data, iv: iv);
  final result = Uint8List(12 + encrypted.bytes.length);
  result.setAll(0, iv.bytes);
  result.setAll(12, encrypted.bytes);
  return result;
}

/// 解密数据
Uint8List? _decrypt(Uint8List encryptedData, Uint8List key) {
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

/// 保存 WebDAV 配置到 CLI 共享加密文件
/// Desktop App 调用此方法后，CLI 可直接读取
Future<void> saveWebdavConfigForCli(Map<String, String> config) async {
  try {
    final file = File(cliSharedConfigPath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final jsonData = utf8.encode(jsonEncode(config));
    final key = _deriveKey();
    final encrypted = _encrypt(Uint8List.fromList(jsonData), key);

    await file.writeAsBytes(encrypted);
    // 设置权限 0600
    await Process.run('chmod', ['600', cliSharedConfigPath]);
  } catch (e) {
    // 静默失败
  }
}

/// 从 CLI 共享加密文件读取 WebDAV 配置
Future<Map<String, String>?> loadWebdavConfigFromCliFile() async {
  try {
    final file = File(cliSharedConfigPath);
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
