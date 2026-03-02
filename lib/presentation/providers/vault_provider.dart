import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hedge/src/dart/vault.dart';
import 'package:hedge/platform/sync_service_factory.dart';
import 'package:hedge/services/sync_service.dart';
import 'package:hedge/domain/use_cases/copy_password_usecase.dart';
import 'package:hedge/domain/use_cases/copy_all_credentials_usecase.dart';
import 'package:hedge/domain/use_cases/search_vault_items_usecase.dart';
import 'package:hedge/domain/services/importer/csv_import_service.dart';
import 'package:hedge/domain/services/importer/import_strategy.dart';
import 'package:hedge/domain/services/sort_service.dart';
import 'package:hedge/domain/models/sync_config.dart';
import 'package:hedge/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for compute function

// Top-level function required by compute()
Future<List<VaultItem>> _searchVaultItemsInIsolate(Map<String, dynamic> params) async {
  final query = params['query'] as String;
  final items = params['items'] as List<VaultItem>;
  final useCase = SearchVaultItemsUseCase();
  return useCase.execute(query, items);
}

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
  final List<VaultItem>? filteredVaultItems;
  final SyncMode syncMode;
  final WebDAVConfig? webdavConfig;

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
    this.filteredVaultItems = const [],
    this.syncMode = SyncMode.local,
    this.webdavConfig,
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
    List<VaultItem>? filteredVaultItems,
    SyncMode? syncMode,
    WebDAVConfig? webdavConfig,
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
      filteredVaultItems: filteredVaultItems ?? this.filteredVaultItems,
      syncMode: syncMode ?? this.syncMode,
      webdavConfig: webdavConfig ?? this.webdavConfig,
    );
  }
}


class VaultNotifier extends StateNotifier<VaultState> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final SyncService _syncService = SyncServiceFactory.getService();
  StreamSubscription? _syncSubscription;
  DateTime? _lastKnownModification;
  String _currentSearchQuery = ""; // Add this line

  // Use Cases
  final _copyPasswordUseCase = CopyPasswordUseCase();
  final _copyAllCredentialsUseCase = CopyAllCredentialsUseCase();

  Future<void> searchItems(String query) async {
    debugPrint('🔍 searchItems 被调用: query="$query", vault=${state.vault != null}, items=${state.vault?.items.length ?? 0}');
    _currentSearchQuery = query;
    final currentVaultState = state;
    if (currentVaultState.vault == null) {
      debugPrint('⚠️ vault 为 null，返回空列表');
      state = state.copyWith(filteredVaultItems: []);
      return;
    }

    if (query.isEmpty) {
      final sorted = SortService.sort(currentVaultState.vault!.items);
      debugPrint('✅ 空查询，返回所有项目: ${sorted.length} 个');
      state = state.copyWith(
        filteredVaultItems: sorted,
      );
      return;
    }

    final filtered = await compute(
      _searchVaultItemsInIsolate,
      {
        'query': query,
        'items': currentVaultState.vault!.items,
      },
    );
    debugPrint('✅ 搜索完成，返回 ${filtered.length} 个结果');
    state = state.copyWith(filteredVaultItems: filtered);
  }



  VaultNotifier() : super(VaultState(isLoading: true, filteredVaultItems: []));

Future<void> checkInitialStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      // 加载同步配置
      await _loadSyncConfig();

      // 检查 iCloud Drive 是否可用
      final iCloudAvailable = await isICloudDriveAvailable();

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
        filteredVaultItems: [], // Initialize empty, will be populated on unlock/setup
      );

      // 显示同步状态
      print('[Vault] Sync mode: ${state.syncMode.name}');
      if (iCloudAvailable && state.syncMode == SyncMode.icloud) {
        print('[Vault] Using iCloud Drive: $path');
      } else if (state.syncMode == SyncMode.webdav) {
        print('[Vault] Using WebDAV: ${state.webdavConfig?.serverUrl}');
      } else {
        print('[Vault] Using local storage: $path');
      }
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

  /// 获取 iCloud Drive 路径
  static Future<String?> _getICloudDrivePath() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return null;
    }

    try {
      // iOS/macOS iCloud Drive 路径
      final home = Platform.environment['HOME'];
      if (home == null) return null;

      final iCloudDrivePath = '$home/Library/Mobile Documents/com~apple~CloudDocs';
      final iCloudDir = Directory(iCloudDrivePath);

      // 检查 iCloud Drive 是否可用
      if (await iCloudDir.exists()) {
        // 创建应用专属文件夹
        final appFolder = Directory('$iCloudDrivePath/Hedge');
        if (!await appFolder.exists()) {
          await appFolder.create(recursive: true);
        }

        print('[iCloud Drive] Path: ${appFolder.path}');
        return appFolder.path;
      } else {
        print('[iCloud Drive] Not available');
        return null;
      }
    } catch (e) {
      print('[iCloud Drive] Error: $e');
      return null;
    }
  }

  /// 检查 iCloud Drive 是否可用
  static Future<bool> isICloudDriveAvailable() async {
    final path = await _getICloudDrivePath();
    return path != null;
  }

  static Future<String> _getDefaultVaultPath() async {
    // iOS/macOS: 优先使用 iCloud Drive
    if (Platform.isIOS || Platform.isMacOS) {
      final iCloudPath = await _getICloudDrivePath();
      if (iCloudPath != null) {
        return '$iCloudPath/vault.db';
      } else {
        print('[Vault] iCloud Drive not available, using local storage');
      }
    }

    // Fallback: 使用本地 Documents 目录
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/vault.db';
  }

  Future<void> setVaultPath(String path) async {
    await _storage.write(key: 'vault_path', value: path);
    final exists = await File(path).exists();
    state = state.copyWith(vaultPath: path, hasVaultFile: exists);
  }

Future<bool> setupVault(String masterPassword) async {
    final vaultState = state;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vault = VaultService.createEmptyVault();
      final path = vaultState.vaultPath ?? await _getDefaultVaultPath();

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
        filteredVaultItems: SortService.sort(vault?.items ?? []),
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
        filteredVaultItems: SortService.sort(vault?.items ?? []),
      );

      // 检查是否有待同步的数据
      _checkAndUploadPendingSync();

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
    final vaultState = state;
    if (vaultState.vault == null || !vaultState.isAuthenticated) {
      state = state.copyWith(error: "vault_not_unlocked");
      return false;
    }

    if (vaultState.currentPassword != currentPassword) {
      state = state.copyWith(error: "incorrect_current_password");
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = vaultState.vaultPath ?? await _getDefaultVaultPath();
      final vault = vaultState.vault!;
      
      await VaultService.saveVault(vaultState.vaultPath!, vaultState.currentPassword!, vault);

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
    final vaultState = state;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = vaultState.vaultPath ?? await _getDefaultVaultPath();
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
        filteredVaultItems: [],
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
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.addItem(vaultState.vault!, title);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

Future<void> addItemWithDetails(VaultItem item) async {
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.addItemWithDetails(vaultState.vault!, item);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

Future<void> updateItem(VaultItem updatedItem) async {
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.updateItem(vaultState.vault!, updatedItem);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

Future<void> deleteItem(String id) async {
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final newVault = VaultService.deleteItem(vaultState.vault!, id);
      await _saveAndRefresh(newVault);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveAndRefresh(Vault newVault) async {
    final vaultState = state;
    final path = vaultState.vaultPath ?? await _getDefaultVaultPath();
    await VaultService.saveVault(path, vaultState.currentPassword!, newVault);
    // Update last known modification time
    final file = File(path);
    if (await file.exists()) {
      _lastKnownModification = await file.lastModified();
    }
    state = state.copyWith(vault: newVault, isLoading: false);
    // Re-run search with current query
    await searchItems(_currentSearchQuery);

    // 如果是 WebDAV 模式，上传到服务器
    if (state.syncMode == SyncMode.webdav && state.webdavConfig != null) {
      _uploadToWebDAVWithRetry(path);
    }
  }

  /// 上传到 WebDAV，支持后台重试
  Future<void> _uploadToWebDAVWithRetry(String path, {int retryCount = 0}) async {
    if (state.webdavConfig == null) return;

    try {
      print('[Vault] Uploading to WebDAV after save... (attempt ${retryCount + 1})');
      final webdavService = await SyncServiceFactory.createWebDAVService(state.webdavConfig!);
      await webdavService.uploadVault(path);
      print('[Vault] Upload to WebDAV completed');

      // 标记需要同步的标志为 false
      await _storage.write(key: 'needs_webdav_sync', value: 'false');
    } catch (e) {
      print('[Vault] Failed to upload to WebDAV: $e');

      // 标记需要同步
      await _storage.write(key: 'needs_webdav_sync', value: 'true');

      // 如果是网络错误，尝试重试（最多 3 次）
      if (retryCount < 2 && _isNetworkError(e)) {
        print('[Vault] Will retry upload in 5 seconds...');
        Future.delayed(const Duration(seconds: 5), () {
          _uploadToWebDAVWithRetry(path, retryCount: retryCount + 1);
        });
      } else {
        print('[Vault] Upload failed after ${retryCount + 1} attempts, will retry on next save');
      }
    }
  }

  /// 检查是否是网络错误
  bool _isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('unreachable');
  }

  /// 检查并上传待同步的数据
  Future<void> _checkAndUploadPendingSync() async {
    if (state.syncMode != SyncMode.webdav || state.webdavConfig == null) return;

    final needsSync = await _storage.read(key: 'needs_webdav_sync');
    if (needsSync == 'true') {
      final path = state.vaultPath ?? await _getDefaultVaultPath();
      final file = File(path);
      if (await file.exists()) {
        print('[Vault] Found pending sync, uploading...');
        _uploadToWebDAVWithRetry(path);
      }
    }
  }

  Future<void> _startSyncWatch(String path, String masterPassword) async {
    // Cancel any existing subscription
    await _syncSubscription?.cancel();
    
    // Start watching for file changes
    await _syncService.startWatching(path, masterPassword: masterPassword);
    
      // Listen for file changes
      _syncSubscription = _syncService.onFileChanged.listen((event) async {
        final currentVaultState = state;
        if (!currentVaultState.isAuthenticated || currentVaultState.currentPassword == null) return;
      
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
        final vault = await VaultService.loadVault(currentVaultState.vaultPath!, currentVaultState.currentPassword!);
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
      filteredVaultItems: [],
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
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null || vaultState.selectedIds.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      var currentVault = vaultState.vault!;
      for (final id in vaultState.selectedIds) {
        currentVault = VaultService.deleteItem(currentVault, id);
      }
      await _saveAndRefresh(currentVault);
      state = state.copyWith(isSelectionMode: false, selectedIds: {});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  VaultItem? findItem(String id) {
    final vaultState = state;
    return vaultState.vault?.items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item not found'),
    );
  }

  /// 设置同步模式
  Future<void> setSyncMode(SyncMode mode, {WebDAVConfig? webdavConfig}) async {
    await _storage.write(key: 'sync_mode', value: mode.name);

    if (mode == SyncMode.webdav && webdavConfig != null) {
      // 保存 WebDAV 配置
      final config = webdavConfig.toJson();
      await _storage.write(key: 'webdav_server_url', value: config['serverUrl']);
      await _storage.write(key: 'webdav_username', value: config['username']);
      await _storage.write(key: 'webdav_password', value: config['password']);
      await _storage.write(key: 'webdav_remote_path', value: config['remotePath']);
    }

    state = state.copyWith(syncMode: mode, webdavConfig: webdavConfig);
    print('[Vault] Sync mode changed to: ${mode.name}');

    // 如果切换到 WebDAV 模式，立即上传当前 vault
    if (mode == SyncMode.webdav && webdavConfig != null && state.vault != null) {
      try {
        final vaultPath = state.vaultPath ?? await _getDefaultVaultPath();
        final file = File(vaultPath);
        if (await file.exists()) {
          print('[Vault] Uploading existing vault to WebDAV...');

          // 初始化 WebDAV 服务
          final webdavService = await SyncServiceFactory.createWebDAVService(webdavConfig);
          await webdavService.uploadVault(vaultPath);

          print('[Vault] Initial upload to WebDAV completed');

          // 重新启动同步监听
          await _stopSyncWatch();
          final masterPassword = state.currentPassword;
          if (masterPassword != null) {
            await _startSyncWatch(vaultPath, masterPassword);
          }
        }
      } catch (e) {
        print('[Vault] Failed to upload to WebDAV: $e');
        // 不抛出异常，让用户继续使用
      }
    }
  }

  /// 加载同步配置
  Future<void> _loadSyncConfig() async {
    final modeStr = await _storage.read(key: 'sync_mode');
    final mode = modeStr != null
        ? SyncMode.values.firstWhere((e) => e.name == modeStr, orElse: () => SyncMode.local)
        : SyncMode.local;

    WebDAVConfig? webdavConfig;
    if (mode == SyncMode.webdav) {
      final serverUrl = await _storage.read(key: 'webdav_server_url');
      final username = await _storage.read(key: 'webdav_username');
      final password = await _storage.read(key: 'webdav_password');
      final remotePath = await _storage.read(key: 'webdav_remote_path');

      if (serverUrl != null && username != null && password != null) {
        webdavConfig = WebDAVConfig(
          serverUrl: serverUrl,
          username: username,
          password: password,
          remotePath: remotePath ?? 'Hedge/vault.db',
        );
      }
    }

    state = state.copyWith(syncMode: mode, webdavConfig: webdavConfig);
  }

  List<VaultItem> getSortedItems() {
    final vaultState = state;
    final items = vaultState.vault?.items ?? [];
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
    final vaultState = state;
    if (vaultState.vault == null || vaultState.currentPassword == null) {
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
        var currentVault = vaultState.vault!;
        
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
