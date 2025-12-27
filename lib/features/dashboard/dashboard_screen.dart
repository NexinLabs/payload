import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/core/widgets/stat_card.dart';
import 'package:payload/core/widgets/quick_action_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payload/core/router/app_router.dart';
import 'package:payload/core/providers/navigation_provider.dart';
import '../../core/providers/storage_providers.dart';
// import '../../core/models/http_request.dart';
// import '../../core/models/collection.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final collections = ref.watch(collectionsProvider);

    final totalRequests = collections.fold(
      0,
      (sum, c) => sum + c.requests.length,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'History',
                    value: history.length.toString(),
                    trend: 'Recent',
                    icon: Icons.history,
                    color: Colors.blueAccent,
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state = 1;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Saved Requests',
                    value: totalRequests.toString(),
                    trend: '${collections.length} Colls',
                    icon: Icons.folder_special,
                    color: Colors.greenAccent,
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state = 2;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                QuickActionButton(
                  label: 'HTTP Request',
                  icon: Icons.http,
                  color: Colors.blue,
                  onTap: () {
                    AppRouter.push(context, AppRouter.requestEditor);
                  },
                ),
                QuickActionButton(
                  label: 'WebSocket',
                  icon: Icons.sync_alt,
                  color: Colors.purple,
                  onTap: () {
                    AppRouter.push(context, AppRouter.socket);
                  },
                ),
                QuickActionButton(
                  label: 'Import cURL',
                  icon: Icons.input,
                  color: Colors.orange,
                  onTap: () {},
                ),
                QuickActionButton(
                  label: 'Environments',
                  icon: Icons.language,
                  color: Colors.teal,
                  onTap: () {},
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).scale(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 6 ? 6 : history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = history[index];
                return _RecentRequestItem(
                  method: request.method,
                  path: request.url,
                  statusCode: 200,
                  time: 'Recent',
                  onTap: () {
                    AppRouter.push(
                      context,
                      AppRouter.requestEditor,
                      arguments: request,
                    );
                  },
                );
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

class _RecentRequestItem extends StatelessWidget {
  final String method;
  final String path;
  final int statusCode;
  final String time;
  final VoidCallback? onTap;

  const _RecentRequestItem({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _MethodBadge(method: method),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                path,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
