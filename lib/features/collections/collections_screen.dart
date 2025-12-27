import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/storage_providers.dart';
import '../../core/models/collection.dart';
import '../../core/router/app_router.dart';
import '../../core/models/http_request.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search collections...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MethodChip(label: 'ALL', isSelected: true),
                _MethodChip(label: 'GET'),
                _MethodChip(label: 'POST'),
                _MethodChip(label: 'PUT'),
                _MethodChip(label: 'DELETE'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: collections.isEmpty
                ? const Center(child: Text('No collections found'))
                : ListView.builder(
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      return GestureDetector(
                        onLongPress: () =>
                            _showCollectionOptions(context, ref, collection),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.folder_open,
                            color: Colors.amber,
                          ),
                          title: Text(
                            collection.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 18,
                                ),
                                onPressed: () {
                                  AppRouter.push(
                                    context,
                                    AppRouter.collectionSettings,
                                    arguments: collection,
                                  );
                                },
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                          subtitle: Text(
                            '${collection.requests.length} requests',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          children: collection.requests.values.map((request) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 32,
                                right: 16,
                              ),
                              leading: _MethodIndicator(method: request.method),
                              title: Text(
                                request.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert, size: 18),
                                onPressed: () =>
                                    _showRequestOptions(context, ref, request),
                              ),
                              onTap: () {
                                ref
                                    .read(historyProvider.notifier)
                                    .addToHistory(request);
                                AppRouter.push(
                                  context,
                                  AppRouter.requestEditor,
                                  arguments: request,
                                );
                              },
                              onLongPress: () =>
                                  _showRequestOptions(context, ref, request),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCollectionDialog(context, ref),
        child: const Icon(Icons.create_new_folder_outlined),
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
              // Find which collection this request belongs to
              final collections = ref.read(collectionsProvider);
              String? collectionId;
              for (var c in collections) {
                if (c.requests.containsKey(request.id)) {
                  collectionId = c.id;
                  break;
                }
              }
              if (collectionId != null) {
                ref
                    .read(collectionsProvider.notifier)
                    .addRequestToCollection(collectionId, newRequest);
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

  void _showAddCollectionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Collection Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => AppRouter.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(collectionsProvider.notifier)
                    .addCollection(
                      CollectionModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: controller.text,
                      ),
                    );
                AppRouter.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _MethodChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        backgroundColor: Colors.white.withOpacity(0.05),
        selectedColor: Colors.blueAccent.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
          ),
        ),
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
