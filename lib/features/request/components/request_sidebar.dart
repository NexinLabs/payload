import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/http_request.dart';
import '../../../core/providers/storage_providers.dart';
import '../../../core/router/app_router.dart';
import '../request_editor_screen.dart';

class RequestSidebar extends ConsumerWidget {
  const RequestSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final selectedCollectionId = ref.watch(selectedCollectionIdProvider);
    final history = ref.watch(historyProvider);

    String subtitle = '';
    if (selectedCollectionId != null) {
      final selected = collections.where((c) => c.id == selectedCollectionId);
      if (selected.isNotEmpty) {
        subtitle = '(${selected.first.name})';
      }
    }

    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset('assets/app_logo.png', height: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'PAYLOAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            // Sessions (Collections) Section
            _buildSectionHeader(
              context,
              title: 'Collections',
              subtitle: subtitle,
              onSettingsPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCollectionId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D2D),
                    items: collections.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedCollectionIdProvider.notifier).state =
                            val;
                      }
                    },
                    hint: const Text(
                      'Select Collection',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Requests Section
            _buildSectionHeader(
              context,
              title: 'Requests',
              onAddPressed: () {
                AppRouter.pop(context);
                AppRouter.replace(context, AppRouter.requestEditor);
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  if (selectedCollectionId != null &&
                      collections.any((c) => c.id == selectedCollectionId))
                    ...collections
                        .firstWhere((c) => c.id == selectedCollectionId)
                        .requests
                        .map((r) => _buildRequestItem(context, r)),

                  const Divider(color: Colors.white10),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...history.map((r) => _buildRequestItem(context, r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String subtitle = '',
    VoidCallback? onSettingsPressed,
    VoidCallback? onAddPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
          const Spacer(),
          if (onSettingsPressed != null)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: Colors.white54,
              ),
              onPressed: onSettingsPressed,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          if (onAddPressed != null)
            IconButton(
              icon: const Icon(Icons.add, size: 18, color: Colors.white54),
              onPressed: onAddPressed,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, HttpRequestModel r) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        r.name,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Text(
            r.method,
            style: TextStyle(
              color: _getMethodColor(r.method),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.url.isEmpty ? 'No URL' : _getPath(r.fullUrl),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () {
        AppRouter.pop(context);
        AppRouter.replace(context, AppRouter.requestEditor, arguments: r);
      },
    );
  }

  String _getPath(String url) {
    try {
      final uri = Uri.parse(url);
      String path = uri.path.isEmpty ? '/' : uri.path;
      if (uri.hasQuery) {
        path += '?${uri.query}';
      }
      return path;
    } catch (_) {
      return url;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
