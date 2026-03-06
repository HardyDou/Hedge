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

    test('生成仅包含大写字母的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        includeUppercase: true,
        includeLowercase: false,
        includeNumbers: false,
        includeSymbols: false,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'^[A-Z]+$').hasMatch(password), isTrue);
    });

    test('生成仅包含小写字母的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        includeUppercase: false,
        includeLowercase: true,
        includeNumbers: false,
        includeSymbols: false,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'^[a-z]+$').hasMatch(password), isTrue);
    });

    test('生成仅包含数字的密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        includeUppercase: false,
        includeLowercase: false,
        includeNumbers: true,
        includeSymbols: false,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'^[0-9]+$').hasMatch(password), isTrue);
    });

    test('生成包含所有字符类型的密码', () {
      final config = PasswordGeneratorConfig.defaultConfig();
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'[A-Z]').hasMatch(password), isTrue);
      expect(RegExp(r'[a-z]').hasMatch(password), isTrue);
      expect(RegExp(r'[0-9]').hasMatch(password), isTrue);
      expect(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password), isTrue);
    });

    test('排除易混淆字符', () {
      final config = PasswordGeneratorConfig.defaultConfig().copyWith(
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
      final config = PasswordGeneratorConfig.defaultConfig().copyWith(length: 8);
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(8));
    });

    test('生成最大长度密码', () {
      final config = PasswordGeneratorConfig.defaultConfig().copyWith(length: 64);
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(64));
    });

    test('未选择任何字符类型时抛出异常', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        includeUppercase: false,
        includeLowercase: false,
        includeNumbers: false,
        includeSymbols: false,
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
  });
}
