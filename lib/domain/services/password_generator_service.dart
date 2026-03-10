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
    final letterCharset = _buildLetterCharset(config.excludeAmbiguous);
    final numberCharset = _buildNumberCharset(config.excludeAmbiguous);
    final symbolCharset = _symbols;

    // 1. 保证字符：开关开启时各放入至少 1 个
    final List<String> guaranteed = [];
    if (config.includeNumbers) {
      guaranteed.add(numberCharset[_random.nextInt(numberCharset.length)]);
    }
    if (config.includeSymbols) {
      guaranteed.add(symbolCharset[_random.nextInt(symbolCharset.length)]);
    }

    // 2. 构建完整字符集（字母始终包含）
    String fullCharset = letterCharset;
    if (config.includeNumbers) fullCharset += numberCharset;
    if (config.includeSymbols) fullCharset += symbolCharset;

    // 3. 剩余位置从完整字符集随机填充
    final remaining = config.length - guaranteed.length;
    for (int i = 0; i < remaining; i++) {
      guaranteed.add(fullCharset[_random.nextInt(fullCharset.length)]);
    }

    // 4. 打乱顺序
    guaranteed.shuffle(_random);

    return guaranteed.join();
  }

  /// 构建字母字符集（大写+小写）
  static String _buildLetterCharset(bool excludeAmbiguous) {
    String charset = _uppercase + _lowercase;

    if (excludeAmbiguous) {
      charset = charset.split('').where((char) => !_ambiguousChars.contains(char)).join();
    }

    return charset;
  }

  /// 构建数字字符集
  static String _buildNumberCharset(bool excludeAmbiguous) {
    String charset = _numbers;

    if (excludeAmbiguous) {
      charset = charset.split('').where((char) => !_ambiguousChars.contains(char)).join();
    }

    return charset;
  }
}
