import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/collection.dart';
import '../../core/models/http_request.dart';
import '../../core/providers/storage_providers.dart';

class CollectionSettingsScreen extends ConsumerStatefulWidget {
  final CollectionModel collection;
  const CollectionSettingsScreen({super.key, required this.collection});

  @override
  ConsumerState<CollectionSettingsScreen> createState() =>
      _CollectionSettingsScreenState();
}

class _CollectionSettingsScreenState
    extends ConsumerState<CollectionSettingsScreen> {
  late TextEditingController _nameController;
  late List<KeyValue> _environments;
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, TextEditingController> _valueControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _environments = List.from(
      widget.collection.environments.isEmpty
          ? [KeyValue(key: '', value: '')]
          : widget.collection.environments,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _keyControllers.values) {
      c.dispose();
    }
    for (var c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final updatedCollection = widget.collection.copyWith(
      name: _nameController.text,
      environments: _environments.where((e) => e.key.isNotEmpty).toList(),
    );
    await ref
        .read(collectionsProvider.notifier)
        .updateCollection(updatedCollection);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Collection updated')));
    }
  }

  Future<void> _exportCollection() async {
    try {
      final currentCollection = widget.collection.copyWith(
        name: _nameController.text,
        environments: _environments.where((e) => e.key.isNotEmpty).toList(),
      );
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(currentCollection.toJson());
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/${_nameController.text.replaceAll(' ', '_')}_collection.json',
      );
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported Collection: ${_nameController.text}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Collection Settings'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _save,
            tooltip: 'Save Changes',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _exportCollection,
            tooltip: 'Export Collection',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Collection Name',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Environment Variables',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildEnvironmentEditor(),
        ],
      ),
    );
  }

  Widget _buildEnvironmentEditor() {
    return Column(
      children: [
        ..._environments.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final keyId = 'env-key-$index'.hashCode;
          final valueId = 'env-value-$index'.hashCode;

          final keyController = _keyControllers.putIfAbsent(
            keyId,
            () => TextEditingController(text: item.key),
          );
          final valueController = _valueControllers.putIfAbsent(
            valueId,
            () => TextEditingController(text: item.value),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: item.enabled,
                  onChanged: (val) {
                    setState(() {
                      _environments[index] = _environments[index].copyWith(
                        enabled: val ?? true,
                      );
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: keyController,
                    onChanged: (val) {
                      _environments[index] = _environments[index].copyWith(
                        key: val,
                      );
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: valueController,
                    onChanged: (val) {
                      _environments[index] = _environments[index].copyWith(
                        value: val,
                      );
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _environments.removeAt(index);
                      if (_environments.isEmpty) {
                        _environments.add(KeyValue(key: '', value: ''));
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _environments.add(KeyValue(key: '', value: ''));
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Variable'),
        ),
      ],
    );
  }
}
