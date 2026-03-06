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
    // 验证配置
    final totalRequired = config.numbersCount + config.symbolsCount;
    if (totalRequired > config.length) {
      throw ArgumentError('数字和符号的总数量不能超过密码长度');
    }

    // 构建字符集
    final letterCharset = _buildLetterCharset(config.excludeAmbiguous);
    final numberCharset = _buildNumberCharset(config.excludeAmbiguous);
    final symbolCharset = _symbols;

    if (letterCharset.isEmpty) {
      throw ArgumentError('字母字符集不能为空');
    }

    final List<String> allChars = [];

    // 1. 添加指定数量的数字
    for (int i = 0; i < config.numbersCount; i++) {
      allChars.add(numberCharset[_random.nextInt(numberCharset.length)]);
    }

    // 2. 添加指定数量的符号
    for (int i = 0; i < config.symbolsCount; i++) {
      allChars.add(symbolCharset[_random.nextInt(symbolCharset.length)]);
    }

    // 3. 剩余位置用字母填充
    final int letterCount = config.length - totalRequired;
    for (int i = 0; i < letterCount; i++) {
      allChars.add(letterCharset[_random.nextInt(letterCharset.length)]);
    }

    // 4. 打乱顺序
    allChars.shuffle(_random);

    return allChars.join();
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
