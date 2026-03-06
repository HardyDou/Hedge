import 'package:flutter/cupertino.dart';
import '../../domain/models/password_strength.dart';
import '../../l10n/generated/app_localizations.dart';

/// 密码强度指示条组件
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final bool showLabel;
  final bool showSuggestion;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.showLabel = true,
    this.showSuggestion = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 强度指示条
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      // 背景
                      Container(
                        color: CupertinoColors.systemGrey5,
                      ),
                      // 进度条
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: strength.progress,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: strength.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 12),
              Text(
                _getLevelText(l10n, strength.level),
                style: TextStyle(
                  fontSize: 14,
                  color: strength.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        // 改进建议
        if (showSuggestion && strength.suggestion.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            strength.suggestion,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ],
    );
  }

  String _getLevelText(AppLocalizations l10n, StrengthLevel level) {
    switch (level) {
      case StrengthLevel.weak:
        return l10n.strengthWeak;
      case StrengthLevel.medium:
        return l10n.strengthMedium;
      case StrengthLevel.strong:
        return l10n.strengthStrong;
      case StrengthLevel.veryStrong:
        return l10n.strengthVeryStrong;
    }
  }
}
