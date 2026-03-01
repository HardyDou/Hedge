import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import '../services/panel_window_service.dart';
import '../services/tray_service.dart';

/// 托盘面板 - 未解锁状态
class TrayPanelLocked extends ConsumerWidget {
  final PanelWindowService panelWindowService;
  final TrayService trayService;

  const TrayPanelLocked({
    super.key,
    required this.panelWindowService,
    required this.trayService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      children: [
        // 标题栏（带右侧按钮）
        _buildHeader(context, l10n, isDark),

        // 中间内容区域
        Expanded(
          child: _buildContent(context, l10n, isDark, ref),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧标题
          Icon(
            CupertinoIcons.lock_fill,
            size: 16,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.appTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),

          const Spacer(),

          // 右侧按钮组
          _buildHeaderIconButton(
            context: context,
            icon: CupertinoIcons.square_arrow_up_on_square,
            tooltip: l10n.openMainWindow,
            isDark: isDark,
            onPressed: () async {
              await panelWindowService.showMainWindow();
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderIconButton(
            context: context,
            icon: CupertinoIcons.power,
            tooltip: l10n.exitApp,
            isDark: isDark,
            isDestructive: true,
            onPressed: () {
              trayService.exitApp();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, AppLocalizations l10n, bool isDark, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 锁定图标
          Icon(
            CupertinoIcons.lock_circle_fill,
            size: 48,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
          const SizedBox(height: 16),

          // 提示文字
          Text(
            l10n.trayPanelLocked,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 24),

          // 解锁按钮
          _buildButton(
            context: context,
            label: l10n.unlockVault,
            icon: CupertinoIcons.lock_open,
            isDark: isDark,
            onPressed: () async {
              await panelWindowService.showMainWindow();
            },
          ),
        ],
      ),
    );
  }

  /// 构建标题栏图标按钮
  Widget _buildHeaderIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: isDestructive
              ? CupertinoColors.systemRed
              : (isDark ? CupertinoColors.white : CupertinoColors.black),
        ),
      ),
    );
  }

  /// 构建按钮
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: CupertinoColors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
