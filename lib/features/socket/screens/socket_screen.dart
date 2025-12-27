import 'package:flutter/material.dart';

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key});

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  bool _isConnected = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'type': 'server',
      'message': 'Connected to echo.websocket.org',
      'time': '10:00 AM',
    },
    {
      'type': 'client',
      'message': '{"action": "subscribe", "topic": "ticker"}',
      'time': '10:01 AM',
    },
    {
      'type': 'server',
      'message': '{"status": "success", "message": "Subscribed to ticker"}',
      'time': '10:01 AM',
    },
  ];

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
                Switch(
                  value: _isConnected,
                  onChanged: (val) {
                    setState(() {
                      _isConnected = val;
                    });
                  },
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: isServer
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
                            if (!isServer)
                              const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.blueAccent,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              isServer ? 'Server' : 'Client',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isServer
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
                            color: isServer
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isServer
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
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
