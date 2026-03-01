import 'package:flutter/cupertino.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import '../services/panel_window_service.dart';
import '../services/tray_service.dart';

/// 托盘快捷面板 UI 组件
class TrayPanel extends StatelessWidget {
  final PanelWindowService panelWindowService;
  final TrayService trayService;

  const TrayPanel({
    super.key,
    required this.panelWindowService,
    required this.trayService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.separator,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.5 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(context, l10n, isDark),

          // 搜索框
          _buildSearchBar(context, l10n, isDark),

          // 内容区域
          Expanded(
            child: _buildContent(context, l10n, isDark),
          ),

          // 底部按钮
          _buildFooter(context, l10n, isDark),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.lock_shield_fill,
            size: 18,
            color: isDark
                ? CupertinoColors.systemGrey6
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.trayPanelTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? CupertinoColors.white
                  : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: CupertinoSearchTextField(
        placeholder: l10n.quickSearch,
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? CupertinoColors.white
              : CupertinoColors.black,
        ),
        placeholderStyle: TextStyle(
          fontSize: 13,
          color: isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey2,
        ),
        backgroundColor: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        onChanged: (value) {
          // TODO: 实现搜索功能
        },
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, AppLocalizations l10n, bool isDark) {
    // TODO: 显示最近使用的密码列表
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.lock_circle,
            size: 48,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noRecentPasswords,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildFooter(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 打开主窗口按钮
          _buildButton(
            context: context,
            label: l10n.openMainWindow,
            icon: CupertinoIcons.square_arrow_up,
            isDark: isDark,
            isPrimary: true,
            onPressed: () async {
              await panelWindowService.showMainWindow();
            },
          ),
          const SizedBox(height: 8),
          // 退出应用按钮
          _buildButton(
            context: context,
            label: l10n.exitApp,
            icon: CupertinoIcons.power,
            isDark: isDark,
            isPrimary: false,
            isDestructive: true,
            onPressed: () {
              trayService.exitApp();
            },
          ),
        ],
      ),
    );
  }

  /// 构建按钮（带悬浮效果）
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isPrimary,
    bool isDestructive = false,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary
                ? CupertinoColors.activeBlue
                : (isDestructive
                    ? CupertinoColors.systemRed.withOpacity(0.1)
                    : (isDark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary
                    ? CupertinoColors.white
                    : (isDestructive
                        ? CupertinoColors.systemRed
                        : (isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPrimary
                      ? CupertinoColors.white
                      : (isDestructive
                          ? CupertinoColors.systemRed
                          : (isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
