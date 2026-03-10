import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/models/password_strength.dart';

/// 密码生成器专用的密码显示组件
/// 特点：默认显示明文，右侧显示强度色块+刷新按钮
class PasswordGeneratorDisplay extends StatelessWidget {
  final String password;
  final PasswordStrength strength;
  final VoidCallback? onRegenerate;

  const PasswordGeneratorDisplay({
    super.key,
    required this.password,
    required this.strength,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 密码文本（始终显示明文）
          Expanded(
            child: Text(
              password,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                height: 1.4,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),

          // 强度色块
          _buildStrengthBadge(context),

          const SizedBox(width: 8),

          // 刷新按钮
          Semantics(
            label: l10n.regenerate,
            button: true,
            hint: 'Generate a new password',
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              minSize: 36,
              onPressed: () {
                HapticFeedback.lightImpact();
                if (onRegenerate != null) {
                  onRegenerate!();
                }
              },
              child: Icon(
                CupertinoIcons.arrow_clockwise,
                size: 20,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建强度色块（1个汉字）
  Widget _buildStrengthBadge(BuildContext context) {
    String label;
    switch (strength.level) {
      case StrengthLevel.weak:
        label = '低';
        break;
      case StrengthLevel.medium:
        label = '中';
        break;
      case StrengthLevel.strong:
        label = '高';
        break;
      case StrengthLevel.veryStrong:
        label = '强';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strength.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}
