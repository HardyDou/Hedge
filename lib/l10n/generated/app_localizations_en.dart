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
  String get appSubtitle => 'Hedge';

  @override
  String get newItem => 'New';

  @override
  String get lock => 'Lock';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get Started';

  @override
  String get introSecureTitle => 'Secure Encryption';

  @override
  String get introSecureDesc =>
      'AES-256 encryption protects your passwords and keeps your data safe';

  @override
  String get introSyncTitle => 'WebDAV Sync';

  @override
  String get introSyncDesc =>
      'Sync across devices seamlessly with WebDAV cloud storage';

  @override
  String get introCrossTitle => 'Cross-Platform';

  @override
  String get introCrossDesc =>
      'Available on iOS, macOS and more - manage passwords anywhere';

  @override
  String get introPrivacyTitle => 'Privacy First';

  @override
  String get introPrivacyDesc =>
      'All data encrypted locally - your passwords belong to you alone';

  @override
  String get viewIntroduction => 'Feature Introduction';

  @override
  String get viewIntroductionDesc => 'View app feature introduction';

  @override
  String get splashScreen => 'Splash Screen';

  @override
  String get splashScreenDesc => 'View startup loading screen';

  @override
  String get totp => 'Verification Code';

  @override
  String get totpCode => 'Code';

  @override
  String get addTotp => 'Add Verification Code';

  @override
  String get editTotp => 'Edit Verification Code';

  @override
  String get deleteTotp => 'Delete Verification Code';

  @override
  String get deleteTotpConfirm =>
      'Are you sure you want to delete the verification code?';

  @override
  String get totpSecret => 'Secret Key';

  @override
  String get totpIssuer => 'Issuer';

  @override
  String get totpIssuerHint => 'e.g., Google, GitHub';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get invalidSecret => 'Invalid Secret Key';

  @override
  String get secretFormatError =>
      'Secret Key should be Base32 encoded (16-32 characters)';

  @override
  String get totpCopied => 'Verification code copied';

  @override
  String get totpGenerationFailed => 'Failed to generate verification code';

  @override
  String get qrCodeScanFailed => 'Failed to scan QR code';

  @override
  String get qrCodeFormatError => 'QR code format is incorrect';

  @override
  String get timeNotSynced =>
      'System time may be inaccurate, verification code may be invalid';

  @override
  String totpRemainingSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get scanFailed => 'Scan Failed';

  @override
  String get invalidQrCode => 'Invalid QR code, please scan a TOTP QR code';

  @override
  String get ok => 'OK';

  @override
  String get scanQrCodeHint =>
      'Place the QR code within the frame to scan automatically';

  @override
  String get error => 'Error';

  @override
  String get addTotpHint => 'Select an image containing a TOTP QR code';

  @override
  String get processing => 'Processing...';

  @override
  String get selectImage => 'Select Image';

  @override
  String get manualInputHint =>
      'Image recognition not supported yet, please enter TOTP Secret manually';

  @override
  String get passwordGenerator => 'Password Generator';

  @override
  String get generate => 'Generate';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get useThisPassword => 'Use This Password';

  @override
  String get generatedPassword => 'Generated Password';

  @override
  String get passwordStrength => 'Password Strength';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthMedium => 'Medium';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get strengthVeryStrong => 'Very Strong';

  @override
  String get passwordLength => 'Length';

  @override
  String get includeUppercase => 'Uppercase (A-Z)';

  @override
  String get includeLowercase => 'Lowercase (a-z)';

  @override
  String get includeNumbers => 'Numbers (0-9)';

  @override
  String get includeSymbols => 'Symbols (!@#\$...)';

  @override
  String get excludeAmbiguous => 'Exclude Ambiguous Characters';

  @override
  String get excludeAmbiguousHint => 'Exclude 0/O, 1/l/I';

  @override
  String get passwordCopiedToClipboard => 'Password copied to clipboard';

  @override
  String get atLeastOneCharType => 'Select at least one character type';

  @override
  String get suggestionIncreaseLength => 'Increase length to 12+ characters';

  @override
  String get suggestionAddSymbols => 'Add special symbols';

  @override
  String get suggestionMoreTypes => 'Use more character types';

  @override
  String get suggestionGood => 'Password strength is good';

  @override
  String get use => 'Use';

  @override
  String get config => 'Config';
}
