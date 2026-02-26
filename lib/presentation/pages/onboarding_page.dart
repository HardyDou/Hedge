import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import '../providers/vault_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _customPath;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _customPath = "$selectedDirectory/vault.db";
      });
      ref.read(vaultProvider.notifier).setVaultPath(_customPath!);
    }
  }

  Future<void> _handleSetup() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordsDoNotMatch)), 
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordTooShort)),
      );
      return;
    }

    final success = await ref.read(vaultProvider.notifier).setupVault(_passwordController.text);
    if (!success && mounted) {
      final error = ref.read(vaultProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? "Setup failed")),
      );
    } else if (success && mounted) {
      // Prompt for import
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1A1A1A) 
              : Colors.white,
          title: Text(l10n.import, 
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87)),
          content: Text(l10n.importPrompt,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Skip
              child: Text(l10n.skip, 
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.importNow),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
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
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingSub,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Storage path is now automated
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDark 
                            ? "Your vault will be automatically synced with iCloud (Apple) or Cloud Backup (Android)."
                            : "您的密码库将自动通过 iCloud 或 厂商云进行同步。",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
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
                  visible: _isPasswordVisible,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmController,
                  hint: l10n.password, 
                  visible: _isPasswordVisible,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: vaultState.isLoading ? null : _handleSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: vaultState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.createVault),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.recoveryWarning,
                  style: TextStyle(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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
    required bool visible,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
