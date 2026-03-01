import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/domain/services/importer/concrete_strategies.dart';
import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/importer/smart_csv_strategy.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/locale_provider.dart';
import 'package:hedge/presentation/providers/theme_provider.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/presentation/pages/sync_settings_page.dart';
import 'dart:io';

class _CustomNavBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onBack;
  final Widget child;

  const _CustomNavBar({
    required this.title,
    required this.isDark,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).padding.top + 44,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: onBack,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.back,
                        color: CupertinoColors.activeBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 70),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: _CustomNavBar(
        title: l10n.settings,
        isDark: isDark,
        onBack: () => Navigator.pop(context),
        child: SafeArea(
          top: false, // This SafeArea will only handle bottom padding
          child: ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 44 + 32), // Add padding for custom nav bar + initial SizedBox
            children: [
              // Removed initial SizedBox(height: 32) since it's now part of the padding
            _buildiOSSection(
              context: context,
              header: l10n.appearance.toUpperCase(),
              children: [
                _iOSListTile(
                  title: l10n.themeMode,
                  subtitle: _getThemeName(themeMode, l10n),
                  leading: const Icon(CupertinoIcons.paintbrush, color: CupertinoColors.activeBlue),
                  onTap: () => _showThemePicker(context, ref),
                  isDark: isDark,
                ),
                _iOSListTile(
                  title: l10n.language,
                  subtitle: currentLocale == null 
                      ? l10n.systemDefault 
                      : (currentLocale.languageCode == 'zh' ? '简体中文' : 'English'),
                  leading: const Icon(CupertinoIcons.globe, color: CupertinoColors.activeBlue),
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
                  title: '同步设置',
                  subtitle: '配置 WebDAV 或 iCloud Drive 同步',
                  leading: const Icon(CupertinoIcons.cloud_upload, color: CupertinoColors.activeBlue),
                  onTap: () => _navigateToSyncSettings(context),
                  isDark: isDark,
                ),
                _iOSListTile(
                  title: l10n.import,
                  subtitle: l10n.importHint,
                  leading: const Icon(CupertinoIcons.arrow_down_doc, color: CupertinoColors.activeBlue),
                  onTap: () => _showImportActionSheet(context, ref),
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
                  leading: const Icon(CupertinoIcons.hand_draw, color: CupertinoColors.activeBlue),
                  value: vaultState.isBiometricsEnabled,
                  onChanged: (val) => ref.read(vaultProvider.notifier).toggleBiometrics(val),
                  isDark: isDark,
                ),
                _iOSListTile(
                  title: l10n.autoLockTimeout,
                  subtitle: vaultState.autoLockTimeout == 0 
                      ? "Off" 
                      : l10n.seconds(vaultState.autoLockTimeout),
                  leading: const Icon(CupertinoIcons.timer, color: CupertinoColors.activeBlue),
                  onTap: () => _showAutoLockPicker(context, ref),
                  isDark: isDark,
                ),
                _iOSListTile(
                  title: l10n.resetPassword,
                  subtitle: "",
                  leading: const Icon(CupertinoIcons.lock_rotation, color: CupertinoColors.activeBlue),
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
                  leading: const Icon(CupertinoIcons.info, color: CupertinoColors.activeBlue),
                  onTap: () => _showAbout(context),
                  isDark: isDark,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildiOSSection({
    required BuildContext context,
    required String header,
    required List<Widget> children,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
          child: Text(
            header,
            style: TextStyle(
              color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.54),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _getThemeName(ThemeModeOption mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeModeOption.system:
        return l10n.system;
      case ThemeModeOption.dark:
        return l10n.dark;
      case ThemeModeOption.light:
        return l10n.light;
    }
  }

  void _showImportActionSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.import),
        message: Text(l10n.importHint),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _handleImport(context, ref, SmartCsvStrategy());
            },
            child: Text('${l10n.importSmart} (${l10n.recommended})'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _handleImport(context, ref, ChromeCsvStrategy());
            },
            child: Text(l10n.importChrome),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _handleImport(context, ref, OnePasswordCsvStrategy());
            },
            child: Text(l10n.import1Password),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          isDestructiveAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  void _handleImport(BuildContext context, WidgetRef ref, ImportStrategy strategy) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Security Warning Dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${l10n.import} (${strategy.providerName})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(l10n.securityWarning), // Warning about deleting CSV after
            const SizedBox(height: 12),
            Text(
              l10n.importFormatHint,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'], // Allow txt just in case
    );
    
    if (result != null) {
      // Show loading indicator
      if (context.mounted) {
        showCupertinoDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => const Center(child: CupertinoActivityIndicator(radius: 16))
        );
      }

      final file = File(result.files.single.path!);
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        // Fallback for encoding issues?
        // Simple retry with latin1 if utf8 fails is complex here without knowing the error type precisely
        // For now assume UTF8.
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          _showErrorToast(context, "Failed to read file. Please ensure it is UTF-8 encoded.");
        }
        return;
      }
      
      final importResult = await ref.read(vaultProvider.notifier).importFromCsv(content, strategy: strategy);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        String message;
        if (importResult.failed == 0) {
          message = l10n.importSuccess(importResult.success);
        } else {
          message = '${l10n.importSuccess(importResult.success)}\n${l10n.importFailed(importResult.failed)}';
        }
        
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(l10n.importResult),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.appTitle),
        content: Text(l10n.aboutDescription),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAutoLockPicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTimeout = ref.read(vaultProvider).autoLockTimeout;
    final notifier = ref.read(vaultProvider.notifier);
    final appLock = AppLock.of(context);
    
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.autoLockTimeout),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(0);
              appLock?.setBackgroundLockLatency(Duration(seconds: 0));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Off"),
                if (currentTimeout == 0) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(1);
              appLock?.setBackgroundLockLatency(Duration(seconds: 1));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.seconds(1)),
                if (currentTimeout == 1) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(5);
              appLock?.setBackgroundLockLatency(Duration(seconds: 5));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.seconds(5)),
                if (currentTimeout == 5) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(10);
              appLock?.setBackgroundLockLatency(Duration(seconds: 10));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.seconds(10)),
                if (currentTimeout == 10) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(30);
              appLock?.setBackgroundLockLatency(Duration(seconds: 30));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.seconds(30)),
                if (currentTimeout == 30) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              notifier.setAutoLockTimeout(60);
              appLock?.setBackgroundLockLatency(Duration(seconds: 60));
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.seconds(60)),
                if (currentTimeout == 60) ...[
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

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _ResetPasswordSheet(isDark: isDark, l10n: l10n),
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
              ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.system);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.system),
                if (themeMode == ThemeModeOption.system) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.dark);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dark),
                if (themeMode == ThemeModeOption.dark) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.light);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.light),
                if (themeMode == ThemeModeOption.light) ...[
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

  void _navigateToSyncSettings(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SyncSettingsPage(),
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
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
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
                      color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.54),
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
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: isDark ? CupertinoColors.white.withOpacity(0.25) : CupertinoColors.black.withOpacity(0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 60),
            color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
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
          SizedBox(
            width: 28,
            height: 28,
            child: IconTheme(
              data: IconThemeData(
                size: 22,
                color: CupertinoColors.activeBlue,
              ),
              child: leading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 16,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: CupertinoColors.activeBlue,
          ),
        ],
      ),
    );
  }
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
              SizedBox(
                width: 28,
                height: 28,
                child: IconTheme(
                  data: IconThemeData(
                    size: 22,
                    color: CupertinoColors.activeBlue,
                  ),
                  child: leading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? CupertinoColors.white.withOpacity(0.6) : CupertinoColors.black.withOpacity(0.45),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 16),
            color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
          ),
      ],
    );
  }
}

class _ResetPasswordSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final AppLocalizations l10n;

  const _ResetPasswordSheet({required this.isDark, required this.l10n});

  @override
  ConsumerState<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends ConsumerState<_ResetPasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_newPasswordController.text.isEmpty || 
        _currentPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError(widget.l10n.passwordsDoNotMatch);
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(widget.l10n.passwordsDoNotMatch);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final success = await ref.read(vaultProvider.notifier).resetMasterPassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      Navigator.pop(context);
      _showSuccess(widget.l10n.passwordResetSuccess);
    } else {
      final error = ref.read(vaultProvider).error;
      String errorMessage;
      switch (error) {
        case 'incorrect_current_password':
          errorMessage = widget.l10n.incorrectCurrentPassword;
          break;
        case 'vault_not_unlocked':
          errorMessage = 'Vault not unlocked';
          break;
        case 'reset_password_failed':
          errorMessage = widget.l10n.passwordResetFailed;
          break;
        default:
          errorMessage = error ?? widget.l10n.passwordResetFailed;
      }
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
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

  void _showSuccess(String message) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final l10n = widget.l10n;
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(l10n.cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    l10n.resetPassword,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _isLoading
                      ? const CupertinoActivityIndicator()
                      : CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _handleReset,
                          child: Text(
                            l10n.save,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                ],
              ),
            ),
            Container(height: 0.5, color: CupertinoColors.separator),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    placeholder: l10n.enterCurrentPassword,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? CupertinoColors.black : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    placeholder: l10n.enterNewPassword,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? CupertinoColors.black : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    placeholder: l10n.confirmNewPassword,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? CupertinoColors.black : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
