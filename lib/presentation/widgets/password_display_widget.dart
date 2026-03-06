import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';

/// 密码显示区域组件
class PasswordDisplayWidget extends StatefulWidget {
  final String password;
  final VoidCallback? onCopy;
  final bool showCopyButton;
  final bool showVisibilityToggle;

  const PasswordDisplayWidget({
    super.key,
    required this.password,
    this.onCopy,
    this.showCopyButton = true,
    this.showVisibilityToggle = true,
  });

  @override
  State<PasswordDisplayWidget> createState() => _PasswordDisplayWidgetState();
}

class _PasswordDisplayWidgetState extends State<PasswordDisplayWidget> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 密码文本
          Expanded(
            child: Text(
              _isVisible ? widget.password : '•' * widget.password.length,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 显示/隐藏按钮
          if (widget.showVisibilityToggle)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () {
                setState(() {
                  _isVisible = !_isVisible;
                });
              },
              child: Icon(
                _isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
            ),
          // 复制按钮
          if (widget.showCopyButton)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.password));
                HapticFeedback.lightImpact();
                if (widget.onCopy != null) {
                  widget.onCopy!();
                }
                if (context.mounted) {
                  // 显示复制成功提示
                  showCupertinoDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => CupertinoAlertDialog(
                      content: Text(l10n.passwordCopiedToClipboard),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(l10n.ok),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Icon(
                CupertinoIcons.doc_on_clipboard,
                size: 20,
                color: CupertinoColors.activeBlue,
              ),
            ),
        ],
      ),
    );
  }
}
