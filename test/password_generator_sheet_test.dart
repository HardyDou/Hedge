import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/presentation/providers/password_generator_provider.dart';
import 'package:hedge/domain/models/password_generator_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PasswordGeneratorProvider 集成测试', () {
    test('初始化时生成默认密码', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(passwordGeneratorProvider.future);

      expect(state.generatedPassword, isNotEmpty);
      expect(state.generatedPassword.length, equals(16));
      expect(state.config.length, equals(16));
      expect(state.config.includeNumbers, isTrue);
      expect(state.config.includeSymbols, isTrue);
    });

    test('更新配置后重新生成密码', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialState = await container.read(passwordGeneratorProvider.future);
      final initialPassword = initialState.generatedPassword;

      final newConfig = initialState.config.copyWith(length: 20);
      container.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);

      await Future.delayed(const Duration(milliseconds: 100));

      final updatedState = await container.read(passwordGeneratorProvider.future);

      expect(updatedState.generatedPassword.length, equals(20));
      expect(updatedState.generatedPassword, isNot(equals(initialPassword)));
    });

    test('重新生成密码', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialState = await container.read(passwordGeneratorProvider.future);
      final initialPassword = initialState.generatedPassword;

      container.read(passwordGeneratorProvider.notifier).regenerate();

      await Future.delayed(const Duration(milliseconds: 100));

      final updatedState = await container.read(passwordGeneratorProvider.future);

      expect(updatedState.generatedPassword, isNot(equals(initialPassword)));
      expect(updatedState.generatedPassword.length, equals(initialState.config.length));
    });

    test('配置持久化', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(passwordGeneratorProvider.future);

      final newConfig = PasswordGeneratorConfig(
        length: 24,
        includeNumbers: false,
        includeSymbols: true,
        excludeAmbiguous: true,
      );
      container.read(passwordGeneratorProvider.notifier).updateConfig(newConfig);

      await Future.delayed(const Duration(milliseconds: 100));

      final updatedState = await container.read(passwordGeneratorProvider.future);

      expect(updatedState.config.length, equals(24));
      expect(updatedState.config.includeNumbers, isFalse);
      expect(updatedState.config.includeSymbols, isTrue);
      expect(updatedState.config.excludeAmbiguous, isTrue);
    });

    test('密码强度计算', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(passwordGeneratorProvider.future);

      expect(state.strength, isNotNull);
      expect(state.strength.score, greaterThan(0));
      expect(state.strength.progress, greaterThan(0.0));
      expect(state.strength.progress, lessThanOrEqualTo(1.0));
    });
  });
}
