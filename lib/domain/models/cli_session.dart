import 'package:uuid/uuid.dart';

enum AuthMode { biometric, password }

/// CLI 会话模型
class CliSession {
  final String tokenId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String vaultId;
  final AuthMode mode;

  CliSession({
    required this.tokenId,
    required this.issuedAt,
    required this.expiresAt,
    required this.vaultId,
    required this.mode,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get ttl => expiresAt.difference(DateTime.now());
}

/// 会话注册表（Desktop App 内存维护）
class SessionRegistry {
  final Map<String, CliSession> _sessions = {};

  String createSession(AuthMode mode, String vaultId) {
    final tokenId = const Uuid().v4();
    final duration = mode == AuthMode.biometric
        ? const Duration(minutes: 15)
        : const Duration(minutes: 5);

    final session = CliSession(
      tokenId: tokenId,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(duration),
      vaultId: vaultId,
      mode: mode,
    );

    _sessions[tokenId] = session;
    _cleanupExpired();
    return tokenId;
  }

  bool validateSession(String tokenId) {
    final session = _sessions[tokenId];
    if (session == null) return false;
    if (session.isExpired) {
      _sessions.remove(tokenId);
      return false;
    }
    return true;
  }

  void revokeSession(String tokenId) {
    _sessions.remove(tokenId);
  }

  void revokeAllSessions() {
    _sessions.clear();
  }

  void _cleanupExpired() {
    _sessions.removeWhere((_, session) => session.isExpired);
  }

  int get activeSessionCount => _sessions.length;
}
