import 'dart:io';
import 'ipc_transport.dart';

/// IPC 客户端（连接 Desktop App）
class IpcClient {
  static String get _socketPath {
    final uid = _getUid();
    return '/tmp/hedge-ipc-$uid.sock';
  }

  IpcTransport? _transport;

  /// 检查 Desktop App 是否在运行（socket 文件是否存在）
  static bool isDesktopAppRunning() {
    return File(_socketPath).existsSync();
  }

  /// 连接到 Desktop App
  Future<bool> connect() async {
    if (!isDesktopAppRunning()) return false;

    try {
      _transport = UnixSocketTransport(socketPath: _socketPath);
      await _transport!.connect();
      return true;
    } catch (_) {
      _transport = null;
      return false;
    }
  }

  /// 发送 ping 检查连接
  Future<bool> ping() async {
    try {
      final response = await _call('ping', {});
      return response['result'] == 'pong';
    } catch (_) {
      return false;
    }
  }

  /// 获取 Desktop App 版本
  Future<String?> getVersion() async {
    try {
      final response = await _call('get_version', {});
      return response['result']?['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 请求生物识别认证，返回会话令牌
  Future<String?> authenticate() async {
    try {
      final response = await _call('authenticate', {});
      if (response.containsKey('error')) return null;
      return response['result']?['session_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 获取密码条目
  Future<Map<String, dynamic>?> getPassword(
      String sessionToken, String query) async {
    try {
      final response = await _call('get_password', {
        'session_token': sessionToken,
        'item_query': query,
      });
      if (response.containsKey('error')) return null;
      return response['result'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 列出所有条目
  Future<List<Map<String, dynamic>>?> listItems(String sessionToken) async {
    try {
      final response = await _call('list_items', {
        'session_token': sessionToken,
      });
      if (response.containsKey('error')) return null;
      final items = response['result']?['items'] as List<dynamic>?;
      return items?.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// 锁定 vault
  Future<bool> lockVault(String sessionToken) async {
    try {
      final response = await _call('lock_vault', {
        'session_token': sessionToken,
      });
      return !response.containsKey('error');
    } catch (_) {
      return false;
    }
  }

  /// 撤销会话令牌
  Future<void> revokeToken(String sessionToken) async {
    try {
      await _call('revoke_token', {'session_token': sessionToken});
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _call(
      String method, Map<String, dynamic> params) async {
    if (_transport == null || !_transport!.isConnected) {
      throw Exception('Not connected to Desktop App');
    }
    return _transport!.sendRequest({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
  }

  Future<void> disconnect() async {
    await _transport?.close();
    _transport = null;
  }

  static String _getUid() {
    try {
      final result = Process.runSync('id', ['-u']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return '0';
  }
}
