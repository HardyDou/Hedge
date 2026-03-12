import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// IPC 传输层抽象
abstract class IpcTransport {
  Future<void> connect();
  Future<Map<String, dynamic>> sendRequest(Map<String, dynamic> request);
  Future<void> close();
  bool get isConnected;
}

/// Unix Domain Socket 传输（macOS/Linux）
class UnixSocketTransport implements IpcTransport {
  final String socketPath;
  final Duration timeout;

  Socket? _socket;
  bool _connected = false;
  final _buffer = <int>[];
  final _pendingRequests = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;
  StreamSubscription? _subscription;

  UnixSocketTransport({
    required this.socketPath,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    ).timeout(timeout);
    _connected = true;

    _subscription = _socket!.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    _processBuffer();
  }

  void _processBuffer() {
    // 协议格式：[4字节长度（大端序）][JSON payload]
    while (_buffer.length >= 4) {
      final length = (_buffer[0] << 24) |
          (_buffer[1] << 16) |
          (_buffer[2] << 8) |
          _buffer[3];

      if (_buffer.length < 4 + length) break;

      final payload = _buffer.sublist(4, 4 + length);
      _buffer.removeRange(0, 4 + length);

      try {
        final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        final id = json['id'] as int?;
        if (id != null && _pendingRequests.containsKey(id)) {
          _pendingRequests.remove(id)!.complete(json);
        }
      } catch (_) {}
    }
  }

  void _onError(Object error) {
    _connected = false;
    for (final completer in _pendingRequests.values) {
      completer.completeError(error);
    }
    _pendingRequests.clear();
  }

  void _onDone() {
    _connected = false;
    for (final completer in _pendingRequests.values) {
      completer.completeError(Exception('IPC connection closed'));
    }
    _pendingRequests.clear();
  }

  @override
  Future<Map<String, dynamic>> sendRequest(
      Map<String, dynamic> request) async {
    if (!_connected || _socket == null) {
      throw Exception('Not connected');
    }

    final id = _nextId++;
    request['id'] = id;

    final payload = utf8.encode(jsonEncode(request));
    final lengthBytes = Uint8List(4);
    lengthBytes[0] = (payload.length >> 24) & 0xFF;
    lengthBytes[1] = (payload.length >> 16) & 0xFF;
    lengthBytes[2] = (payload.length >> 8) & 0xFF;
    lengthBytes[3] = payload.length & 0xFF;

    _socket!.add(lengthBytes);
    _socket!.add(payload);
    await _socket!.flush();

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    return completer.future.timeout(timeout, onTimeout: () {
      _pendingRequests.remove(id);
      throw TimeoutException('IPC request timed out', timeout);
    });
  }

  @override
  Future<void> close() async {
    _subscription?.cancel();
    await _socket?.close();
    _socket = null;
    _connected = false;
  }
}
