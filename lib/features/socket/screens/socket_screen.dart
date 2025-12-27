import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/websocket_service.dart';

class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'wss://echo.websocket.org',
  );
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleConnection() async {
    final service = ref.read(webSocketServiceProvider);
    if (_isConnected) {
      service.disconnect();
      setState(() {
        _isConnected = false;
      });
    } else {
      setState(() {
        _isConnecting = true;
      });
      try {
        await service.connect(_urlController.text);
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        service.stream?.listen(
          (message) {
            setState(() {
              _messages.add({
                'type': 'server',
                'message': message.toString(),
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
            });
          },
          onError: (error) {
            setState(() {
              _isConnected = false;
              _messages.add({
                'type': 'error',
                'message': 'Error: $error',
                'time': DateFormat('hh:mm a').format(DateTime.now()),
              });
            });
          },
          onDone: () {
            setState(() {
              _isConnected = false;
            });
          },
        );
      } catch (e) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    final service = ref.read(webSocketServiceProvider);
    service.sendMessage(_messageController.text);
    setState(() {
      _messages.add({
        'type': 'client',
        'message': _messageController.text,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Client'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'wss://echo.websocket.org',
                      prefixIcon: Icon(
                        Icons.link,
                        color: _isConnected ? Colors.green : Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _isConnected,
                        onChanged: (val) => _toggleConnection(),
                        activeColor: Colors.green,
                      ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isServer = msg['type'] == 'server';
                  final isError = msg['type'] == 'error';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: isServer || isError
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isServer)
                              const Icon(
                                Icons.dns,
                                size: 12,
                                color: Colors.purpleAccent,
                              ),
                            if (!isServer && !isError)
                              const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.blueAccent,
                              ),
                            if (isError)
                              const Icon(
                                Icons.error_outline,
                                size: 12,
                                color: Colors.redAccent,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isError
                                  ? 'Error'
                                  : isServer
                                  ? 'Server'
                                  : 'Client',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isError
                                    ? Colors.redAccent
                                    : isServer
                                    ? Colors.purpleAccent
                                    : Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              msg['time'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isError
                                ? Colors.red.withOpacity(0.1)
                                : isServer
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isError
                                  ? Colors.red.withOpacity(0.2)
                                  : isServer
                                  ? Colors.purple.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            msg['message'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type message...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _isConnected ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
