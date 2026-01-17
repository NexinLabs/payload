import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/socket_model.dart';

class SocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _messageController = StreamController<SocketMessage>.broadcast();
  Stream<SocketMessage> get messages => _messageController.stream;

  final _statusController = StreamController<SocketStatus>.broadcast();
  Stream<SocketStatus> get status => _statusController.stream;

  Future<void> connect(String url) async {
    try {
      _statusController.add(SocketStatus.connecting);
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        (message) {
          _messageController.add(
            SocketMessage(
              event: 'message',
              payload: message.toString(),
              timestamp: DateTime.now(),
              isSent: false,
            ),
          );
        },
        onDone: () {
          _statusController.add(SocketStatus.disconnected);
        },
        onError: (error) {
          _statusController.add(SocketStatus.error);
        },
      );

      _statusController.add(SocketStatus.connected);
    } catch (e) {
      _statusController.add(SocketStatus.error);
      rethrow;
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _statusController.add(SocketStatus.disconnected);
  }

  void emit(String event, String payload) {
    if (_channel != null) {
      // For raw websockets, we just send the payload.
      // If we wanted to support "events", we might wrap it in JSON.
      // But let's just send the payload for now.
      _channel!.sink.add(payload);
      _messageController.add(
        SocketMessage(
          event: event,
          payload: payload,
          timestamp: DateTime.now(),
          isSent: true,
        ),
      );
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
