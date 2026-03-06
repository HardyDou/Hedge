import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/domain/models/password_strength.dart';
import 'package:hedge/domain/services/password_strength_calculator.dart';

void main() {
  group('PasswordStrengthCalculator', () {
    test('弱密码 - 短且简单', () {
      final strength = PasswordStrengthCalculator.calculate('abc123');

      expect(strength.score, lessThan(50));
    });

    test('中等密码 - 中等长度和复杂度', () {
      final strength = PasswordStrengthCalculator.calculate('Abc12345');

      expect(strength.level, equals(StrengthLevel.medium));
      expect(strength.score, greaterThanOrEqualTo(25));
      expect(strength.score, lessThan(50));
    });

    test('强密码 - 较长且包含多种字符', () {
      final strength = PasswordStrengthCalculator.calculate('Abc123456789');

      expect(strength.level, equals(StrengthLevel.strong));
      expect(strength.score, greaterThanOrEqualTo(50));
      expect(strength.score, lessThan(75));
    });

    test('极强密码 - 长且包含所有字符类型', () {
      final strength = PasswordStrengthCalculator.calculate('Abc123!@#XyzPqr456');

      expect(strength.level, equals(StrengthLevel.veryStrong));
      expect(strength.score, greaterThanOrEqualTo(75));
    });

    test('空密码应该得分为0', () {
      final strength = PasswordStrengthCalculator.calculate('');

      expect(strength.score, equals(0));
      expect(strength.level, equals(StrengthLevel.weak));
    });

    test('仅数字密码强度较低', () {
      final strength = PasswordStrengthCalculator.calculate('123456789012');

      expect(strength.level, isIn([StrengthLevel.weak, StrengthLevel.medium]));
    });

    test('包含大写字母增加强度', () {
      final strengthLower = PasswordStrengthCalculator.calculate('abcdefgh');
      final strengthMixed = PasswordStrengthCalculator.calculate('Abcdefgh');

      expect(strengthMixed.score, greaterThan(strengthLower.score));
    });

    test('包含数字增加强度', () {
      final strengthNoNum = PasswordStrengthCalculator.calculate('abcdefgh');
      final strengthWithNum = PasswordStrengthCalculator.calculate('abcdef12');

      expect(strengthWithNum.score, greaterThan(strengthNoNum.score));
    });

    test('包含符号增加强度', () {
      final strengthNoSymbol = PasswordStrengthCalculator.calculate('Abcdef12');
      final strengthWithSymbol = PasswordStrengthCalculator.calculate('Abcd12!@');

      expect(strengthWithSymbol.score, greaterThan(strengthNoSymbol.score));
    });

    test('长度增加提高强度', () {
      final strength8 = PasswordStrengthCalculator.calculate('Abc123!@');
      final strength16 = PasswordStrengthCalculator.calculate('Abc123!@Xyz456#\$');

      expect(strength16.score, greaterThan(strength8.score));
    });

    test('建议短密码增加长度', () {
      final strength = PasswordStrengthCalculator.calculate('Abc1!');

      expect(strength.suggestion, contains('长度'));
    });

    test('建议无符号密码添加符号', () {
      final strength = PasswordStrengthCalculator.calculate('Abcdefgh1234');

      expect(strength.suggestion, contains('符号'));
    });

    test('强密码应该有良好建议', () {
      final strength = PasswordStrengthCalculator.calculate('Abc123!@#XyzPqr456');

      expect(strength.suggestion, contains('良好'));
    });

    test('分数应该在0-100范围内', () {
      final passwords = [
        '',
        'a',
        'abc',
        'Abc123',
        'Abc123!@#',
        'Abc123!@#XyzPqr456\$%^&*()',
      ];

      for (final password in passwords) {
        final strength = PasswordStrengthCalculator.calculate(password);
        expect(strength.score, greaterThanOrEqualTo(0));
        expect(strength.score, lessThanOrEqualTo(100));
      }
    });

    test('进度值应该在0.0-1.0范围内', () {
      final passwords = [
        '',
        'abc',
        'Abc123',
        'Abc123!@#XyzPqr456',
      ];

      for (final password in passwords) {
        final strength = PasswordStrengthCalculator.calculate(password);
        expect(strength.progress, greaterThanOrEqualTo(0.0));
        expect(strength.progress, lessThanOrEqualTo(1.0));
      }
    });
  });
}
