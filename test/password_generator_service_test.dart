import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/domain/models/password_generator_config.dart';
import 'package:hedge/domain/services/password_generator_service.dart';

void main() {
  group('PasswordGeneratorService', () {
    test('生成默认配置的密码', () {
      final config = PasswordGeneratorConfig.defaultConfig();
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(password, isNotEmpty);
    });

    test('生成指定长度的密码', () {
      final config = PasswordGeneratorConfig.defaultConfig().copyWith(length: 20);
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(20));
    });

    test('生成仅包含字母的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        numbersCount: 0,
        symbolsCount: 0,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'^[A-Za-z]+$').hasMatch(password), isTrue);
    });

    test('生成包含指定数量数字的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        numbersCount: 4,
        symbolsCount: 0,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      final digitCount = password.split('').where((c) => RegExp(r'[0-9]').hasMatch(c)).length;
      expect(digitCount, equals(4));
    });

    test('生成包含指定数量符号的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        numbersCount: 0,
        symbolsCount: 3,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      final symbolCount = password.split('').where((c) => RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(c)).length;
      expect(symbolCount, equals(3));
    });

    test('生成包含数字和符号的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        numbersCount: 2,
        symbolsCount: 2,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'[A-Za-z]').hasMatch(password), isTrue);
      expect(RegExp(r'[0-9]').hasMatch(password), isTrue);
      expect(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password), isTrue);
    });

    test('排除易混淆字符', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        numbersCount: 4,
        symbolsCount: 0,
        excludeAmbiguous: true,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(password.contains('0'), isFalse);
      expect(password.contains('O'), isFalse);
      expect(password.contains('1'), isFalse);
      expect(password.contains('l'), isFalse);
      expect(password.contains('I'), isFalse);
    });

    test('生成最小长度密码', () {
      final config = PasswordGeneratorConfig(
        length: 8,
        numbersCount: 2,
        symbolsCount: 2,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(8));
    });

    test('生成最大长度密码', () {
      final config = PasswordGeneratorConfig(
        length: 64,
        numbersCount: 10,
        symbolsCount: 10,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(64));
    });

    test('数字和符号总数超过密码长度时抛出异常', () {
      final config = PasswordGeneratorConfig(
        length: 10,
        numbersCount: 6,
        symbolsCount: 6,
      );

      expect(
        () => PasswordGeneratorService.generate(config),
        throwsArgumentError,
      );
    });

    test('生成的密码应该是随机的', () {
      final config = PasswordGeneratorConfig.defaultConfig();
      final password1 = PasswordGeneratorService.generate(config);
      final password2 = PasswordGeneratorService.generate(config);

      expect(password1, isNot(equals(password2)));
    });

    test('数字和符号数量为0时生成纯字母密码', () {
      final config = PasswordGeneratorConfig(
        length: 12,
        numbersCount: 0,
        symbolsCount: 0,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(12));
      expect(RegExp(r'^[A-Za-z]+$').hasMatch(password), isTrue);
    });
  });
}
