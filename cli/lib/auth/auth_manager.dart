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
  Future<Vault?> authenticate({bool forceStandalone = false}) async {
    // 1. 尝试复用现有会话
    final existingSession = await SessionStorage.loadSession();
    if (existingSession != null && !existingSession.isExpired) {
      _currentSession = existingSession;

      // 通过 IPC 验证会话是否仍然有效
      if (!forceStandalone && await _ipcClient.connect()) {
        if (await _ipcClient.ping()) {
          return await _loadVaultViaIpc();
        }
      }
    }

    // 2. 尝试 IPC 模式（生物识别）
    if (!forceStandalone && IpcClient.isDesktopAppRunning()) {
      final vault = await _authenticateViaIpc();
      if (vault != null) return vault;
    }

    // 3. 降级到独立模式（主密码）
    return await _authenticateStandalone();
  }

  Future<Vault?> _authenticateViaIpc() async {
    try {
      print('🔐 Authenticating via Desktop App (Touch ID)...');

      if (!await _ipcClient.connect()) {
        return null;
      }

      final token = await _ipcClient.authenticate();
      if (token == null) {
        print('❌ Authentication failed');
        return null;
      }

      // 创建会话（15 分钟）
      _currentSession = CliSession(
        tokenId: token,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: 15)),
        mode: AuthMode.biometric,
      );
      await SessionStorage.saveSession(_currentSession!);

      return await _loadVaultViaIpc();
    } catch (e) {
      return null;
    }
  }

  Future<Vault?> _loadVaultViaIpc() async {
    // IPC 模式下，vault 数据通过 IPC 获取，不直接读取文件
    // 这里返回一个占位符，实际数据在命令执行时通过 IPC 获取
    _vault = Vault(items: []);
    return _vault;
  }

  Future<Vault?> _authenticateStandalone() async {
    print('⚠️  Desktop App not detected. Falling back to master password mode.');

    final vaultPath = await VaultLoader.discoverVaultPath();
    if (vaultPath == null) {
      print('❌ Vault file not found. Please specify path with HEDGE_VAULT_PATH.');
      return null;
    }

    stdout.write('🔑 Enter master password: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    print('');

    final vault = await VaultLoader.loadVault(vaultPath, password);
    if (vault == null) {
      print('❌ Incorrect password');
      return null;
    }

    // 创建会话（5 分钟）
    _currentSession = CliSession(
      tokenId: 'standalone-${DateTime.now().millisecondsSinceEpoch}',
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 5)),
      mode: AuthMode.password,
    );
    await SessionStorage.saveSession(_currentSession!);

    _vault = vault;
    return vault;
  }

  Future<VaultItem?> getItem(String query) async {
    if (_currentSession?.mode == AuthMode.biometric) {
      // IPC 模式：通过 Desktop App 获取
      final result = await _ipcClient.getPassword(_currentSession!.tokenId, query);
      if (result == null) return null;
      return VaultItem.fromJson(result);
    } else {
      // 独立模式：本地搜索
      if (_vault == null) return null;
      final matches = _vault!.items.where((item) => item.matches(query)).toList();
      if (matches.isEmpty) return null;
      if (matches.length > 1) {
        print('⚠️  Multiple items found. Please be more specific.');
        return null;
      }
      return matches.first;
    }
  }

  Future<List<VaultItem>> listItems() async {
    if (_currentSession?.mode == AuthMode.biometric) {
      final result = await _ipcClient.listItems(_currentSession!.tokenId);
      if (result == null) return [];
      return result.map((json) => VaultItem.fromJson(json)).toList();
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
