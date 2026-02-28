import 'package:flutter/cupertino.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import '../../providers/vault_provider.dart';

class UnlockPage extends ConsumerStatefulWidget {
  final bool isLockOverlay;
  final VoidCallback? onUnlocked;

  const UnlockPage({
    super.key,
    this.isLockOverlay = false,
    this.onUnlocked,
  });

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_passwordController.text.isEmpty) return;

    final success = await ref.read(vaultProvider.notifier).unlockVault(
          _passwordController.text,
        );

    if (success) {
      if (widget.isLockOverlay) {
        widget.onUnlocked?.call();
      }
    } else {
      _passwordController.clear();
    }
  }

  Future<void> _handleForgotPassword(BuildContext context) async {
    final vaultState = ref.read(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    
    if (vaultState.isBiometricsEnabled) {
      showCupertinoModalPopup(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(l10n.forgotPassword),
          message: Text(l10n.biometricResetReason),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(sheetContext);
                final success = await ref.read(vaultProvider.notifier).unlockWithBiometrics();
                if (success && widget.isLockOverlay && context.mounted) {
                  widget.onUnlocked?.call();
                }
              },
              child: Text(_getBiometricLabel(vaultState.biometricType, l10n)),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                _showResetConfirmDialog(context);
              },
              child: Text(l10n.createNewVault),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(l10n.cancelCaps),
          ),
        ),
      );
    } else {
      _showResetConfirmDialog(context);
    }
  }

  Future<void> _showResetConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.resetVaultTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.resetVaultWarning),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmReset),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(vaultProvider.notifier).resetVaultCompletely();
      if (widget.isLockOverlay && context.mounted) {
        AppLock.of(context)?.didUnlock();
      }
    }
  }

  String _getBiometricLabel(BiometricType? type, AppLocalizations l10n) {
    if (type == BiometricType.face) {
      return l10n.unlockWithFaceID;
    } else if (type == BiometricType.fingerprint) {
      return l10n.unlockWithTouchID;
    }
    return l10n.resetWithBiometrics;
  }

  IconData _getBiometricIcon(BiometricType? type) {
    if (type == BiometricType.face) {
      return CupertinoIcons.viewfinder;
    } else if (type == BiometricType.fingerprint) {
      return CupertinoIcons.hand_draw;
    }
    return CupertinoIcons.lock_open;
  }

  void _showSuccessDialog(BuildContext context, String message, {bool navigateToOnboarding = false}) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (navigateToOnboarding) {
                Navigator.of(dialogContext).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : CupertinoColors.white,
      child: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Container(
              decoration: isDark
                  ? const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          Color(0xFF1A1A1A),
                          Color(0xFF0F0F0F),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          
          // 主要内容层 (居中)
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.lock,
                        size: 64,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.appTitle,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // 生物识别按钮 (移到输入框上方)
                      if (vaultState.isBiometricsEnabled)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: CupertinoButton(
                            onPressed: () async {
                              final success = await ref.read(vaultProvider.notifier).unlockWithBiometrics();
                              if (success && widget.isLockOverlay) {
                                widget.onUnlocked?.call();
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.activeBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getBiometricIcon(vaultState.biometricType),
                                    size: 36,
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getBiometricLabel(vaultState.biometricType, l10n),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // 密码输入框
                      CupertinoTextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        autofocus: true,
                        padding: const EdgeInsets.all(16),
                        style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black, fontSize: 18),
                        placeholder: l10n.enterMasterPassword,
                        placeholderStyle: TextStyle(color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.3)),
                        decoration: BoxDecoration(
                          color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffix: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              _isPasswordVisible
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.5),
                              size: 20,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _handleUnlock(),
                      ),
                      const SizedBox(height: 16),
                      
                      // 错误提示
                      if (vaultState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            vaultState.error!,
                            style: const TextStyle(color: CupertinoColors.destructiveRed),
                          ),
                        ),
                      
                      // 解锁按钮
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: CupertinoButton(
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: vaultState.isLoading ? null : _handleUnlock,
                          child: vaultState.isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CupertinoActivityIndicator(
                                    color: isDark ? CupertinoColors.black : CupertinoColors.white,
                                  ),
                                )
                              : Text(
                                  l10n.unlock,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: isDark ? CupertinoColors.black : CupertinoColors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 80), // 底部留白
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 底部固定层 (忘记密码)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _handleForgotPassword(context),
                    child: Text(
                      l10n.forgotPassword,
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
