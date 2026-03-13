import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/cli_session.dart';
import '../../src/dart/vault.dart';

/// IPC Server Service（Desktop App 端）
class IpcServerService {
  ServerSocket? _server;
  final SessionRegistry _sessionRegistry = SessionRegistry();
  final List<Socket> _clients = [];
  bool _isRunning = false;

  // 依赖注入
  final Future<bool> Function() authenticateWithBiometrics;
  final Vault? Function() getCurrentVault;
  final bool Function() isVaultUnlocked;
  final Future<bool> Function() requestUnlockForCli;

  IpcServerService({
    required this.authenticateWithBiometrics,
    required this.getCurrentVault,
    required this.isVaultUnlocked,
    required this.requestUnlockForCli,
  });

  String get _socketPath => '/tmp/hedge-ipc.sock';

  Future<void> start() async {
    if (_isRunning) return;

    try {
      // 清理陈旧的 socket 文件
      final socketFile = File(_socketPath);
      if (await socketFile.exists()) {
        await socketFile.delete();
      }

      _server = await ServerSocket.bind(
        InternetAddress(_socketPath, type: InternetAddressType.unix),
        0,
      );

      // 设置 socket 文件权限 0600
      await Process.run('chmod', ['600', _socketPath]);

      _isRunning = true;
      debugPrint('[IPC] Server started at $_socketPath');

      _server!.listen(_handleClient);
    } catch (e) {
      debugPrint('[IPC] Failed to start server: $e');
    }
  }

  void _handleClient(Socket client) {
    debugPrint('[IPC] Client connected');
    _clients.add(client);

    final buffer = <int>[];
    client.listen(
      (data) {
        buffer.addAll(data);
        _processBuffer(client, buffer);
      },
      onError: (error) {
        debugPrint('[IPC] Client error: $error');
        _clients.remove(client);
      },
      onDone: () {
        debugPrint('[IPC] Client disconnected');
        _clients.remove(client);
      },
    );
  }

  void _processBuffer(Socket client, List<int> buffer) {
    while (buffer.length >= 4) {
      final length = (buffer[0] << 24) |
          (buffer[1] << 16) |
          (buffer[2] << 8) |
          buffer[3];

      if (buffer.length < 4 + length) break;

      final payload = buffer.sublist(4, 4 + length);
      buffer.removeRange(0, 4 + length);

      try {
        final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        _handleRequest(client, json);
      } catch (e) {
        debugPrint('[IPC] Invalid request: $e');
      }
    }
  }

  Future<void> _handleRequest(
      Socket client, Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final id = request['id'];

    Map<String, dynamic> response;

    switch (method) {
      case 'ping':
        response = _buildResponse(id, {'result': 'pong'});
        break;

      case 'get_version':
        response = _buildResponse(id, {
          'result': {'version': '1.9.0'}
        });
        break;

      case 'authenticate':
        response = await _handleAuthenticate(id);
        break;

      case 'get_password':
        response = await _handleGetPassword(id, params);
        break;

      case 'list_items':
        response = await _handleListItems(id, params);
        break;

      case 'lock_vault':
        response = await _handleLockVault(id, params);
        break;

      case 'revoke_token':
        response = _handleRevokeToken(id, params);
        break;

      case 'get_webdav_config':
        response = _handleGetWebdavConfig(id);
        break;

      default:
        response = _buildError(id, -32601, 'Method not found');
    }

    _sendResponse(client, response);
  }

  Future<Map<String, dynamic>> _handleAuthenticate(dynamic id) async {
    if (!isVaultUnlocked()) {
      // vault 锁定，等待用户解锁（可能触发 Touch ID 或主密码）
      final unlocked = await requestUnlockForCli();
      if (!unlocked) return _buildError(id, 1007, 'Vault is locked');
      // 用户刚完成解锁，无需再次 Touch ID
    } else {
      // vault 已解锁，需要 Touch ID 确认 CLI 访问
      final success = await authenticateWithBiometrics();
      if (!success) return _buildError(id, 1004, 'Biometric authentication failed');
    }

    final vault = getCurrentVault();
    if (vault == null) {
      return _buildError(id, 2001, 'Vault not found');
    }

    final token = _sessionRegistry.createSession(
      AuthMode.biometric,
      'vault-id',
    );

    return _buildResponse(id, {
      'result': {'session_token': token}
    });
  }

  Future<Map<String, dynamic>> _handleGetPassword(
      dynamic id, Map<String, dynamic> params) async {
    final token = params['session_token'] as String?;
    final query = params['item_query'] as String?;

    if (token == null || !_sessionRegistry.validateSession(token)) {
      return _buildError(id, 1002, 'Session token expired or invalid');
    }

    if (query == null) {
      return _buildError(id, -32602, 'Missing item_query parameter');
    }

    final vault = getCurrentVault();
    if (vault == null) {
      return _buildError(id, 2001, 'Vault not found');
    }

    final matches = vault.items
        .where((item) =>
            item.title.toLowerCase().contains(query.toLowerCase()) ||
            (item.url?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (item.username?.toLowerCase().contains(query.toLowerCase()) ??
                false))
        .toList();

    if (matches.isEmpty) {
      return _buildError(id, 3001, 'No item found matching "$query"');
    }

    if (matches.length > 1) {
      return _buildError(id, 3002, 'Multiple items found');
    }

    final item = matches.first;
    return _buildResponse(id, {
      'result': {
        'id': item.id,
        'title': item.title,
        'username': item.username,
        'password': item.password,
        'url': item.url,
        'notes': item.notes,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      }
    });
  }

  Future<Map<String, dynamic>> _handleListItems(
      dynamic id, Map<String, dynamic> params) async {
    final token = params['session_token'] as String?;

    if (token == null || !_sessionRegistry.validateSession(token)) {
      return _buildError(id, 1002, 'Session token expired or invalid');
    }

    final vault = getCurrentVault();
    if (vault == null) {
      return _buildError(id, 2001, 'Vault not found');
    }

    final items = vault.items
        .map((item) => {
              'id': item.id,
              'title': item.title,
              'username': item.username,
              'url': item.url,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            })
        .toList();

    return _buildResponse(id, {
      'result': {'items': items}
    });
  }

  Future<Map<String, dynamic>> _handleLockVault(
      dynamic id, Map<String, dynamic> params) async {
    final token = params['session_token'] as String?;

    if (token == null || !_sessionRegistry.validateSession(token)) {
      return _buildError(id, 1002, 'Session token expired or invalid');
    }

    _sessionRegistry.revokeSession(token);
    return _buildResponse(id, {'result': 'ok'});
  }

  Map<String, dynamic> _handleRevokeToken(
      dynamic id, Map<String, dynamic> params) {
    final token = params['session_token'] as String?;
    if (token != null) {
      _sessionRegistry.revokeSession(token);
    }
    return _buildResponse(id, {'result': 'ok'});
  }

  /// 获取 WebDAV 配置（从 Desktop App 的 flutter_secure_storage）
  /// 注意：这里需要访问 flutter_secure_storage，
  /// 但 IPC Server 在独立 isolate 中，无法直接访问。
  /// 返回空配置，让 CLI 从 Keychain 读取
  Map<String, dynamic> _handleGetWebdavConfig(dynamic id) {
    // Desktop App 应该通过其他方式提供配置
    // MVP 阶段让 CLI 直接从 Keychain 读取
    return _buildResponse(id, {
      'result': {
        'server_url': null,
        'username': null,
        'password': null,
        'remote_path': null,
      }
    });
  }

  Map<String, dynamic> _buildResponse(dynamic id, Map<String, dynamic> data) {
    return {'jsonrpc': '2.0', 'id': id, ...data};
  }

  Map<String, dynamic> _buildError(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message}
    };
  }

  void _sendResponse(Socket client, Map<String, dynamic> response) {
    final payload = utf8.encode(jsonEncode(response));
    final lengthBytes = Uint8List(4);
    lengthBytes[0] = (payload.length >> 24) & 0xFF;
    lengthBytes[1] = (payload.length >> 16) & 0xFF;
    lengthBytes[2] = (payload.length >> 8) & 0xFF;
    lengthBytes[3] = payload.length & 0xFF;

    client.add(lengthBytes);
    client.add(payload);
  }

  void onVaultLocked() {
    _sessionRegistry.revokeAllSessions();
  }

  Future<void> stop() async {
    _isRunning = false;
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;

    final socketFile = File(_socketPath);
    if (await socketFile.exists()) {
      await socketFile.delete();
    }
    debugPrint('[IPC] Server stopped');
  }
}
