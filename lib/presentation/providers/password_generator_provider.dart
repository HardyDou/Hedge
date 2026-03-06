import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/password_generator_config.dart';
import '../../domain/models/password_strength.dart';
import '../../domain/services/password_generator_service.dart';
import '../../domain/services/password_strength_calculator.dart';
import '../../domain/services/password_generator_config_service.dart';

part 'password_generator_provider.g.dart';

/// 密码生成器状态
class PasswordGeneratorState {
  final PasswordGeneratorConfig config;
  final String generatedPassword;
  final PasswordStrength strength;

  const PasswordGeneratorState({
    required this.config,
    required this.generatedPassword,
    required this.strength,
  });

  PasswordGeneratorState copyWith({
    PasswordGeneratorConfig? config,
    String? generatedPassword,
    PasswordStrength? strength,
  }) {
    return PasswordGeneratorState(
      config: config ?? this.config,
      generatedPassword: generatedPassword ?? this.generatedPassword,
      strength: strength ?? this.strength,
    );
  }
}

/// 密码生成器 Provider
@riverpod
class PasswordGenerator extends _$PasswordGenerator {
  @override
  Future<PasswordGeneratorState> build() async {
    // 从本地存储加载用户偏好配置
    final config = await PasswordGeneratorConfigService.loadConfig();
    final password = PasswordGeneratorService.generate(config);
    final strength = PasswordStrengthCalculator.calculate(password);

    return PasswordGeneratorState(
      config: config,
      generatedPassword: password,
      strength: strength,
    );
  }

  /// 更新配置并重新生成
  Future<void> updateConfig(PasswordGeneratorConfig config) async {
    final currentState = state.value;
    if (currentState == null) return;

    // 保存配置到本地
    await PasswordGeneratorConfigService.saveConfig(config);

    // 重新生成密码
    final password = PasswordGeneratorService.generate(config);
    final strength = PasswordStrengthCalculator.calculate(password);

    state = AsyncValue.data(
      currentState.copyWith(
        config: config,
        generatedPassword: password,
        strength: strength,
      ),
    );
  }

  /// 重新生成密码
  void regenerate() {
    final currentState = state.value;
    if (currentState == null) return;

    final password = PasswordGeneratorService.generate(currentState.config);
    final strength = PasswordStrengthCalculator.calculate(password);

    state = AsyncValue.data(
      currentState.copyWith(
        generatedPassword: password,
        strength: strength,
      ),
    );
  }

  /// 复制到剪贴板
  Future<void> copyToClipboard() async {
    final currentState = state.value;
    if (currentState == null) return;

    await Clipboard.setData(ClipboardData(text: currentState.generatedPassword));
  }
}
