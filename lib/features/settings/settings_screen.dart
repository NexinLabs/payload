import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Interface'),
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Always on',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          _buildSettingTile(
            icon: Icons.text_fields,
            title: 'Editor Font Size',
            subtitle: '14px',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.code,
            title: 'Syntax Highlighting',
            subtitle: 'Enabled',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Networking'),
          _buildSettingTile(
            icon: Icons.timer_outlined,
            title: 'Request Timeout',
            subtitle: '30 seconds',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: 'SSL Verification',
            subtitle: 'Enabled',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          _buildSettingTile(
            icon: Icons.redo,
            title: 'Follow Redirects',
            subtitle: 'Enabled',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data'),
          _buildSettingTile(
            icon: Icons.backup_outlined,
            title: 'Export Data',
            subtitle: 'Backup your collections and history',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove temporary files',
            onTap: () {},
            color: Colors.redAccent,
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text(
                  'PAYLOAD v1.0.0',
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.white70, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
