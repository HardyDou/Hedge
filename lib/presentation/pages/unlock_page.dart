import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import '../providers/vault_provider.dart';

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

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final vaultState = ref.read(vaultProvider);
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    final canUseBiometrics = vaultState.isBiometricsEnabled;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.forgotPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.resetWarning,
            ),
            const SizedBox(height: 16),
            if (canUseBiometrics) ...[
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await ref.read(vaultProvider.notifier).resetVaultWithBiometrics();
                    if (success && context.mounted) {
                      _showSuccessDialog(context, l10n.vaultResetSuccess);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.lock_open,
                        color: isDark ? CupertinoColors.black : CupertinoColors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.resetWithBiometrics,
                        style: TextStyle(color: isDark ? CupertinoColors.black : CupertinoColors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.noBiometricsAvailable,
                  style: TextStyle(color: CupertinoColors.systemOrange),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: () async {
                  final confirmed = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(l10n.createNewVault),
                      content: Text(l10n.resetWarning),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancelCaps),
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
                    Navigator.pop(context);
                    await ref.read(vaultProvider.notifier).resetVaultCompletely();
                    if (context.mounted) {
                      _showSuccessDialog(context, l10n.vaultResetSuccess, navigateToOnboarding: true);
                    }
                  }
                },
                child: Text(l10n.createNewVault),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelCaps),
          ),
        ],
      ),
    );
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 64),
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
                  const SizedBox(height: 24),
                  if (vaultState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        vaultState.error!,
                        style: const TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                    ),
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
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CupertinoButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54)),
                      ),
                    ),
                  ),
                  if (vaultState.isBiometricsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CupertinoButton(
                        onPressed: () async {
                          final success = await ref.read(vaultProvider.notifier).unlockWithBiometrics();
                          if (success && widget.isLockOverlay) {
                            widget.onUnlocked?.call();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.hand_draw, color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.useBiometrics,
                              style: TextStyle(color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
