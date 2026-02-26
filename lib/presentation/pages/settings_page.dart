import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_password/l10n/generated/app_localizations.dart';
import 'package:note_password/presentation/providers/locale_provider.dart';
import 'package:note_password/presentation/providers/theme_provider.dart';
import 'package:note_password/presentation/providers/vault_provider.dart';
import 'dart:io';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.appearance.toUpperCase(),
            children: [
              _iOSListTile(
                title: l10n.themeMode,
                subtitle: _getThemeName(themeMode, l10n),
                leading: Icon(Icons.palette_outlined, color: _getAccentColor(isDark)),
                onTap: () => _showThemePicker(context, ref),
                isDark: isDark,
              ),
              _iOSListTile(
                title: l10n.language,
                subtitle: currentLocale == null 
                    ? l10n.systemDefault 
                    : (currentLocale.languageCode == 'zh' ? '简体中文' : 'English'),
                leading: Icon(Icons.language_outlined, color: _getAccentColor(isDark)),
                onTap: () => _showLanguagePicker(context, ref),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.data,
            children: [
              _iOSListTile(
                title: l10n.import,
                subtitle: l10n.importHint,
                leading: Icon(Icons.file_download_outlined, color: _getAccentColor(isDark)),
                onTap: () => _handleImport(context, ref),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: l10n.security.toUpperCase(),
            children: [
              _iOSSwitchTile(
                title: l10n.useBiometrics,
                leading: Icon(Icons.fingerprint, color: _getAccentColor(isDark)),
                value: vaultState.isBiometricsEnabled,
                onChanged: (val) => ref.read(vaultProvider.notifier).toggleBiometrics(val),
                isDark: isDark,
              ),
              _iOSSliderTile(
                title: l10n.autoLockTimeout,
                value: vaultState.autoLockTimeout.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: l10n.seconds(vaultState.autoLockTimeout),
                onChanged: (value) => ref.read(vaultProvider.notifier).setAutoLockTimeout(value.toInt()),
                leading: Icon(Icons.timer_outlined, color: _getAccentColor(isDark)),
                isDark: isDark,
              ),
              _iOSListTile(
                title: l10n.resetPassword,
                subtitle: "",
                leading: Icon(Icons.lock_reset, color: _getAccentColor(isDark)),
                onTap: () => _showResetPasswordDialog(context, ref),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildiOSSection(
            context: context,
            header: "ABOUT",
            children: [
              _iOSListTile(
                title: l10n.appTitle,
                subtitle: "Version 1.0.0",
                leading: Icon(Icons.info_outline, color: _getAccentColor(isDark)),
                onTap: () => _showAbout(context),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Color _getAccentColor(bool isDark) {
    return const Color(0xFF007AFF);
  }

  Widget _buildiOSSection({
    required BuildContext context,
    required String header,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
          child: Text(
            header,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.system;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.light:
        return l10n.light;
    }
  }

  void _handleImport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show format hint dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.import),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importFormatHint),
            const SizedBox(height: 12),
            Text(
              l10n.importNoHeaderHint,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      
      final importResult = await ref.read(vaultProvider.notifier).importFromCsv(content);
      
      if (context.mounted) {
        String message;
        if (importResult.failed == 0) {
          message = l10n.importSuccess(importResult.success);
        } else {
          message = '${l10n.importSuccess(importResult.success)}\n${l10n.importFailed(importResult.failed)}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: importResult.failed > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appTitle),
        content: Text(l10n.aboutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.resetPassword),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: currentPasswordController,
              placeholder: l10n.enterCurrentPassword,
              obscureText: true,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: newPasswordController,
              placeholder: l10n.enterNewPassword,
              obscureText: true,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: confirmPasswordController,
              placeholder: l10n.confirmNewPassword,
              obscureText: true,
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (newPasswordController.text.isEmpty || 
                  currentPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                return;
              }
              
              if (newPasswordController.text != confirmPasswordController.text) {
                _showErrorToast(context, l10n.passwordsDoNotMatch);
                return;
              }
              
              Navigator.pop(dialogContext);
              
              final success = await ref.read(vaultProvider.notifier).resetMasterPassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
              
              if (context.mounted) {
                if (success) {
                  _showSuccessToast(context, l10n.passwordResetSuccess);
                } else {
                  final error = ref.read(vaultProvider).error;
                  String errorMessage;
                  switch (error) {
                    case 'incorrect_current_password':
                      errorMessage = l10n.incorrectCurrentPassword;
                      break;
                    case 'vault_not_unlocked':
                      errorMessage = 'Vault not unlocked';
                      break;
                    case 'reset_password_failed':
                      errorMessage = l10n.passwordResetFailed;
                      break;
                    default:
                      errorMessage = error ?? l10n.passwordResetFailed;
                  }
                  _showErrorToast(context, errorMessage);
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.themeMode),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.system),
                if (themeMode == ThemeMode.system) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dark),
                if (themeMode == ThemeMode.dark) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.light),
                if (themeMode == ThemeMode.light) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDestructiveAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.language),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(null);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.systemDefault),
                if (currentLocale == null) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("English"),
                if (currentLocale?.languageCode == 'en') ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("简体中文"),
                if (currentLocale?.languageCode == 'zh') ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDestructiveAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
}

class _iOSListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;
  final bool isDark;
  final bool showDivider;

  const _iOSListTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconTheme(
                    data: IconThemeData(
                      size: 22,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    child: leading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: 60,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
      ],
    );
  }
}

class _iOSSwitchTile extends StatelessWidget {
  final String title;
  final Widget leading;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _iOSSwitchTile({
    required this.title,
    required this.leading,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _getAccentColor(isDark),
          ),
        ],
      ),
    );
  }

  Color _getAccentColor(bool isDark) => const Color(0xFF007AFF);
}

class _iOSSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;
  final Widget leading;
  final bool isDark;
  final bool showDivider;

  const _iOSSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    required this.leading,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            activeColor: _getAccentColor(isDark),
            onChanged: onChanged,
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: 16,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
      ],
    );
  }

  Color _getAccentColor(bool isDark) => const Color(0xFF007AFF);
}

class _iOSPickerTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool showDivider;

  const _iOSPickerTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: _getAccentColor(isDark),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: 20,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
      ],
    );
  }

  Color _getAccentColor(bool isDark) => const Color(0xFF007AFF);
}

class _iOSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool isDark;
  final bool isPassword;

  const _iOSTextField({
    required this.controller,
    required this.placeholder,
    required this.isDark,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.08) 
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 16,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
