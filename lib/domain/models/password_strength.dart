import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_strength.freezed.dart';

/// 密码强度等级
enum StrengthLevel {
  /// 弱 (0-25)
  weak,

  /// 中 (25-50)
  medium,

  /// 强 (50-75)
  strong,

  /// 极强 (75-100)
  veryStrong,
}

/// 密码强度
@freezed
class PasswordStrength with _$PasswordStrength {
  const PasswordStrength._();

  const factory PasswordStrength({
    /// 强度分数 (0-100)
    required int score,

    /// 强度等级
    required StrengthLevel level,

    /// 改进建议
    required String suggestion,
  }) = _PasswordStrength;

  /// 获取强度等级对应的颜色
  Color get color {
    switch (level) {
      case StrengthLevel.weak:
        return CupertinoColors.systemRed;
      case StrengthLevel.medium:
        return CupertinoColors.systemOrange;
      case StrengthLevel.strong:
        return CupertinoColors.systemYellow;
      case StrengthLevel.veryStrong:
        return CupertinoColors.systemGreen;
    }
  }

  /// 获取强度等级的进度值 (0.0-1.0)
  double get progress => score / 100.0;
}
