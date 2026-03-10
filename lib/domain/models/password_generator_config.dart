import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_generator_config.freezed.dart';
part 'password_generator_config.g.dart';

/// 密码生成器配置
@freezed
class PasswordGeneratorConfig with _$PasswordGeneratorConfig {
  const factory PasswordGeneratorConfig({
    /// 密码长度 (8-64)
    required int length,

    /// 是否包含数字
    @Default(true) bool includeNumbers,

    /// 是否包含符号
    @Default(true) bool includeSymbols,

    /// 排除易混淆字符 (0/O, 1/l/I)
    @Default(false) bool excludeAmbiguous,
  }) = _PasswordGeneratorConfig;

  /// 默认配置
  factory PasswordGeneratorConfig.defaultConfig() => const PasswordGeneratorConfig(
        length: 16,
        includeNumbers: true,
        includeSymbols: true,
        excludeAmbiguous: false,
      );

  /// 从 JSON 反序列化
  factory PasswordGeneratorConfig.fromJson(Map<String, dynamic> json) =>
      _$PasswordGeneratorConfigFromJson(json);
}
