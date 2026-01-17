import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/socket_model.dart';
import '../../core/providers/socket_provider.dart';
import '../../core/theme/app_theme.dart';

class WebSocketScreen extends ConsumerStatefulWidget {
  const WebSocketScreen({super.key});

  @override
  ConsumerState<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends ConsumerState<WebSocketScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();
  String _selectedEvent = 'message';

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  void _loadSocket(SocketConnectionModel? socket) {
    if (socket != null) {
      _nameController.text = socket.name;
      _urlController.text = socket.url;
      if (socket.events.isNotEmpty) {
        _selectedEvent = socket.events.contains(_selectedEvent)
            ? _selectedEvent
            : socket.events.first;
      }
    } else {
      _nameController.clear();
      _urlController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSocket = ref.watch(currentSocketProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Update controllers when socket changes
    ref.listen(currentSocketProvider, (previous, next) {
      if (next != null && next.id != previous?.id) {
        _loadSocket(next);
      }
    });

    return currentSocket == null
        ? _buildEmptyState()
        : _buildMainContent(currentSocket, isMobile);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.electrical_services,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'WebSocket Master',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select or create a connection to start',
            style: TextStyle(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createNewConnection,
            icon: const Icon(Icons.add),
            label: const Text('Create New Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(SocketConnectionModel socket, bool isMobile) {
    return Column(
      children: [
        // Connection Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: _buildConnectionHeader(socket),
        ),

        Expanded(
          child: isMobile
              ? ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Event Log',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildConsoleLogContainer(socket),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildConfigSection(socket),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Event Log first (top)
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildConsoleSection(socket),
                      ),
                    ),
                    const Divider(height: 1),
                    // Messaging Section (bottom)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildConfigSection(socket),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConsoleLogContainer(SocketConnectionModel socket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: socket.messages.isEmpty
          ? const Center(child: Text('Waiting for messages...'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: socket.messages.length,
              itemBuilder: (context, index) {
                final msg = socket.messages[socket.messages.length - 1 - index];
                return _buildMessageItem(msg);
              },
            ),
    );
  }

  Widget _buildConnectionHeader(SocketConnectionModel socket) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      socket.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusIndicator(socket.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                socket.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showSocketSettingsDialog(socket),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: socket.status == SocketStatus.connected
              ? _disconnect
              : _connect,
          icon: Icon(
            socket.status == SocketStatus.connected
                ? Icons.link_off
                : Icons.link,
          ),
          style: IconButton.styleFrom(
            backgroundColor: socket.status == SocketStatus.connected
                ? AppTheme.errorColor
                : AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigSection(SocketConnectionModel socket) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Messaging',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: () => _showAddEventDialog(socket),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('New Event'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: socket.events.contains(_selectedEvent)
                ? _selectedEvent
                : socket.events.first,
            decoration: const InputDecoration(
              labelText: 'Event',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: socket.events
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedEvent = val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _payloadController,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Payload',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'Enter message or JSON...',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: socket.status == SocketStatus.connected
                  ? _emitMessage
                  : null,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Emit Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleSection(SocketConnectionModel socket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Event Log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (socket.messages.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _updateSocket(socket.copyWith(messages: []));
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildConsoleLogContainer(socket)),
      ],
    );
  }

  Widget _buildMessageItem(SocketMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: msg.isSent
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: msg.isSent
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    msg.isSent ? Icons.outbox : Icons.move_to_inbox,
                    size: 14,
                    color: msg.isSent ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.event.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: msg.isSent ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
              Text(
                '${msg.timestamp.hour}:${msg.timestamp.minute}:${msg.timestamp.second}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg.payload,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(SocketStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(SocketStatus status) {
    switch (status) {
      case SocketStatus.connected:
        return AppTheme.successColor;
      case SocketStatus.connecting:
        return AppTheme.warningColor;
      case SocketStatus.error:
        return AppTheme.errorColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  void _createNewConnection() {
    final newConn = SocketConnectionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Socket ${ref.read(socketConnectionsProvider).length + 1}',
      url: 'ws://echo.websocket.org',
    );
    ref.read(socketConnectionsProvider.notifier).addConnection(newConn);
    ref.read(selectedSocketIdProvider.notifier).state = newConn.id;
  }

  void _updateSocket(SocketConnectionModel socket) {
    ref.read(socketConnectionsProvider.notifier).updateConnection(socket);
  }

  void _connect() async {
    final socket = ref.read(currentSocketProvider);
    if (socket == null) return;

    try {
      await ref.read(socketServiceProvider).connect(socket.url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  void _disconnect() {
    ref.read(socketServiceProvider).disconnect();
  }

  void _emitMessage() {
    final socket = ref.read(currentSocketProvider);
    if (socket == null) return;

    final payload = _payloadController.text;
    ref.read(socketServiceProvider).emit(_selectedEvent, payload);
    // Message will be added to list by the listener in the provider
  }

  void _showSocketSettingsDialog(SocketConnectionModel socket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Socket Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Socket Server',
              ),
              onChanged: (val) => _updateSocket(socket.copyWith(name: val)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'ws://echo.websocket.org',
              ),
              onChanged: (val) => _updateSocket(socket.copyWith(url: val)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(SocketConnectionModel socket) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Event name',
            helperText: 'For raw WebSockets, this is just a label for the log',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(socketConnectionsProvider.notifier)
                    .addEvent(socket.id, controller.text);
                setState(() => _selectedEvent = controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
