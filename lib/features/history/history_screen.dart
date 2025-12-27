import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/storage_providers.dart';
import '../../core/router/app_router.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => ref.read(historyProvider.notifier).clearHistory(),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('No history yet'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final request = history[index];
                return ListTile(
                  leading: _MethodIndicator(method: request.method),
                  title: Text(request.name),
                  subtitle: Text(
                    request.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    AppRouter.push(
                      context,
                      AppRouter.requestEditor,
                      arguments: request,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MethodIndicator extends StatelessWidget {
  final String method;
  const _MethodIndicator({required this.method});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (method) {
      case 'GET':
        color = Colors.green;
        break;
      case 'POST':
        color = Colors.blue;
        break;
      case 'PUT':
        color = Colors.orange;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 40,
      alignment: Alignment.center,
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
