import 'package:flutter/material.dart';
import 'package:payload/core/widgets/stat_card.dart';
import 'package:payload/core/widgets/quick_action_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payload/features/request/screens/request_editor_screen.dart';
import 'package:payload/features/socket/screens/socket_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Row(
              children: [
                StatCard(
                  title: 'Requests today',
                  value: '124',
                  trend: '+12%',
                  icon: Icons.bolt,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 12),
                StatCard(
                  title: 'Success rate',
                  value: '98.2%',
                  trend: '+0.5%',
                  icon: Icons.check_circle_outline,
                  color: Colors.greenAccent,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestEditorScreen(),
                      ),
                    );
                  },
                ),
                QuickActionButton(
                  label: 'WebSocket',
                  icon: Icons.sync_alt,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebSocketScreen(),
                      ),
                    );
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
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _RecentRequestItem(
                  method: index % 2 == 0 ? 'GET' : 'POST',
                  path: '/api/v1/users${index > 0 ? '/$index' : ''}',
                  statusCode: 200,
                  time: '124ms',
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

  const _RecentRequestItem({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.time,
  });

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getMethodColor(method).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: TextStyle(
                color: _getMethodColor(method),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
