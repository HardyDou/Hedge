import '../auth/auth_manager.dart';
import '../session/cli_session.dart';
import '../session/session_storage.dart';

/// hedge unlock - 手动创建会话令牌
class UnlockCommand {
  final AuthManager authManager;

  UnlockCommand(this.authManager);

  Future<int> execute({bool forceStandalone = false, bool outputToken = false}) async {
    // 先清除旧会话，强制重新认证
    await SessionStorage.clearSession();

    final vault = await authManager.authenticate(forceStandalone: forceStandalone);
    if (vault == null) return 1;

    final session = await SessionStorage.loadSession();
    if (session == null) {
      print('❌ Failed to create session');
      return 1;
    }

    if (outputToken) {
      print(session.tokenId);
    } else {
      final modeLabel = session.mode == AuthMode.biometric ? 'Touch ID' : 'master password';
      final expiresIn = session.expiresAt.difference(DateTime.now());
      final minutes = expiresIn.inMinutes;
      print('✓ Unlocked via $modeLabel. Session valid for $minutes minutes.');
    }

    return 0;
  }
}
