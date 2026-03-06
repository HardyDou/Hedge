import 'dart:async';
import 'package:otp/otp.dart';

/// TOTP 服务
/// 负责生成基于时间的一次性密码（TOTP）
class TotpService {
  /// 生成 TOTP 验证码
  ///
  /// [secret]: Base32 编码的 Secret Key
  /// [time]: 可选的时间戳（默认使用当前时间）
  /// 返回 6 位数字验证码
  static String generateTotp(String secret, {DateTime? time}) {
    try {
      final timestamp = time ?? DateTime.now();
      final code = OTP.generateTOTPCodeString(
        secret,
        timestamp.millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return code;
    } catch (e) {
      throw TotpException('生成 TOTP 失败: $e');
    }
  }

  /// 获取当前 TOTP 周期的剩余秒数
  ///
  /// 返回 0-29 之间的整数，表示当前验证码还有多少秒过期
  static int getRemainingSeconds({DateTime? time}) {
    final timestamp = time ?? DateTime.now();
    final seconds = timestamp.second;
    return 30 - (seconds % 30);
  }

  /// 获取当前 TOTP 周期的进度（0.0 - 1.0）
  ///
  /// 用于显示进度条
  static double getProgress({DateTime? time}) {
    final remaining = getRemainingSeconds(time: time);
    return remaining / 30.0;
  }

  /// 验证 Secret Key 格式是否正确
  ///
  /// Secret Key 应为 Base32 编码的字符串
  static bool isValidSecret(String secret) {
    if (secret.isEmpty) return false;

    // 移除空格和连字符
    final cleaned = secret.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

    // Base32 字符集：A-Z 和 2-7
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    if (!base32Regex.hasMatch(cleaned)) return false;

    // 长度应为 16-32 个字符（不包括填充符）
    final lengthWithoutPadding = cleaned.replaceAll('=', '').length;
    return lengthWithoutPadding >= 16 && lengthWithoutPadding <= 32;
  }

  /// 清理 Secret Key（移除空格和连字符，转换为大写）
  static String cleanSecret(String secret) {
    return secret.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  }

  /// 格式化 TOTP 验证码（添加空格分隔）
  ///
  /// 例如：123456 -> 123 456
  static String formatCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }

  /// 解析 otpauth:// URI
  ///
  /// 格式：otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
  /// 返回 Map，包含 secret 和 issuer
  static Map<String, String>? parseOtpauthUri(String uri) {
    try {
      if (!uri.startsWith('otpauth://totp/')) return null;

      final parsedUri = Uri.parse(uri);
      final secret = parsedUri.queryParameters['secret'];
      final issuer = parsedUri.queryParameters['issuer'];

      if (secret == null || secret.isEmpty) return null;

      return {
        'secret': cleanSecret(secret),
        if (issuer != null && issuer.isNotEmpty) 'issuer': issuer,
      };
    } catch (e) {
      return null;
    }
  }
}

/// TOTP 异常
class TotpException implements Exception {
  final String message;
  TotpException(this.message);

  @override
  String toString() => 'TotpException: $message';
}
