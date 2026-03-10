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

    test('两个开关均关闭时生成纯字母密码', () {
      final config = PasswordGeneratorConfig(
        length: 16,
        includeNumbers: false,
        includeSymbols: false,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(16));
      expect(RegExp(r'^[A-Za-z]+$').hasMatch(password), isTrue);
    });

    test('开启数字开关时密码包含至少 1 个数字', () {
      // 多次运行以降低随机误判概率
      for (int i = 0; i < 20; i++) {
        final config = PasswordGeneratorConfig(
          length: 16,
          includeNumbers: true,
          includeSymbols: false,
        );
        final password = PasswordGeneratorService.generate(config);

        expect(password.length, equals(16));
        expect(RegExp(r'[0-9]').hasMatch(password), isTrue,
            reason: '密码应包含至少 1 个数字: $password');
      }
    });

    test('开启符号开关时密码包含至少 1 个符号', () {
      for (int i = 0; i < 20; i++) {
        final config = PasswordGeneratorConfig(
          length: 16,
          includeNumbers: false,
          includeSymbols: true,
        );
        final password = PasswordGeneratorService.generate(config);

        expect(password.length, equals(16));
        expect(
          RegExp(r'[!@#$%^&*()\-_+=\[\]{}|;:,.<>?]').hasMatch(password),
          isTrue,
          reason: '密码应包含至少 1 个符号: $password',
        );
      }
    });

    test('两个开关均开启时密码同时包含数字和符号', () {
      for (int i = 0; i < 20; i++) {
        final config = PasswordGeneratorConfig(
          length: 16,
          includeNumbers: true,
          includeSymbols: true,
        );
        final password = PasswordGeneratorService.generate(config);

        expect(password.length, equals(16));
        expect(RegExp(r'[A-Za-z]').hasMatch(password), isTrue);
        expect(RegExp(r'[0-9]').hasMatch(password), isTrue,
            reason: '密码应包含至少 1 个数字: $password');
        expect(
          RegExp(r'[!@#$%^&*()\-_+=\[\]{}|;:,.<>?]').hasMatch(password),
          isTrue,
          reason: '密码应包含至少 1 个符号: $password',
        );
      }
    });

    test('排除易混淆字符', () {
      for (int i = 0; i < 20; i++) {
        final config = PasswordGeneratorConfig(
          length: 16,
          includeNumbers: true,
          includeSymbols: false,
          excludeAmbiguous: true,
        );
        final password = PasswordGeneratorService.generate(config);

        expect(password.length, equals(16));
        expect(password.contains('0'), isFalse);
        expect(password.contains('O'), isFalse);
        expect(password.contains('1'), isFalse);
        expect(password.contains('l'), isFalse);
        expect(password.contains('I'), isFalse);
      }
    });

    test('最小长度（8）时两个开关均开启仍能生成正确密码', () {
      for (int i = 0; i < 20; i++) {
        final config = PasswordGeneratorConfig(
          length: 8,
          includeNumbers: true,
          includeSymbols: true,
        );
        final password = PasswordGeneratorService.generate(config);

        expect(password.length, equals(8));
        expect(RegExp(r'[0-9]').hasMatch(password), isTrue);
        expect(
          RegExp(r'[!@#$%^&*()\-_+=\[\]{}|;:,.<>?]').hasMatch(password),
          isTrue,
        );
      }
    });

    test('生成最大长度密码', () {
      final config = PasswordGeneratorConfig(
        length: 64,
        includeNumbers: true,
        includeSymbols: true,
      );
      final password = PasswordGeneratorService.generate(config);

      expect(password.length, equals(64));
    });

    test('生成的密码应该是随机的', () {
      final config = PasswordGeneratorConfig.defaultConfig();
      final password1 = PasswordGeneratorService.generate(config);
      final password2 = PasswordGeneratorService.generate(config);

      expect(password1, isNot(equals(password2)));
    });
  });
}
