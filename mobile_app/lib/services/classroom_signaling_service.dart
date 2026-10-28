import 'dart:convert';
import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

class ClassroomSignalingService {
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required String baseUrl,
    required String token,
    required int classroomId,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(String) onStatus,
  }) async {
    await disconnect();

    if (token.trim().isEmpty) {
      onStatus('Not connected: please log in again.');
      return;
    }

    final httpUri = Uri.parse(baseUrl);
    final scheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final uri = Uri(
      scheme: scheme,
      host: httpUri.host,
      port: httpUri.hasPort ? httpUri.port : null,
      path: '/ws/classrooms/$classroomId/',
    );

    try {
      onStatus('Connecting to classroom signaling…');

      final channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Token $token'},
        connectTimeout: const Duration(seconds: 10),
      );

      _channel = channel;

      await channel.ready.timeout(const Duration(seconds: 12));
      onStatus('Signaling connected');

      _subscription = channel.stream.listen(
        (event) {
          try {
            if (event is String) {
              final decoded = jsonDecode(event);
              if (decoded is Map<String, dynamic>) {
                onMessage(decoded);
              }
            }
          } catch (_) {
            onStatus('Received an invalid signaling message.');
          }
        },
        onError: (Object error) {
          onStatus('Signaling connection error: $error');
        },
        onDone: () {
          _channel = null;
          onStatus('Signaling disconnected');
        },
        cancelOnError: false,
      );
    } catch (e) {
      _channel = null;
      onStatus('Could not connect to signaling: $e');
    }
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Classroom signaling is not connected.');
    }
    channel.sink.add(jsonEncode(message));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    final channel = _channel;
    _channel = null;

    if (channel != null) {
      await channel.sink.close(ws_status.normalClosure);
    }
  }
}

