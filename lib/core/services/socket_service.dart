import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/socket_model.dart';

class SocketService {
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  final _messageController = StreamController<SocketMessageUpdate>.broadcast();
  Stream<SocketMessageUpdate> get messages => _messageController.stream;

  final _statusController = StreamController<SocketStatusUpdate>.broadcast();
  Stream<SocketStatusUpdate> get status => _statusController.stream;

  Future<void> connect(String socketId, String url) async {
    try {
      // Disconnect existing if any
      await disconnect(socketId);

      _statusController.add(
        SocketStatusUpdate(socketId, SocketStatus.connecting),
      );
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channels[socketId] = channel;

      final subscription = channel.stream.listen(
        (message) {
          _messageController.add(
            SocketMessageUpdate(
              socketId,
              SocketMessage(
                event: 'message',
                payload: message.toString(),
                timestamp: DateTime.now(),
                isSent: false,
              ),
            ),
          );
        },
        onDone: () {
          _statusController.add(
            SocketStatusUpdate(socketId, SocketStatus.disconnected),
          );
          _channels.remove(socketId);
          _subscriptions.remove(socketId);
        },
        onError: (error) {
          _statusController.add(
            SocketStatusUpdate(socketId, SocketStatus.error),
          );
        },
      );

      _subscriptions[socketId] = subscription;
      _statusController.add(
        SocketStatusUpdate(socketId, SocketStatus.connected),
      );
    } catch (e) {
      _statusController.add(SocketStatusUpdate(socketId, SocketStatus.error));
      rethrow;
    }
  }

  Future<void> disconnect(String socketId) async {
    await _subscriptions[socketId]?.cancel();
    await _channels[socketId]?.sink.close();
    _subscriptions.remove(socketId);
    _channels.remove(socketId);
    _statusController.add(
      SocketStatusUpdate(socketId, SocketStatus.disconnected),
    );
  }

  void emit(String socketId, String event, String payload) {
    final channel = _channels[socketId];
    if (channel != null) {
      channel.sink.add(payload);
      _messageController.add(
        SocketMessageUpdate(
          socketId,
          SocketMessage(
            event: event,
            payload: payload,
            timestamp: DateTime.now(),
            isSent: true,
          ),
        ),
      );
    }
  }

  void dispose() {
    for (var socketId in _channels.keys.toList()) {
      disconnect(socketId);
    }
    _messageController.close();
    _statusController.close();
  }
}
