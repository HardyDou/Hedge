import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import '../services/panel_window_service.dart';
import '../services/tray_service.dart';

/// 托盘面板 - 未解锁状态
class TrayPanelLocked extends ConsumerStatefulWidget {
  final PanelWindowService panelWindowService;
  final TrayService trayService;

  const TrayPanelLocked({
    super.key,
    required this.panelWindowService,
    required this.trayService,
  });

  @override
  ConsumerState<TrayPanelLocked> createState() => _TrayPanelLockedState();
}

class _TrayPanelLockedState extends ConsumerState<TrayPanelLocked> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(vaultProvider.notifier).unlockVault(_passwordController.text);

      if (!success && mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)?.incorrectPassword ?? 'Incorrect password';
          _isUnlocking = false;
        });
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isUnlocking = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometric() async {
    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(vaultProvider.notifier).unlockWithBiometrics();

      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
          _isUnlocking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isUnlocking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: _buildContent(context, l10n, isDark),
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
              await widget.panelWindowService.showMainWindow();
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
              widget.trayService.exitApp();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Logo/Icon - 更小更紧凑
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 32,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 24),

          // 密码输入框 + 解锁按钮 - 整体设计
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
              border: _errorMessage != null
                  ? Border.all(color: CupertinoColors.systemRed, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // 输入框
                Expanded(
                  child: CupertinoTextField(
                    controller: _passwordController,
                    placeholder: l10n.enterMasterPassword,
                    obscureText: true,
                    enabled: !_isUnlocking,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                    ),
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onSubmitted: (value) => _unlock(),
                  ),
                ),

                // 解锁按钮
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minSize: 0,
                  onPressed: _isUnlocking ? null : _unlock,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isUnlocking
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.activeBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _isUnlocking
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                            radius: 8,
                          )
                        : const Icon(
                            CupertinoIcons.arrow_right,
                            size: 16,
                            color: CupertinoColors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // 错误提示
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 生物识别按钮 - 更紧凑
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isUnlocking ? null : _unlockWithBiometric,
            child: Container(
              width: double.infinity,
              height: 36,
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
                    CupertinoIcons.hand_raised_fill,
                    size: 16,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.useBiometricUnlock,
                    style: TextStyle(
                      fontSize: 12,
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
