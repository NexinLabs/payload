import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/socket_model.dart';
import '../../../core/providers/socket_provider.dart';
import '../../../core/theme/app_theme.dart';

class SocketSidebar extends ConsumerWidget {
  const SocketSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(socketConnectionsProvider);
    final selectedId = ref.watch(selectedSocketIdProvider);

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connections',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined, size: 24),
                    onPressed: () => _createNewConnection(ref),
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: connections.isEmpty
                  ? Center(
                      child: Text(
                        'No connections',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: connections.length,
                      itemBuilder: (context, index) {
                        final conn = connections[index];
                        final isSelected = conn.id == selectedId;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                conn.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.cable,
                              color: _getStatusColor(conn.status),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            conn.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(
                            conn.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          onTap: () => _onSocketSelected(context, ref, conn.id),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () =>
                                _deleteConnection(context, ref, conn.id),
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewConnection(WidgetRef ref) {
    final newConn = SocketConnectionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Socket ${ref.read(socketConnectionsProvider).length + 1}',
      url: 'ws://echo.websocket.org',
    );
    ref.read(socketConnectionsProvider.notifier).addConnection(newConn);
    ref.read(selectedSocketIdProvider.notifier).state = newConn.id;
  }

  void _deleteConnection(BuildContext context, WidgetRef ref, String id) {
    ref.read(socketConnectionsProvider.notifier).deleteConnection(id);
    if (ref.read(selectedSocketIdProvider) == id) {
      ref.read(selectedSocketIdProvider.notifier).state = null;
    }
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.maybePop(context); // Close drawer if it's open
    }
  }

  void _onSocketSelected(BuildContext context, WidgetRef ref, String id) {
    ref.read(selectedSocketIdProvider.notifier).state = id;
    if (MediaQuery.of(context).size.width < 800) {
      Navigator.maybePop(context); // Close drawer if it's open
    }
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
}
