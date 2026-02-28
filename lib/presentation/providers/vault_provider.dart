import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/platform/sync_service_factory.dart';
import 'package:hedge/services/sync_service.dart';
import 'package:hedge/domain/use_cases/copy_password_usecase.dart';
import 'package:hedge/domain/use_cases/copy_all_credentials_usecase.dart';
import 'package:hedge/domain/services/importer/csv_import_service.dart';
import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/sort_service.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class VaultState {
  final Vault? vault;
  final bool isLoading;
  final String? error;
  final bool hasVaultFile;
  final bool isAuthenticated;
  final String? currentPassword;
  final bool isBiometricsEnabled;
  final String? vaultPath;
  final int autoLockTimeout; // in seconds
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final BiometricType? biometricType;

  VaultState({
    this.vault,
    this.isLoading = false,
    this.error,
    this.hasVaultFile = false,
    this.isAuthenticated = false,
    this.currentPassword,
    this.isBiometricsEnabled = false,
    this.vaultPath,
    this.autoLockTimeout = 5,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.biometricType,
  });

  VaultState copyWith({
    Vault? vault,
    bool? isLoading,
    String? error,
    bool? hasVaultFile,
    bool? isAuthenticated,
    String? currentPassword,
    bool? isBiometricsEnabled,
    String? vaultPath,
    int? autoLockTimeout,
    bool? isSelectionMode,
    Set<String>? selectedIds,
    BiometricType? biometricType,
  }) {
    return VaultState(
      vault: vault ?? this.vault,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasVaultFile: hasVaultFile ?? this.hasVaultFile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentPassword: currentPassword ?? this.currentPassword,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      vaultPath: vaultPath ?? this.vaultPath,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      biometricType: biometricType ?? this.biometricType,
    );
  }
}


class VaultNotifier extends StateNotifier<VaultState> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final SyncService _syncService = SyncServiceFactory.getService();
  StreamSubscription? _syncSubscription;
  DateTime? _lastKnownModification;

  // Use Cases
  final _copyPasswordUseCase = CopyPasswordUseCase();
  final _copyAllCredentialsUseCase = CopyAllCredentialsUseCase();
  
  // Services
  final _importService = CsvImportService();

  VaultNotifier() : super(VaultState(isLoading: true));

  Future<void> checkInitialStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final path = await _getDefaultVaultPath();
      final exists = await File(path).exists();
      
      if (exists) {
        final file = File(path);
        _lastKnownModification = await file.lastModified();
      }
      
      final bioEnabled = await _storage.read(key: 'bio_enabled') == 'true';
      final timeoutStr = await _storage.read(key: 'auto_lock_timeout');
      final timeout = timeoutStr != null ? int.tryParse(timeoutStr) ?? 5 : 5;
      
      // Detect biometric type
      final biometricType = await _detectBiometricType();
      
      state = state.copyWith(
        hasVaultFile: exists, 
        isBiometricsEnabled: bioEnabled,
        vaultPath: path,
        autoLockTimeout: timeout,
        isLoading: false,
        biometricType: biometricType,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<BiometricType?> _detectBiometricType() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      }
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      // For other types like strong/weak, default to fingerprint if available, else null
      if (availableBiometrics.isNotEmpty) {
        return BiometricType.fingerprint; // Fallback
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await _storage.write(key: 'auto_lock_timeout', value: seconds.toString());
    state = state.copyWith(autoLockTimeout: seconds);
  }

  Future<String> _getDefaultVaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    // Use a specific filename. On iOS/macOS, files in 'Documents' are 
    // automatically synced to iCloud if the app is configured.
    return '${directory.path}/vault.db';
  }

  Future<void> setVaultPath(String path) async {
    await _storage.write(key: 'vault_path', value: path);
    final exists = await File(path).exists();
    state = state.copyWith(vaultPath: path, hasVaultFile: exists);
  }

  Future<bool> setupVault(String masterPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vault = VaultService.createEmptyVault();
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await VaultService.saveVault(path, masterPassword, vault);

      await _storage.write(key: 'master_password', value: masterPassword);
      await _storage.write(key: 'bio_enabled', value: 'true');
      await _storage.write(key: 'vault_path', value: path);
      
      await _startSyncWatch(path, masterPassword);

      state = state.copyWith(
        vault: vault,
        isLoading: false,
        isAuthenticated: true,
        hasVaultFile: true,
        currentPassword: masterPassword,
        isBiometricsEnabled: true,
        vaultPath: path,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Setup failed: $e");
      return false;
    }
  }

  Future<bool> unlockVault(String masterPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      final vault = await VaultService.loadVault(path, masterPassword);

      await _storage.write(key: 'master_password', value: masterPassword);
      await _storage.write(key: 'vault_path', value: path);
      
      // Start watching for file changes
      await _startSyncWatch(path, masterPassword);

      state = state.copyWith(
        vault: vault,
        isLoading: false,
        isAuthenticated: true,
        currentPassword: masterPassword,
        vaultPath: path,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Incorrect master password");
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        state = state.copyWith(error: "Device does not support biometrics");
        return false;
      }
      
      final canCheckBio = await _localAuth.canCheckBiometrics;
      if (!canCheckBio) {
        state = state.copyWith(error: "Biometrics not enrolled or available");
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock NotePassword',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final masterPassword = await _storage.read(key: 'master_password');
        if (masterPassword != null) {
          return await unlockVault(masterPassword);
        } else {
          state = state.copyWith(error: "No master password stored for biometrics");
        }
      }
      return false;
    } catch (e) {
      String errorMessage = "Biometric error";
      final errorStr = e.toString();
      if (errorStr.contains("NotEnrolled")) {
        errorMessage = "No biometrics enrolled on this device.";
      } else if (errorStr.contains("LockedOut") || errorStr.contains("locked_out")) {
        errorMessage = "Biometrics locked out. Please use password.";
      } else if (errorStr.contains("PasscodeNotSet")) {
        errorMessage = "No passcode set on device.";
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> resetVaultWithBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBio = await _localAuth.canCheckBiometrics;
      
      if (!isSupported || !canCheckBio) {
        state = state.copyWith(error: "Biometrics not available on this device");
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to reset your vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await resetVaultCompletely();
        return true;
      }
      return false;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains("-34018")) {
        errorMessage = "macOS security error. Please use 'Create New Vault' button instead, or configure code signing in Xcode.";
      } else if (e.toString().contains("NotEnrolled")) {
        errorMessage = "No biometrics enrolled on this device.";
      } else if (e.toString().contains("LockedOut")) {
        errorMessage = "Biometrics locked out. Please use 'Create New Vault' button.";
      } else {
        errorMessage = "Biometric error: $e";
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> resetMasterPassword(String currentPassword, String newPassword) async {
    if (state.vault == null || !state.isAuthenticated) {
      state = state.copyWith(error: "vault_not_unlocked");
      return false;
    }

    if (state.currentPassword != currentPassword) {
      state = state.copyWith(error: "incorrect_current_password");
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      final vault = state.vault!;
      
      await VaultService.saveVault(state.vaultPath!, state.currentPassword!, vault);

      await _storage.write(key: 'master_password', value: newPassword);
      
      state = state.copyWith(
        currentPassword: newPassword,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "reset_password_failed");
      return false;
    }
  }

  Future<void> resetVaultCompletely() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      final vaultFile = File(path);
      
      if (await vaultFile.exists()) {
        final backupPath = '${vaultFile.parent.path}/vault_backup.db';
        await vaultFile.copy(backupPath);
        await vaultFile.delete();
      }
      
      await _storage.deleteAll();
      
      state = VaultState(
        hasVaultFile: false,
        isBiometricsEnabled: false,
        vaultPath: path,
        autoLockTimeout: 5,
      );
      checkInitialStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Reset failed: $e");
    }
  }

  Future<void> toggleBiometrics(bool enabled) async {
    if (enabled) {
      // Try to authenticate once to make sure it works before enabling
      final success = await _localAuth.authenticate(
        localizedReason: 'Confirm biometrics to enable',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!success) return;
    }
    
    await _storage.write(key: 'bio_enabled', value: enabled.toString());
    state = state.copyWith(isBiometricsEnabled: enabled);
  }

  Future<void> addItem(String title) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.addItem(state.vault!, title);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addItemWithDetails(VaultItem item) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      // 直接添加完整的 item，而不是先添加再更新
      final newVault = VaultService.addItemWithDetails(state.vault!, item);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateItem(VaultItem updatedItem) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.updateItem(state.vault!, updatedItem);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteItem(String id) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.deleteItem(state.vault!, id);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveAndRefresh(Vault newVault) async {
    final path = state.vaultPath ?? await _getDefaultVaultPath();
    await VaultService.saveVault(path, state.currentPassword!, newVault);
    // Update last known modification time
    final file = File(path);
    if (await file.exists()) {
      _lastKnownModification = await file.lastModified();
    }
    state = state.copyWith(vault: newVault, isLoading: false);
  }

  Future<void> _startSyncWatch(String path, String masterPassword) async {
    // Cancel any existing subscription
    await _syncSubscription?.cancel();
    
    // Start watching for file changes
    await _syncService.startWatching(path, masterPassword: masterPassword);
    
      // Listen for file changes
      _syncSubscription = _syncService.onFileChanged.listen((event) async {
        if (!state.isAuthenticated || state.currentPassword == null) return;
      
      // Check if this is our own change (by comparing modification time)
      final file = File(path);
      if (!await file.exists()) return;
      
      final currentMod = await file.lastModified();
      if (_lastKnownModification != null && 
          currentMod.difference(_lastKnownModification!).inMilliseconds < 500) {
        // This is likely our own change, ignore
        return;
      }
      
      // Check for conflict
      final hasConflict = await _syncService.hasConflict(path);
      if (hasConflict) {
        // Create a backup if there's a conflict
        await _syncService.createConflictBackup(path);
      }
      
      // Reload vault from file
      try {
        final vault = await VaultService.loadVault(state.vaultPath!, state.currentPassword!);
        state = state.copyWith(vault: vault);
        _lastKnownModification = currentMod;
      } catch (e) {
        // Failed to reload, ignore
      }
    });
  }

  Future<void> _stopSyncWatch() async {
    await _syncSubscription?.cancel();
    _syncSubscription = null;
    await _syncService.stopWatching();
  }

  void lock() {
    _stopSyncWatch();
    state = state.copyWith(
      vault: null,
      isAuthenticated: false,
      currentPassword: null,
      isSelectionMode: false,
      selectedIds: {},
    );
  }

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void toggleItemSelection(String id) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  Future<void> deleteSelectedItems() async {
    if (state.vault == null || state.currentPassword == null || state.selectedIds.isEmpty) return;
    
    state = state.copyWith(isLoading: true);
    try {
      var currentVault = state.vault!;
      for (final id in state.selectedIds) {
        currentVault = VaultService.deleteItem(currentVault, id);
      }
      await _saveAndRefresh(currentVault);
      state = state.copyWith(isSelectionMode: false, selectedIds: {});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  VaultItem? findItem(String id) {
    return state.vault?.items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item not found'),
    );
  }

  List<VaultItem> get sortedItems {
    final items = state.vault?.items ?? [];
    return SortService.sort(items);
  }

  void copyPassword(String itemId) {
    final item = findItem(itemId);
    if (item == null) return;
    final password = _copyPasswordUseCase.execute(item);
    Clipboard.setData(ClipboardData(text: password));
  }

  void copyAllCredentials(String itemId, AppLocalizations l10n) {
    final item = findItem(itemId);
    if (item == null) return;
    final parts = _copyAllCredentialsUseCase.execute(item);

    final buffer = StringBuffer();
    if (parts.username != null && parts.username!.isNotEmpty) {
      buffer.writeln('${l10n.username}: ${parts.username}');
    }
    if (parts.password != null && parts.password!.isNotEmpty) {
      buffer.writeln('${l10n.password}: ${parts.password}');
    }
    if (parts.url != null && parts.url!.isNotEmpty) {
      buffer.writeln('${l10n.url}: ${parts.url}');
    }
    if (parts.notes != null && parts.notes!.isNotEmpty) {
      buffer.writeln('${l10n.notes}:\n${parts.notes}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
  }

  Future<ImportResult> importFromCsv(String csvContent, {ImportStrategy? strategy}) async {
    if (state.vault == null || state.currentPassword == null) {
      return ImportResult(success: 0, failed: 0);
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Use the service to parse content with the provided strategy (or smart default)
      // Note: We create a new service instance or update the existing one's strategy if needed.
      // But CsvImportService now takes strategy in import() method if we refactored it that way?
      // Wait, CsvImportService constructor takes strategy.
      // Let's instantiate a fresh service for this specific import operation to keeps things clean.
      final service = CsvImportService(strategy: strategy);
      final result = await service.import(csvContent);
      
      if (result.items.isNotEmpty) {
        var currentVault = state.vault!;
        
        // Add all imported items
        for (final item in result.items) {
           currentVault = VaultService.addItemWithDetails(currentVault, item);
        }
        
        await _saveAndRefresh(currentVault);
      }
      
      return result;
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Import failed: ${e.toString()}");
      // Return a failed result
      return ImportResult(success: 0, failed: 1);
    }
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier();
});
