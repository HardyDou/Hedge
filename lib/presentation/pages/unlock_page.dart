import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import '../providers/vault_provider.dart';

class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

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

    if (!success) {
      _passwordController.clear();
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final vaultState = ref.read(vaultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final canUseBiometrics = vaultState.isBiometricsEnabled;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(
          l10n.forgotPassword,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.resetWarning,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            if (canUseBiometrics) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await ref.read(vaultProvider.notifier).resetVaultWithBiometrics();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.vaultResetSuccess)),
                      );
                    }
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.resetWithBiometrics),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.noBiometricsAvailable,
                  style: TextStyle(color: isDark ? Colors.orange[300] : Colors.orange[700]),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      title: Text(
                        l10n.createNewVault,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      content: Text(
                        l10n.resetWarning,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancelCaps),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            l10n.confirmReset,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context);
                    await ref.read(vaultProvider.notifier).resetVaultCompletely();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.vaultResetSuccess)),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                  foregroundColor: isDark ? Colors.white : Colors.black,
                ),
                child: Text(l10n.createNewVault),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelCaps),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: Container(
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
                  // Logo / Icon
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Master Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: l10n.enterMasterPassword,
                      hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
                      filled: true,
                      fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
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
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  // Unlock Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: vaultState.isLoading ? null : _handleUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: vaultState.isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Text(
                              l10n.unlock,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Forgot Password Link
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                  // Biometrics button
                  if (vaultState.isBiometricsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        onPressed: () =>
                            ref.read(vaultProvider.notifier).unlockWithBiometrics(),
                        icon: Icon(Icons.fingerprint, color: isDark ? Colors.white70 : Colors.black54),
                        label: Text(
                          l10n.useBiometrics,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
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
