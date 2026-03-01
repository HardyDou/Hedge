import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:hedge/presentation/providers/locale_provider.dart';
import 'package:hedge/presentation/providers/theme_provider.dart';
import 'package:hedge/presentation/providers/vault_provider.dart';
import 'package:hedge/presentation/pages/sync_settings_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hedge/domain/services/importer/concrete_strategies.dart';
import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/importer/smart_csv_strategy.dart';
import 'dart:io';

class SettingsPanel extends ConsumerStatefulWidget {
  final bool isModal;
  final VoidCallback? onClose;

  const SettingsPanel({
    super.key,
    this.isModal = false,
    this.onClose,
  });

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final vaultState = ref.watch(vaultProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(widget.isModal ? 12 : 0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isModal) _buildHeader(isDark, l10n),
          _buildTabBar(isDark, l10n),
          Container(height: 1, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
          Flexible(
            child: SingleChildScrollView(
              child: _buildContent(themeMode, currentLocale, vaultState, isDark, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, AppLocalizations l10n) {
    final vaultState = ref.watch(vaultProvider);
    final isAuthenticated = vaultState.isAuthenticated;

    final tabs = [
      {'icon': CupertinoIcons.paintbrush, 'label': l10n.appearance, 'requiresAuth': false},
      {'icon': CupertinoIcons.lock, 'label': l10n.security, 'requiresAuth': true},
      {'icon': CupertinoIcons.arrow_down_doc, 'label': l10n.data, 'requiresAuth': true},
      {'icon': CupertinoIcons.info, 'label': '关于', 'requiresAuth': false},
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final requiresAuth = entry.value['requiresAuth'] as bool;
          final isDisabled = requiresAuth && !isAuthenticated;

          return _buildTabItem(
            index: entry.key,
            icon: entry.value['icon'] as IconData,
            label: entry.value['label'] as String,
            isDark: isDark,
            isDisabled: isDisabled,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: isDisabled
          ? () => _showUnlockRequiredDialog()
          : () => setState(() => _selectedTab = index),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey6) : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : (isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : (isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6)),
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 10,
                  color: isDark ? CupertinoColors.white.withValues(alpha: 0.4) : CupertinoColors.black.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockRequiredDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('需要解锁'),
        content: const Text('此功能需要先解锁密码库才能访问'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onClose != null) {
                widget.onClose!();
              }
              ref.read(vaultProvider.notifier).lock();
            },
            child: const Text('立即解锁'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.settings, size: 18, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          const SizedBox(width: 8),
          Text(
            l10n.settings,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          ),
          const Spacer(),
          if (widget.onClose != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onClose,
              child: Icon(CupertinoIcons.xmark, size: 16, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeModeOption themeMode, dynamic currentLocale, VaultState vaultState, bool isDark, AppLocalizations l10n) {
    switch (_selectedTab) {
      case 0:
        return _buildAppearanceTab(themeMode, currentLocale, isDark, l10n);
      case 1:
        return _buildSecurityTab(vaultState, isDark, l10n);
      case 2:
        return _buildDataTab(isDark, l10n);
      case 3:
        return _buildAboutTab(isDark, l10n);
      default:
        return _buildAppearanceTab(themeMode, currentLocale, isDark, l10n);
    }
  }

  Widget _buildAppearanceTab(ThemeModeOption themeMode, dynamic currentLocale, bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingCard([
            _buildListTile(
              title: l10n.themeMode,
              subtitle: _getThemeName(themeMode, l10n),
              isDark: isDark,
              onTap: () => _showThemePicker(context, ref),
            ),
            _buildDivider(isDark),
            _buildListTile(
              title: l10n.language,
              subtitle: currentLocale == null
                  ? l10n.systemDefault
                  : (currentLocale.languageCode == 'zh' ? '简体中文' : 'English'),
              isDark: isDark,
              onTap: () => _showLanguagePicker(context, ref),
              showDivider: false,
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(VaultState vaultState, bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingCard([
            _buildSwitchTile(
              title: l10n.useBiometrics,
              value: vaultState.isBiometricsEnabled,
              isDark: isDark,
              onChanged: (val) => ref.read(vaultProvider.notifier).toggleBiometrics(val),
            ),
            _buildDivider(isDark),
            _buildListTile(
              title: l10n.autoLockTimeout,
              subtitle: vaultState.autoLockTimeout == 0
                  ? 'Off'
                  : l10n.seconds(vaultState.autoLockTimeout),
              isDark: isDark,
              onTap: () => _showAutoLockPicker(context, ref),
              showDivider: false,
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildDataTab(bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingCard([
            _buildListTile(
              title: '同步设置',
              subtitle: '配置 WebDAV 或 iCloud Drive 同步',
              isDark: isDark,
              onTap: () => _navigateToSyncSettings(context),
            ),
            _buildDivider(isDark),
            _buildListTile(
              title: l10n.import,
              subtitle: l10n.importHint,
              isDark: isDark,
              onTap: () => _showImportActionSheet(context, ref),
              showDivider: false,
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildAboutTab(bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingCard([
            _buildListTile(
              title: l10n.appTitle,
              subtitle: 'Version 1.0.0',
              isDark: isDark,
              onTap: () => _showAbout(context),
              showDivider: false,
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF3C3C3E) : CupertinoColors.systemGrey5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 16),
      color: isDark ? const Color(0xFF3C3C3E) : CupertinoColors.systemGrey5,
    );
  }

  Widget _buildListTile({required String title, required String subtitle, required bool isDark, required VoidCallback onTap, bool showDivider = true}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white.withValues(alpha: 0.6) : CupertinoColors.black.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, size: 14, color: isDark ? CupertinoColors.white.withValues(alpha: 0.3) : CupertinoColors.black.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required bool isDark, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 15, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: CupertinoColors.activeBlue),
        ],
      ),
    );
  }

  String _getThemeName(ThemeModeOption mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeModeOption.system: return l10n.system;
      case ThemeModeOption.dark: return l10n.dark;
      case ThemeModeOption.light: return l10n.light;
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerItem(l10n.system, themeMode == ThemeModeOption.system, isDark, () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.system);
                Navigator.pop(ctx);
              }),
              _buildDivider(isDark),
              _buildPickerItem(l10n.dark, themeMode == ThemeModeOption.dark, isDark, () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.dark);
                Navigator.pop(ctx);
              }),
              _buildDivider(isDark),
              _buildPickerItem(l10n.light, themeMode == ThemeModeOption.light, isDark, () {
                ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.light);
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerItem(String text, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: isDark ? CupertinoColors.white : CupertinoColors.black))),
            if (isSelected) const Icon(CupertinoIcons.checkmark_alt, size: 16, color: CupertinoColors.activeBlue),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerItem(l10n.systemDefault, currentLocale == null, isDark, () {
                ref.read(localeProvider.notifier).setLocale(null);
                Navigator.pop(ctx);
              }),
              _buildDivider(isDark),
              _buildPickerItem("English", currentLocale?.languageCode == 'en', isDark, () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(ctx);
              }),
              _buildDivider(isDark),
              _buildPickerItem("简体中文", currentLocale?.languageCode == 'zh', isDark, () {
                ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoLockPicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTimeout = ref.read(vaultProvider).autoLockTimeout;
    final notifier = ref.read(vaultProvider.notifier);
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerItem("Off", currentTimeout == 0, isDark, () { notifier.setAutoLockTimeout(0); Navigator.pop(ctx); }),
              _buildDivider(isDark),
              _buildPickerItem(l10n.seconds(5), currentTimeout == 5, isDark, () { notifier.setAutoLockTimeout(5); Navigator.pop(ctx); }),
              _buildDivider(isDark),
              _buildPickerItem(l10n.seconds(30), currentTimeout == 30, isDark, () { notifier.setAutoLockTimeout(30); Navigator.pop(ctx); }),
              _buildDivider(isDark),
              _buildPickerItem(l10n.seconds(60), currentTimeout == 60, isDark, () { notifier.setAutoLockTimeout(60); Navigator.pop(ctx); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.appTitle),
        content: Text(l10n.aboutDescription),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
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

  void _showImportActionSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    // For Desktop, we use a simple Dialog instead of ActionSheet for better UX
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (sheetContext) => Center(
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(l10n.import, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(l10n.importHint, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Container(height: 0.5, color: CupertinoColors.separator),
              CupertinoButton(
                child: Text('${l10n.importSmart} (${l10n.recommended})'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _handleImport(context, ref, SmartCsvStrategy());
                },
              ),
              Container(height: 0.5, color: CupertinoColors.separator),
              CupertinoButton(
                child: Text(l10n.importChrome),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _handleImport(context, ref, ChromeCsvStrategy());
                },
              ),
              Container(height: 0.5, color: CupertinoColors.separator),
              CupertinoButton(
                child: Text(l10n.import1Password),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _handleImport(context, ref, OnePasswordCsvStrategy());
                },
              ),
              Container(height: 0.5, color: CupertinoColors.separator),
              CupertinoButton(
                child: Text(l10n.cancel, style: const TextStyle(color: CupertinoColors.destructiveRed)),
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
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
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              content: const Text("Failed to read file. Please ensure it is UTF-8 encoded."),
              actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))],
            ),
          );
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
}
