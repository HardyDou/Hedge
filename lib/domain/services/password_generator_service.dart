import 'dart:math';
import '../models/password_generator_config.dart';

/// 密码生成器服务
class PasswordGeneratorService {
  // 字符集定义
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // 易混淆字符
  static const String _ambiguousChars = '0O1lI';

  static final Random _random = Random.secure();

  /// 生成密码
  static String generate(PasswordGeneratorConfig config) {
    // 1. 构建字符集
    String charset = _buildCharset(config);

    if (charset.isEmpty) {
      throw ArgumentError('至少需要选择一种字符类型');
    }

    // 2. 确保至少包含每种选中的字符类型
    final List<String> requiredChars = _getRequiredChars(config);

    // 3. 生成剩余的随机字符
    final int remainingLength = config.length - requiredChars.length;
    if (remainingLength < 0) {
      throw ArgumentError('密码长度不足以包含所有必需的字符类型');
    }

    final List<String> allChars = List.from(requiredChars);
    for (int i = 0; i < remainingLength; i++) {
      allChars.add(charset[_random.nextInt(charset.length)]);
    }

    // 4. 打乱顺序
    allChars.shuffle(_random);

    return allChars.join();
  }

  /// 构建字符集
  static String _buildCharset(PasswordGeneratorConfig config) {
    String charset = '';

    if (config.includeUppercase) {
      charset += _uppercase;
    }
    if (config.includeLowercase) {
      charset += _lowercase;
    }
    if (config.includeNumbers) {
      charset += _numbers;
    }
    if (config.includeSymbols) {
      charset += _symbols;
    }

    // 排除易混淆字符
    if (config.excludeAmbiguous) {
      charset = charset.split('').where((char) => !_ambiguousChars.contains(char)).join();
    }

    return charset;
  }

  /// 获取必需的字符（确保每种类型至少有一个）
  static List<String> _getRequiredChars(PasswordGeneratorConfig config) {
    final List<String> required = [];

    if (config.includeUppercase) {
      String chars = config.excludeAmbiguous
          ? _uppercase.split('').where((c) => !_ambiguousChars.contains(c)).join()
          : _uppercase;
      required.add(chars[_random.nextInt(chars.length)]);
    }

    if (config.includeLowercase) {
      String chars = config.excludeAmbiguous
          ? _lowercase.split('').where((c) => !_ambiguousChars.contains(c)).join()
          : _lowercase;
      required.add(chars[_random.nextInt(chars.length)]);
    }

    if (config.includeNumbers) {
      String chars = config.excludeAmbiguous
          ? _numbers.split('').where((c) => !_ambiguousChars.contains(c)).join()
          : _numbers;
      required.add(chars[_random.nextInt(chars.length)]);
    }

    if (config.includeSymbols) {
      required.add(_symbols[_random.nextInt(_symbols.length)]);
    }

    return required;
  }
}
