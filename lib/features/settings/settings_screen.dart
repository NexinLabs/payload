import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/storage_providers.dart';
import '../../core/providers/socket_provider.dart';
import 'utils/settings_utils.dart';
import 'package:payload/config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final collections = ref.watch(collectionsProvider);
    final history = ref.watch(historyProvider);
    final sockets = ref.watch(socketConnectionsProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Interface'),
          _buildSettingTile(
            icon: Icons.code,
            title: 'Syntax Highlighting',
            subtitle: settings.syntaxHighlighting ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: settings.syntaxHighlighting,
              onChanged: (val) {
                ref
                    .read(settingsProvider.notifier)
                    .updateSettings(settings.copyWith(syntaxHighlighting: val));
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Networking'),
          _buildSettingTile(
            icon: Icons.timer_outlined,
            title: 'Request Timeout',
            subtitle: '${settings.timeout} seconds',
            onTap: () => _showTimeoutDialog(context, ref, settings.timeout),
          ),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: 'SSL Verification',
            subtitle: settings.sslVerification ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: settings.sslVerification,
              onChanged: (val) {
                ref
                    .read(settingsProvider.notifier)
                    .updateSettings(settings.copyWith(sslVerification: val));
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.redo,
            title: 'Follow Redirects',
            subtitle: settings.followRedirects ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: settings.followRedirects,
              onChanged: (val) {
                ref
                    .read(settingsProvider.notifier)
                    .updateSettings(settings.copyWith(followRedirects: val));
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data'),
          _buildSettingTile(
            icon: Icons.backup_outlined,
            title: 'Export Data',
            subtitle: 'Backup your collections and history to JSON',
            onTap: () async {
              await SettingsUtils.exportData(
                collections: collections,
                history: history,
                sockets: sockets,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data exported successfully')),
                );
              }
            },
          ),
          _buildSettingTile(
            icon: Icons.file_download_outlined,
            title: 'Import Data',
            subtitle: 'Restore collections and history from JSON',
            onTap: () async {
              try {
                final data = await SettingsUtils.importData();
                if (data != null) {
                  await ref
                      .read(collectionsProvider.notifier)
                      .setCollections(data['collections']);
                  await ref
                      .read(historyProvider.notifier)
                      .setHistory(data['history']);
                  await ref
                      .read(socketConnectionsProvider.notifier)
                      .setConnections(data['sockets']);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data imported successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),
          _buildSettingTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove temporary files',
            onTap: () async {
              await SettingsUtils.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }
            },
            color: Colors.redAccent,
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                // Credits
                const Text(
                  'DEVELOPED BY',
                  style: TextStyle(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCreditLink('Hunter87', Config.devGithubUrl),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('|', style: TextStyle(color: Colors.white10)),
                    ),
                    _buildCreditLink('NexinLabs', Config.orgGithubUrl),
                  ],
                ),

                const SizedBox(height: 20),

                // App Name and Version
                const Text(
                  '${Config.appName} v${Config.appVersion}',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ for developers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditLink(String label, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showTimeoutDialog(BuildContext context, WidgetRef ref, int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Request Timeout',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Seconds',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                final settings = ref.read(settingsProvider);
                ref
                    .read(settingsProvider.notifier)
                    .updateSettings(settings.copyWith(timeout: val));
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          color: enabled ? (color ?? Colors.white70) : Colors.white24,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.white : Colors.white24,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: enabled
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        trailing: trailing,
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
