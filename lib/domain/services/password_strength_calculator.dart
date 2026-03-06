import 'dart:math';
import '../models/password_strength.dart';

/// 密码强度计算器
class PasswordStrengthCalculator {
  /// 计算密码强度
  static PasswordStrength calculate(String password) {
    int score = 0;

    // 1. 长度评分（最多40分）
    score += min(password.length * 2, 40);

    // 2. 字符类型多样性（最多30分）
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 5;
    if (password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) score += 15;

    // 3. 熵值评分（最多30分）
    final entropy = _calculateEntropy(password);
    score += min((entropy / 4).round(), 30);

    // 确保分数在 0-100 范围内
    score = score.clamp(0, 100);

    // 确定等级
    final level = _getLevel(score);

    // 生成建议
    final suggestion = _generateSuggestion(password, score);

    return PasswordStrength(
      score: score,
      level: level,
      suggestion: suggestion,
    );
  }

  /// 计算熵值
  static double _calculateEntropy(String password) {
    final charSet = password.split('').toSet().length;
    if (charSet == 0) return 0;
    return password.length * (log(charSet) / log(2));
  }

  /// 根据分数确定等级
  static StrengthLevel _getLevel(int score) {
    if (score < 25) return StrengthLevel.weak;
    if (score < 50) return StrengthLevel.medium;
    if (score < 75) return StrengthLevel.strong;
    return StrengthLevel.veryStrong;
  }

  /// 生成改进建议
  static String _generateSuggestion(String password, int score) {
    if (password.length < 12) return '建议增加长度至12位以上';
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      return '建议添加特殊符号';
    }
    if (score < 50) return '建议使用更多字符类型';
    return '密码强度良好';
  }
}
