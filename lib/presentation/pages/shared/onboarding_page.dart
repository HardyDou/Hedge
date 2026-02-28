import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import '../../providers/vault_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) return;
    if (_passwordController.text != _confirmController.text) {
      _showErrorDialog(l10n.passwordsDoNotMatch);
      return;
    }

    if (_passwordController.text.length < 8) {
      _showErrorDialog(l10n.passwordTooShort);
      return;
    }

    final success = await ref.read(vaultProvider.notifier).setupVault(_passwordController.text);
    if (!success && mounted) {
      final error = ref.read(vaultProvider).error;
      _showErrorDialog(error ?? "Setup failed");
    } else if (success && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.import),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.importPrompt),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.skip),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['csv'],
                );
                if (result != null) {
                  final file = File(result.files.single.path!);
                  final content = await file.readAsString();
                  ref.read(vaultProvider.notifier).importFromCsv(content);
                }
              },
              child: Text(l10n.importNow),
            ),
          ],
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
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
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcome,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingSub,
                  style: TextStyle(
                    color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.recoveryWarning,
                          style: TextStyle(
                            color: isDark ? CupertinoColors.white.withOpacity(0.9) : CupertinoColors.black.withOpacity(0.87),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildField(
                  controller: _passwordController,
                  hint: l10n.enterMasterPassword,
                  obscure: _obscurePassword,
                  isDark: isDark,
                  toggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmController,
                  hint: l10n.enterMasterPassword,
                  obscure: _obscureConfirm,
                  isDark: isDark,
                  toggleVisibility: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: vaultState.isLoading ? null : _handleSetup,
                    child: vaultState.isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : Text(
                            l10n.createVault,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: CupertinoColors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required bool isDark,
    required VoidCallback toggleVisibility,
  }) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscure,
      padding: const EdgeInsets.all(16),
      style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
      placeholder: hint,
      placeholderStyle: TextStyle(color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.3)),
      decoration: BoxDecoration(
        color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      suffix: CupertinoButton(
        padding: const EdgeInsets.only(right: 8),
        onPressed: toggleVisibility,
        child: Icon(
          obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          color: (isDark ? CupertinoColors.white : CupertinoColors.black).withOpacity(0.5),
          size: 20,
        ),
      ),
    );
  }
}
