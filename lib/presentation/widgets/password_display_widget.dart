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
          // 密码文本
          Expanded(
            child: Text(
              _isVisible ? widget.password : '•' * widget.password.length,
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
          // 显示/隐藏按钮
          if (widget.showVisibilityToggle)
            Semantics(
              label: _isVisible ? 'Hide password' : 'Show password',
              button: true,
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                minSize: 36,
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
                child: Icon(
                  _isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          // 复制按钮
          if (widget.showCopyButton)
            Semantics(
              label: 'Copy password',
              button: true,
              hint: 'Copy password to clipboard',
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                minSize: 36,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.password));
                  HapticFeedback.mediumImpact();
                  if (widget.onCopy != null) {
                    widget.onCopy!();
                  }
                  if (context.mounted) {
                    _showCopiedToast(context, l10n);
                  }
                },
                child: Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 20,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCopiedToast(BuildContext context, AppLocalizations l10n) {
    final overlay = Overlay.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: screenHeight * 0.15,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CupertinoColors.systemGreen.resolveFrom(context),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.systemGreen.resolveFrom(context),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.passwordCopiedToClipboard,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1200), () {
      overlayEntry.remove();
    });
  }
}
