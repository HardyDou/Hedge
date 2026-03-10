import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/models/password_strength.dart';

/// 密码生成器专用的密码显示组件
/// 明文显示 + 强度进度条 + 刷新/复制操作
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
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：密码文本 + 强度进度条
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  password,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    height: 1.35,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _buildStrengthRow(context),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 右侧：操作按钮列
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: l10n.regenerate,
                button: true,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minSize: 40,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onRegenerate?.call();
                  },
                  child: Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 20,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                ),
              ),
              Semantics(
                label: l10n.copy,
                button: true,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minSize: 40,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: password));
                  },
                  child: Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 18,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthRow(BuildContext context) {
    final label = _strengthLabel();
    final color = strength.color;

    return Row(
      children: [
        // 进度条
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  // 背景轨道
                  Container(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                  ),
                  // 填充进度
                  FractionallySizedBox(
                    widthFactor: strength.progress,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 强度文字标签
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _strengthLabel() {
    switch (strength.level) {
      case StrengthLevel.weak:
        return '弱';
      case StrengthLevel.medium:
        return '一般';
      case StrengthLevel.strong:
        return '强';
      case StrengthLevel.veryStrong:
        return '极强';
    }
  }
}
