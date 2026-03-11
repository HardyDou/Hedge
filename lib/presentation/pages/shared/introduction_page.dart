import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';

/// 功能介绍页面 - 多页轮播展示应用核心功能
class IntroductionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroductionPage({super.key, required this.onComplete});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_introduction', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      _IntroPage(
        icon: CupertinoIcons.lock_shield_fill,
        title: l10n.introSecureTitle,
        description: l10n.introSecureDesc,
        color: CupertinoColors.activeBlue,
      ),
      _IntroPage(
        icon: CupertinoIcons.cloud,
        title: l10n.introSyncTitle,
        description: l10n.introSyncDesc,
        color: CupertinoColors.systemGreen,
      ),
      _IntroPage(
        icon: CupertinoIcons.device_laptop,
        title: l10n.introCrossTitle,
        description: l10n.introCrossDesc,
        color: CupertinoColors.systemOrange,
      ),
      _IntroPage(
        icon: CupertinoIcons.hand_raised_fill,
        title: l10n.introPrivacyTitle,
        description: l10n.introPrivacyDesc,
        color: CupertinoColors.systemPurple,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000), // Transparent
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CupertinoButton(
                onPressed: _complete,
                child: Text(
                  l10n.introSkip,
                  style: TextStyle(
                    color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) => pages[index],
              ),
            ),
            _buildIndicator(isDark, pages.length),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _currentPage == pages.length - 1
                      ? _complete
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  child: Text(
                    _currentPage == pages.length - 1 ? l10n.introStart : l10n.introNext,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildIndicator(bool isDark, int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? CupertinoColors.activeBlue
                : (isDark ? CupertinoColors.white : CupertinoColors.black)
                    .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                  .withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
