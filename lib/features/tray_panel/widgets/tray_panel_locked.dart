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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Logo/Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 36,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 32),

          // 密码输入框 + 解锁按钮
          Row(
            children: [
              // 输入框
              Expanded(
                child: CupertinoTextField(
                  placeholder: l10n.enterMasterPassword,
                  obscureText: true,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  placeholderStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onSubmitted: (value) {
                    // TODO: 解锁
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 解锁按钮
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // TODO: 解锁
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_right,
                    size: 20,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 生物识别按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: 生物识别解锁
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.touchid,
                    size: 18,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.useBiometricUnlock,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
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
}
