// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Password Vault';

  @override
  String get unlock => 'UNLOCK';

  @override
  String get enterMasterPassword => 'Enter Master Password';

  @override
  String get incorrectPassword => 'Incorrect master password';

  @override
  String get myVault => 'My Passwords';

  @override
  String get addPassword => 'ADD PASSWORD';

  @override
  String get newEntry => 'New Entry';

  @override
  String get title => 'Title';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get url => 'URL';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'SAVE';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'ADD';

  @override
  String get delete => 'DELETE';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get deleteEntry => 'Delete Entry?';

  @override
  String get deleteWarning => 'This action cannot be undone.';

  @override
  String get search => 'Search...';

  @override
  String get noPasswords => 'No passwords yet. Tap + to add.';

  @override
  String copied(String label) {
    return 'Copied';
  }

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get welcome => 'Welcome';

  @override
  String get createVault => 'CREATE VAULT';

  @override
  String get onboardingSub =>
      'Create a strong master password to encrypt your personal vault.';

  @override
  String get storageLocation => 'STORAGE LOCATION';

  @override
  String get defaultLocal => 'Default (Local Only)';

  @override
  String get syncTip =>
      'Tip: Choose a folder in iCloud Drive or Xiaomi/Huawei Cloud to sync across devices.';

  @override
  String get recoveryWarning =>
      'IMPORTANT: If you forget this password, your data cannot be recovered. We do not store it on any server.';

  @override
  String get attachments => 'ATTACHMENTS';

  @override
  String get addFile => 'Add Certificate/File';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get language => 'Language';

  @override
  String get security => 'Security';

  @override
  String get vaultPath => 'Vault Path';

  @override
  String get system => 'System';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get confirmDelete => 'Delete Entry?';

  @override
  String get cancelCaps => 'CANCEL';

  @override
  String get deleteCaps => 'DELETE';

  @override
  String get saveCaps => 'SAVE';

  @override
  String get systemDefault => 'System Default';

  @override
  String get autoLockTimeout => 'Auto-Lock Timeout';

  @override
  String seconds(int count) {
    return '${count}s';
  }

  @override
  String get importPrompt =>
      'Would you like to import your existing passwords now?';

  @override
  String get importNow => 'IMPORT NOW';

  @override
  String get skip => 'SKIP';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetWithBiometrics => 'Unlock with Biometrics';

  @override
  String get unlockWithFaceID => 'Unlock with Face ID';

  @override
  String get unlockWithTouchID => 'Unlock with Touch ID';

  @override
  String get createNewVault => 'Reset Vault';

  @override
  String get resetWarning =>
      'IMPORTANT: This action cannot be undone!\nAll your data will be permanently deleted.\nAre you sure you want to reset?';

  @override
  String get confirmReset => 'Confirm Reset';

  @override
  String get biometricResetReason => 'Authenticate to unlock';

  @override
  String get vaultResetSuccess =>
      'Vault has been reset. Please create a new master password.';

  @override
  String get noBiometricsAvailable =>
      'No biometrics available. You can only create a new vault.';

  @override
  String get oldVaultBackup =>
      'Old vault has been backed up as vault_backup.db';

  @override
  String get credentials => 'Credentials';

  @override
  String get notSet => 'Not set';

  @override
  String get copyAll => 'COPY ALL';

  @override
  String get allDetailsCopied => 'All details copied to clipboard';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get enlarge => 'Enlarge';

  @override
  String get copy => 'Copy';

  @override
  String get couldNotOpenFile => 'Could not open file';

  @override
  String get aboutDescription =>
      'A minimalist cross-platform password manager.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get passwordResetFailed => 'Failed to reset password';

  @override
  String get incorrectCurrentPassword => 'Incorrect current password';

  @override
  String get importDescription => 'Import passwords from CSV';

  @override
  String get data => 'DATA';

  @override
  String get importHint => 'CSV format: Title/Username/Password/Notes';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get titleHint => 'e.g., Gmail, Netflix';

  @override
  String get usernameHint => 'Username or email';

  @override
  String get passwordHint => 'Password';

  @override
  String get notesHint => 'Additional notes...';

  @override
  String get noAttachments => 'No attachments';

  @override
  String get vertical => 'Vertical';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get copyPassword => 'Copy Password';

  @override
  String importSuccess(int count) {
    return 'Successfully imported $count items';
  }

  @override
  String importFailed(int count) {
    return 'Failed to import $count items';
  }

  @override
  String get importFormatHint =>
      'Supports CSV with headers. Recommended: Chrome, 1Password, Bitwarden export with column headers.';

  @override
  String get importNoHeaderHint =>
      'CSV without headers: Title, URL, Username, Password, Notes order';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Delete $count items?';
  }

  @override
  String get selectItems => 'Select items to delete';

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String get resetVaultTitle => 'Reset Vault?';

  @override
  String get resetVaultWarning =>
      'This will permanently delete all passwords and data on this device. This action cannot be undone.\n\nAre you sure you want to continue?';

  @override
  String get importSmart => 'Smart Import';

  @override
  String get importChrome => 'Google Chrome';

  @override
  String get import1Password => '1Password';

  @override
  String get recommended => 'Recommended';

  @override
  String get securityWarning =>
      'SECURITY WARNING: After import, please DELETE the CSV file immediately. It contains unencrypted passwords.';

  @override
  String get importResult => 'Import Result';

  @override
  String get trayPanelTitle => 'Quick Access';

  @override
  String get openMainWindow => 'Open Main Window';

  @override
  String get exitApp => 'Exit Application';

  @override
  String get recentPasswords => 'Recent Passwords';

  @override
  String get noRecentPasswords => 'No recent passwords';

  @override
  String get quickSearch => 'Quick Search...';

  @override
  String get viewAll => 'View All';

  @override
  String get trayPanelLocked => 'Vault is Locked';

  @override
  String get unlockVault => 'Unlock Vault';

  @override
  String get useBiometricUnlock => 'Use Biometric';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get recentlyUsed => 'Recently Used';

  @override
  String get lockNow => 'Lock Now';

  @override
  String get quickSettings => 'Quick Settings';

  @override
  String get passwordCopied => 'Password Copied';

  @override
  String get sync => 'Sync';

  @override
  String get about => 'About';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get syncSettingsSubtitle => 'Configure WebDAV or iCloud Drive sync';

  @override
  String get appSubtitle => 'Hedgehog';

  @override
  String get newItem => 'New';

  @override
  String get lock => 'Lock';
}
