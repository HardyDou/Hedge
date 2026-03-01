import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Vault'**
  String get appTitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK'**
  String get unlock;

  /// No description provided for @enterMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Master Password'**
  String get enterMasterPassword;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect master password'**
  String get incorrectPassword;

  /// No description provided for @myVault.
  ///
  /// In en, this message translates to:
  /// **'My Passwords'**
  String get myVault;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'ADD PASSWORD'**
  String get addPassword;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get deleteEntry;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @noPasswords.
  ///
  /// In en, this message translates to:
  /// **'No passwords yet. Tap + to add.'**
  String get noPasswords;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String copied(String label);

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @createVault.
  ///
  /// In en, this message translates to:
  /// **'CREATE VAULT'**
  String get createVault;

  /// No description provided for @onboardingSub.
  ///
  /// In en, this message translates to:
  /// **'Create a strong master password to encrypt your personal vault.'**
  String get onboardingSub;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'STORAGE LOCATION'**
  String get storageLocation;

  /// No description provided for @defaultLocal.
  ///
  /// In en, this message translates to:
  /// **'Default (Local Only)'**
  String get defaultLocal;

  /// No description provided for @syncTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Choose a folder in iCloud Drive or Xiaomi/Huawei Cloud to sync across devices.'**
  String get syncTip;

  /// No description provided for @recoveryWarning.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: If you forget this password, your data cannot be recovered. We do not store it on any server.'**
  String get recoveryWarning;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS'**
  String get attachments;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add Certificate/File'**
  String get addFile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @vaultPath.
  ///
  /// In en, this message translates to:
  /// **'Vault Path'**
  String get vaultPath;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get confirmDelete;

  /// No description provided for @cancelCaps.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelCaps;

  /// No description provided for @deleteCaps.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteCaps;

  /// No description provided for @saveCaps.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveCaps;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @autoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get autoLockTimeout;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String seconds(int count);

  /// No description provided for @importPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to import your existing passwords now?'**
  String get importPrompt;

  /// No description provided for @importNow.
  ///
  /// In en, this message translates to:
  /// **'IMPORT NOW'**
  String get importNow;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometrics'**
  String get resetWithBiometrics;

  /// No description provided for @unlockWithFaceID.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID'**
  String get unlockWithFaceID;

  /// No description provided for @unlockWithTouchID.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Touch ID'**
  String get unlockWithTouchID;

  /// No description provided for @createNewVault.
  ///
  /// In en, this message translates to:
  /// **'Reset Vault'**
  String get createNewVault;

  /// No description provided for @resetWarning.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: This action cannot be undone!\nAll your data will be permanently deleted.\nAre you sure you want to reset?'**
  String get resetWarning;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset'**
  String get confirmReset;

  /// No description provided for @biometricResetReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock'**
  String get biometricResetReason;

  /// No description provided for @vaultResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vault has been reset. Please create a new master password.'**
  String get vaultResetSuccess;

  /// No description provided for @noBiometricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No biometrics available. You can only create a new vault.'**
  String get noBiometricsAvailable;

  /// No description provided for @oldVaultBackup.
  ///
  /// In en, this message translates to:
  /// **'Old vault has been backed up as vault_backup.db'**
  String get oldVaultBackup;

  /// No description provided for @credentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentials;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'COPY ALL'**
  String get copyAll;

  /// No description provided for @allDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'All details copied to clipboard'**
  String get allDetailsCopied;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @enlarge.
  ///
  /// In en, this message translates to:
  /// **'Enlarge'**
  String get enlarge;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get couldNotOpenFile;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A minimalist cross-platform password manager.'**
  String get aboutDescription;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get passwordResetFailed;

  /// No description provided for @incorrectCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password'**
  String get incorrectCurrentPassword;

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'Import passwords from CSV'**
  String get importDescription;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get data;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'CSV format: Title/Username/Password/Notes'**
  String get importHint;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Gmail, Netflix'**
  String get titleHint;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes...'**
  String get notesHint;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get noAttachments;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// No description provided for @copyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get copyPassword;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} items'**
  String importSuccess(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import {count} items'**
  String importFailed(int count);

  /// No description provided for @importFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Supports CSV with headers. Recommended: Chrome, 1Password, Bitwarden export with column headers.'**
  String get importFormatHint;

  /// No description provided for @importNoHeaderHint.
  ///
  /// In en, this message translates to:
  /// **'CSV without headers: Title, URL, Username, Password, Notes order'**
  String get importNoHeaderHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @deleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items?'**
  String deleteSelectedConfirm(int count);

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select items to delete'**
  String get selectItems;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);

  /// No description provided for @resetVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Vault?'**
  String get resetVaultTitle;

  /// No description provided for @resetVaultWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all passwords and data on this device. This action cannot be undone.\n\nAre you sure you want to continue?'**
  String get resetVaultWarning;

  /// No description provided for @importSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart Import'**
  String get importSmart;

  /// No description provided for @importChrome.
  ///
  /// In en, this message translates to:
  /// **'Google Chrome'**
  String get importChrome;

  /// No description provided for @import1Password.
  ///
  /// In en, this message translates to:
  /// **'1Password'**
  String get import1Password;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @securityWarning.
  ///
  /// In en, this message translates to:
  /// **'SECURITY WARNING: After import, please DELETE the CSV file immediately. It contains unencrypted passwords.'**
  String get securityWarning;

  /// No description provided for @importResult.
  ///
  /// In en, this message translates to:
  /// **'Import Result'**
  String get importResult;

  /// No description provided for @trayPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get trayPanelTitle;

  /// No description provided for @openMainWindow.
  ///
  /// In en, this message translates to:
  /// **'Open Main Window'**
  String get openMainWindow;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitApp;

  /// No description provided for @recentPasswords.
  ///
  /// In en, this message translates to:
  /// **'Recent Passwords'**
  String get recentPasswords;

  /// No description provided for @noRecentPasswords.
  ///
  /// In en, this message translates to:
  /// **'No recent passwords'**
  String get noRecentPasswords;

  /// No description provided for @quickSearch.
  ///
  /// In en, this message translates to:
  /// **'Quick Search...'**
  String get quickSearch;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @trayPanelLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault is Locked'**
  String get trayPanelLocked;

  /// No description provided for @unlockVault.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vault'**
  String get unlockVault;

  /// No description provided for @useBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometricUnlock;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @recentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently Used'**
  String get recentlyUsed;

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock Now'**
  String get lockNow;

  /// No description provided for @quickSettings.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get quickSettings;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password Copied'**
  String get passwordCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
