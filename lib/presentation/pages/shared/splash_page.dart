import 'package:flutter/cupertino.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';

/// 启动页面 - 显示应用 Logo 和加载动画
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 图标
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                CupertinoIcons.lock_shield_fill,
                size: 56,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 32),

            // 应用名称
            const Text(
              'Hedge',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // 副标题
            if (l10n != null)
              Text(
                l10n.appSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                      .withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 48),

            // 加载指示器
            const CupertinoActivityIndicator(
              radius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
