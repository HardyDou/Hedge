import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LargePasswordDialog {
  static void show(BuildContext context, String password) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _buildDialog(context, password, isDark, screenWidth),
    );
  }

  static Widget _buildDialog(BuildContext context, String password, bool isDark, double screenWidth) {
    final maxWidth = screenWidth * 0.8;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '密码',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: List.generate(password.length, (index) {
                    return _buildCharWithIndex(password[index], index + 1, isDark);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_doc, size: 16, color: CupertinoColors.white),
                    SizedBox(width: 6),
                    Text('复制密码', style: TextStyle(color: CupertinoColors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCharWithIndex(String char, int index, bool isDark) {
    final isEven = index % 2 == 0;
    final bgColor = isEven
        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7))
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA));
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              char,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            index.toString(),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? CupertinoColors.white.withValues(alpha: 0.5) : CupertinoColors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
