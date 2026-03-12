import 'dart:io';
import '../ipc/ipc_client.dart';
import '../session/cli_session.dart';
import '../session/session_storage.dart';
import '../vault/vault_loader.dart';
import '../vault/vault_models.dart';

/// 认证管理器（混合模式：优先 IPC，降级到主密码）
class AuthManager {
  final IpcClient _ipcClient = IpcClient();
  CliSession? _currentSession;
  Vault? _vault;

  /// 认证并获取 vault（自动选择模式）
  /// 保证返回后 _currentSession 有效，整个命令生命周期内只认证一次
  Future<Vault?> authenticate({bool forceStandalone = false}) async {
    // 1. 尝试复用现有会话（验证 token 是否仍然有效）
    final existingSession = await SessionStorage.loadSession();
    if (existingSession != null && !existingSession.isExpired && !forceStandalone) {
      if (IpcClient.isDesktopAppRunning() && await _ipcClient.connect()) {
        // 用实际请求验证 token，而不只是 ping
        final test = await _ipcClient.listItems(existingSession.tokenId);
        if (test != null) {
          _currentSession = existingSession;
          return _loadVaultViaIpc();
        }
        // Token 失效，清除会话，重新认证
        await SessionStorage.clearSession();
        await _ipcClient.disconnect();
      }
    }

    // 2. IPC 模式（生物识别）
    if (!forceStandalone && IpcClient.isDesktopAppRunning()) {
      final vault = await _authenticateViaIpc();
      if (vault != null) return vault;
    }

    // 3. 降级到独立模式（主密码）
    return await _authenticateStandalone();
  }

  Future<Vault?> _authenticateViaIpc() async {
    try {
      if (!_ipcClient.isConnected && !await _ipcClient.connect()) return null;

      var result = await _ipcClient.authenticate();

      // Vault 锁定时，提示用户解锁后重试（一次）
      if (result.errorCode == 1007) {
        print('🔒 Hedge vault is locked.');
        stdout.write('   Please unlock Hedge, then press Enter to continue...');
        stdin.readLineSync();
        await _ipcClient.disconnect();
        if (!await _ipcClient.connect()) return null;
        result = await _ipcClient.authenticate();
      }

      if (result.token == null) {
        print(result.errorCode == 1007 ? '❌ Vault is still locked.' : '❌ Authentication failed');
        return null;
      }

      print('✓ Authenticated via Touch ID');
      _currentSession = CliSession(
        tokenId: result.token!,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        mode: AuthMode.biometric,
      );
      await SessionStorage.saveSession(_currentSession!);
      return _loadVaultViaIpc();
    } catch (_) {
      return null;
    }
  }

  Vault _loadVaultViaIpc() {
    _vault = Vault(items: []);
    return _vault!;
  }

  Future<Vault?> _authenticateStandalone() async {
    stderr.writeln('⚠️  Desktop App not detected. Falling back to master password mode.');

    final vaultPath = await VaultLoader.discoverVaultPath();
    if (vaultPath == null) {
      stderr.writeln('❌ Vault file not found. Please specify path with HEDGE_VAULT_PATH.');
      return null;
    }

    // Prefer env var for CI/CD non-interactive use
    String? password = Platform.environment['HEDGE_MASTER_PASSWORD'];

    if (password == null || password.isEmpty) {
      stderr.write('🔑 Enter master password: ');
      stdin.echoMode = false;
      password = stdin.readLineSync() ?? '';
      stdin.echoMode = true;
      stderr.writeln('');

      if (password.isEmpty) {
        stderr.writeln('❌ Password required');
        return null;
      }
    } else {
      stderr.writeln('🔑 Using password from HEDGE_MASTER_PASSWORD environment variable');
    }

    final vault = await VaultLoader.loadVault(vaultPath, password);
    if (vault == null) {
      stderr.writeln('❌ Incorrect password');
      return null;
    }

    _currentSession = CliSession(
      tokenId: 'standalone-${DateTime.now().millisecondsSinceEpoch}',
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      mode: AuthMode.password,
    );
    await SessionStorage.saveSession(_currentSession!);
    _vault = vault;
    return vault;
  }

  Future<VaultItem?> getItem(String query) async {
    if (_currentSession?.mode == AuthMode.biometric) {
      if (!_ipcClient.isConnected) await _ipcClient.connect();
      final result = await _ipcClient.getPassword(_currentSession!.tokenId, query);
      if (result == null) return null;
      return VaultItem.fromJson(result);
    } else {
      if (_vault == null) return null;
      final matches = _vault!.items.where((item) => item.matches(query)).toList();
      if (matches.length > 1) {
        print('⚠️  Multiple items found. Please be more specific.');
        return null;
      }
      return matches.isEmpty ? null : matches.first;
    }
  }

  Future<List<VaultItem>> listItems() async {
    if (_currentSession?.mode == AuthMode.biometric) {
      if (!_ipcClient.isConnected) await _ipcClient.connect();
      final result = await _ipcClient.listItems(_currentSession!.tokenId);
      return result?.map((json) => VaultItem.fromJson(json)).toList() ?? [];
    } else {
      return _vault?.items ?? [];
    }
  }

  Future<void> lock() async {
    if (_currentSession?.mode == AuthMode.biometric) {
      await _ipcClient.revokeToken(_currentSession!.tokenId);
    }
    await SessionStorage.clearSession();
    _currentSession = null;
    _vault = null;
  }

  Future<void> dispose() async {
    await _ipcClient.disconnect();
  }
}
