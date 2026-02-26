import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:note_password/src/rust/api/model.dart';
import 'package:note_password/src/rust/api/vault.dart' as rust_vault;
import 'package:note_password/platform/sync_service_factory.dart';
import 'package:note_password/services/sync_service.dart';
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
    );
  }
}

class ImportResult {
  final int success;
  final int failed;
  
  ImportResult({required this.success, required this.failed});
}

class VaultNotifier extends StateNotifier<VaultState> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final SyncService _syncService = SyncServiceFactory.getService();
  StreamSubscription? _syncSubscription;
  DateTime? _lastKnownModification;

  VaultNotifier() : super(VaultState());

  Future<void> checkInitialStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      // Always ensure we have a path set automatically
      final path = await _getDefaultVaultPath();
      final exists = await File(path).exists();
      
      // Get file modification time if exists
      if (exists) {
        final file = File(path);
        _lastKnownModification = await file.lastModified();
      }
      
      final bioEnabled = await _storage.read(key: 'bio_enabled') == 'true';
      final timeoutStr = await _storage.read(key: 'auto_lock_timeout');
      final timeout = timeoutStr != null ? int.tryParse(timeoutStr) ?? 5 : 5;
      
      state = state.copyWith(
        hasVaultFile: exists, 
        isBiometricsEnabled: bioEnabled,
        vaultPath: path,
        autoLockTimeout: timeout,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
      final vault = await rust_vault.createEmptyVault();
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      
      // Ensure the parent directory exists (especially critical on iOS/Android)
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await rust_vault.saveVault(
        path: path,
        masterPassword: masterPassword,
        vault: vault,
      );

      await _storage.write(key: 'master_password', value: masterPassword);
      await _storage.write(key: 'bio_enabled', value: 'true');
      await _storage.write(key: 'vault_path', value: path);
      
      // Start watching for file changes
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
      final vault = await rust_vault.loadVault(
        path: path,
        masterPassword: masterPassword,
      );

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
      
      await rust_vault.saveVault(
        path: path,
        masterPassword: newPassword,
        vault: vault,
      );

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
      }
      
      await _storage.deleteAll();
      
      state = VaultState(
        hasVaultFile: false,
        isBiometricsEnabled: false,
        vaultPath: path,
        autoLockTimeout: 5,
      );
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
      final newVault = await rust_vault.addItem(vault: state.vault!, title: title);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addItemWithDetails(VaultItem item) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      // Since Rust's addItem only takes title, we manually add to the list
      // Or we can add an 'addItemFull' to Rust.
      // Let's just use the existing update logic after adding.
      final newVaultWithTitle = await rust_vault.addItem(vault: state.vault!, title: item.title);
      final lastItem = newVaultWithTitle.items.last;
      
      final fullItem = VaultItem(
        id: lastItem.id,
        title: item.title,
        username: item.username,
        password: item.password,
        url: item.url,
        notes: item.notes,
        category: item.category,
        attachments: item.attachments,
        updatedAt: item.updatedAt,
      );

      final finalVault = await rust_vault.updateItem(
        vault: newVaultWithTitle,
        updatedItem: fullItem,
      );
      
      await _saveAndRefresh(finalVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateItem(VaultItem updatedItem) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final newVault = await rust_vault.updateItem(
        vault: state.vault!, 
        updatedItem: updatedItem
      );
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteItem(String id) async {
    if (state.vault == null || state.currentPassword == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final newVault = await rust_vault.deleteItem(vault: state.vault!, id: id);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveAndRefresh(Vault newVault) async {
    final path = state.vaultPath ?? await _getDefaultVaultPath();
    await rust_vault.saveVault(
      path: path,
      masterPassword: state.currentPassword!,
      vault: newVault,
    );
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
        print('[iCloud Sync] File changed event received: ${event.type}');
        
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
        final vault = await rust_vault.loadVault(
          path: path,
          masterPassword: masterPassword,
        );
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
        currentVault = await rust_vault.deleteItem(vault: currentVault, id: id);
      }
      await _saveAndRefresh(currentVault);
      state = state.copyWith(isSelectionMode: false, selectedIds: {});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ImportResult> importFromCsv(String csvContent) async {
    if (state.vault == null || state.currentPassword == null) {
      return ImportResult(success: 0, failed: 0);
    }
    
    state = state.copyWith(isLoading: true, error: null);
    var successCount = 0;
    var failedCount = 0;
    
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) return ImportResult(success: 0, failed: 0);

      var currentVault = state.vault!;
      
      // 1. Detect if CSV has headers
      final firstLine = lines[0].trim();
      var hasHeaders = _detectHasHeaders(firstLine);
      
      Map<String, int> indexMap = {};
      
      if (hasHeaders) {
        // Parse headers
        final headerLine = firstLine.toLowerCase();
        final headers = _parseCsvLine(headerLine);
        for (int i = 0; i < headers.length; i++) {
          final header = headers[i].trim().replaceAll('"', '');
          if (header.contains('title') || header.contains('name')) indexMap['title'] = i;
          if (header.contains('username') || header.contains('email')) indexMap['username'] = i;
          if (header.contains('password') || header.contains('pass')) indexMap['password'] = i;
          if (header.contains('url') || header.contains('website') || header.contains('site')) indexMap['url'] = i;
          if (header.contains('notes') || header.contains('note') || header.contains('comment')) indexMap['notes'] = i;
        }
        
        if (!indexMap.containsKey('title')) {
          // No title found, try without headers
          hasHeaders = false;
        }
      }
      
      // 2. Parse rows
      final startIndex = hasHeaders ? 1 : 0;
      
      for (var i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          final fields = _parseCsvLine(line);
          if (fields.isEmpty) continue;
          
          String title;
          String? username;
          String? password;
          String? url;
          String? notes;
          
          if (hasHeaders && indexMap.containsKey('title')) {
            // Use header mapping
            if (fields.length <= indexMap['title']!) continue;
            title = fields[indexMap['title']!];
            if (title.isEmpty) continue;
            
            username = indexMap.containsKey('username') && fields.length > indexMap['username']! 
                ? fields[indexMap['username']!] : null;
            password = indexMap.containsKey('password') && fields.length > indexMap['password']! 
                ? fields[indexMap['password']!] : null;
            url = indexMap.containsKey('url') && fields.length > indexMap['url']! 
                ? fields[indexMap['url']!] : null;
            notes = indexMap.containsKey('notes') && fields.length > indexMap['notes']! 
                ? fields[indexMap['notes']!] : null;
          } else {
            // No headers: use default order (Title, URL, Username, Password, Notes)
            title = fields.isNotEmpty ? fields[0] : '';
            if (title.isEmpty) continue;
            
            url = fields.length > 1 && fields[1].isNotEmpty ? fields[1] : null;
            username = fields.length > 2 && fields[2].isNotEmpty ? fields[2] : null;
            password = fields.length > 3 && fields[3].isNotEmpty ? fields[3] : null;
            notes = fields.length > 4 && fields[4].isNotEmpty ? fields[4] : null;
          }

          final item = VaultItem(
            id: "",
            title: title,
            username: username,
            password: password,
            url: url,
            notes: notes,
            category: null,
            attachments: [],
            updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          final newVaultWithTitle = await rust_vault.addItem(vault: currentVault, title: item.title);
          final lastItem = newVaultWithTitle.items.last;
          
          final fullItem = VaultItem(
            id: lastItem.id,
            title: item.title,
            username: item.username,
            password: item.password,
            url: item.url,
            notes: item.notes,
            category: item.category,
            attachments: item.attachments,
            updatedAt: item.updatedAt,
          );

          currentVault = await rust_vault.updateItem(
            vault: newVaultWithTitle,
            updatedItem: fullItem,
          );
          successCount++;
        } catch (e) {
          failedCount++;
        }
      }

      await _saveAndRefresh(currentVault);
      return ImportResult(success: successCount, failed: failedCount);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Import failed: ${e.toString()}");
      return ImportResult(success: successCount, failed: failedCount + 1);
    }
  }
  
  bool _detectHasHeaders(String firstLine) {
    // Heuristics: if first line contains common field names, it's likely a header
    final lower = firstLine.toLowerCase();
    final hasTitle = lower.contains('title') || lower.contains('name');
    final hasUsername = lower.contains('username') || lower.contains('email') || lower.contains('user');
    final hasPassword = lower.contains('password') || lower.contains('pass');
    final hasUrl = lower.contains('url') || lower.contains('website') || lower.contains('http');
    
    // If at least 2 common field names found, assume it's a header
    int matchCount = 0;
    if (hasTitle) matchCount++;
    if (hasUsername) matchCount++;
    if (hasPassword) matchCount++;
    if (hasUrl) matchCount++;
    
    return matchCount >= 2;
  }

  List<String> _parseCsvLine(String line) {
    // Simple CSV parser that handles basic quotes
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.toString().trim());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    result.add(currentField.toString().trim());
    return result;
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier();
});
