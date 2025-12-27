import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/http_request.dart';
import '../../../core/models/collection.dart';
import '../../../core/providers/storage_providers.dart';
import '../../../core/router/app_router.dart';

final isRequestsExpandedProvider = StateProvider<bool>((ref) => true);
final isWrapRequestsProvider = StateProvider<bool>((ref) => false);

class RequestSidebar extends ConsumerWidget {
  const RequestSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final selectedCollectionId = ref.watch(selectedCollectionIdProvider);
    final history = ref.watch(historyProvider);
    final isExpanded = ref.watch(isRequestsExpandedProvider);
    final isWrap = ref.watch(isWrapRequestsProvider);

    String subtitle = '';
    CollectionModel? selectedCollection;
    if (selectedCollectionId != null) {
      final selected = collections.where((c) => c.id == selectedCollectionId);
      if (selected.isNotEmpty) {
        selectedCollection = selected.first;
        subtitle = '(${selectedCollection.name})';
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
              onSettingsPressed: () {
                if (selectedCollection != null) {
                  AppRouter.pop(context);
                  AppRouter.push(
                    context,
                    AppRouter.collectionSettings,
                    arguments: selectedCollection,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a collection')),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: GestureDetector(
                onLongPress: () {
                  if (selectedCollection != null) {
                    _showCollectionOptions(context, ref, selectedCollection);
                  }
                },
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
                          ref
                                  .read(selectedCollectionIdProvider.notifier)
                                  .state =
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
            ),

            const SizedBox(height: 16),

            // Requests Section
            _buildSectionHeader(
              context,
              title: 'Requests',
              isExpanded: isExpanded,
              onToggle: () {
                ref.read(isRequestsExpandedProvider.notifier).state =
                    !isExpanded;
              },
              onAddPressed: () {
                AppRouter.pop(context);
                AppRouter.replace(context, AppRouter.requestEditor);
              },
              onWrapToggle: () {
                ref.read(isWrapRequestsProvider.notifier).state = !isWrap;
              },
              isWrap: isWrap,
            ),
            if (isExpanded)
              Expanded(
                child: ListView(
                  children: [
                    if (selectedCollectionId != null &&
                        collections.any((c) => c.id == selectedCollectionId))
                      ...collections
                          .firstWhere((c) => c.id == selectedCollectionId)
                          .requests
                          .values
                          .map(
                            (r) => _buildRequestItem(context, ref, r, isWrap),
                          ),

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
                    ...history.map(
                      (r) => _buildRequestItem(context, ref, r, isWrap),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCollectionOptions(
    BuildContext context,
    WidgetRef ref,
    CollectionModel collection,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white70),
            title: const Text(
              'Edit Collection',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              AppRouter.pop(context);
              AppRouter.push(
                context,
                AppRouter.collectionSettings,
                arguments: collection,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text(
              'Delete Collection',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              ref
                  .read(collectionsProvider.notifier)
                  .deleteCollection(collection.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String subtitle = '',
    VoidCallback? onSettingsPressed,
    VoidCallback? onAddPressed,
    VoidCallback? onToggle,
    VoidCallback? onWrapToggle,
    bool isExpanded = true,
    bool isWrap = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: 18,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
          if (onWrapToggle != null)
            IconButton(
              icon: Icon(
                isWrap ? Icons.wrap_text : Icons.short_text,
                size: 18,
                color: isWrap ? Colors.blueAccent : Colors.white54,
              ),
              onPressed: onWrapToggle,
              tooltip: 'Toggle Wrap Requests',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(right: 8),
            ),
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

  Widget _buildRequestItem(
    BuildContext context,
    WidgetRef ref,
    HttpRequestModel r,
    bool isWrap,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        r.name,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: isWrap ? null : 1,
        overflow: isWrap ? null : TextOverflow.ellipsis,
      ),
      subtitle: Row(
        crossAxisAlignment: isWrap
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
              overflow: isWrap ? null : TextOverflow.ellipsis,
              maxLines: isWrap ? null : 1,
            ),
          ),
        ],
      ),
      onTap: () {
        AppRouter.pop(context);
        AppRouter.replace(context, AppRouter.requestEditor, arguments: r);
      },
      onLongPress: () => _showRequestOptions(context, ref, r),
    );
  }

  void _showRequestOptions(
    BuildContext context,
    WidgetRef ref,
    HttpRequestModel request,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy, color: Colors.white70),
            title: const Text(
              'Duplicate Request',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              final newRequest = HttpRequestModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '${request.name} (Copy)',
                method: request.method,
                url: request.url,
                headers: List.from(request.headers),
                params: List.from(request.params),
                formData: List.from(request.formData),
                filePaths: List.from(request.filePaths),
                body: request.body,
                bodyType: request.bodyType,
              );
              final selectedId = ref.read(selectedCollectionIdProvider);
              if (selectedId != null) {
                ref
                    .read(collectionsProvider.notifier)
                    .addRequestToCollection(selectedId, newRequest);
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text(
              'Delete Request',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              ref.read(collectionsProvider.notifier).deleteRequest(request.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
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
