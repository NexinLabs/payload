import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'components/response_view.dart';
import 'components/request_sidebar.dart';
import '../../core/models/http_request.dart';
import '../../core/models/collection.dart';
import '../../core/services/request_service.dart';
import '../../core/providers/storage_providers.dart';

class RequestEditorScreen extends ConsumerStatefulWidget {
  final HttpRequestModel? request;
  const RequestEditorScreen({super.key, this.request});

  @override
  ConsumerState<RequestEditorScreen> createState() =>
      _RequestEditorScreenState();
}

class _RequestEditorScreenState extends ConsumerState<RequestEditorScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late TextEditingController _urlController;
  late TextEditingController _nameController;
  late TextEditingController _bodyController;
  String _selectedMethod = 'GET';
  String _bodyType = 'none';
  List<KeyValue> _headers = [];
  List<KeyValue> _params = [];
  List<KeyValue> _formData = [];
  List<String> _filePaths = [];

  dio.Response? _response;
  bool _isLoading = false;

  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, TextEditingController> _valueControllers = {};

  final List<String> _methods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _urlController = TextEditingController(text: widget.request?.url ?? '');
    _nameController = TextEditingController(
      text: widget.request?.name ?? 'New Request',
    );
    _bodyController = TextEditingController(text: widget.request?.body ?? '');
    _selectedMethod = widget.request?.method ?? 'GET';
    _bodyType = widget.request?.bodyType ?? 'none';
    _headers = List.from(
      widget.request?.headers ?? [KeyValue(key: '', value: '')],
    );
    _params = List.from(
      widget.request?.params ?? [KeyValue(key: '', value: '')],
    );
    _formData = List.from(
      widget.request?.formData ?? [KeyValue(key: '', value: '')],
    );
    _filePaths = List.from(widget.request?.filePaths ?? []);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _nameController.dispose();
    _bodyController.dispose();
    for (var controller in _keyControllers.values) {
      controller.dispose();
    }
    for (var controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  HttpRequestModel _getCurrentRequest() {
    return HttpRequestModel(
      id:
          widget.request?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      method: _selectedMethod,
      url: _urlController.text,
      headers: _headers.where((h) => h.key.isNotEmpty).toList(),
      params: _params.where((p) => p.key.isNotEmpty).toList(),
      formData: _formData.where((f) => f.key.isNotEmpty).toList(),
      filePaths: _filePaths,
      body: _bodyType == 'none' ? null : _bodyController.text,
      bodyType: _bodyType,
    );
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    final request = _getCurrentRequest();

    try {
      final response = await ref
          .read(requestServiceProvider)
          .sendRequest(request);

      if (!mounted) return;
      setState(() {
        _response = response;
      });
      ref.read(historyProvider.notifier).addToHistory(request);

      // Open response view
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResponseView(response: response, request: request),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRequest() async {
    final request = _getCurrentRequest();

    if (widget.request != null) {
      await ref.read(collectionsProvider.notifier).updateRequest(request);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request updated')));
    } else {
      final collections = ref.read(collectionsProvider);
      if (collections.isEmpty) {
        final newColl = CollectionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'My Requests',
          requests: [request],
        );
        await ref.read(collectionsProvider.notifier).addCollection(newColl);
      } else {
        await ref
            .read(collectionsProvider.notifier)
            .addRequestToCollection(collections.first.id, request);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Request Name',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRequest),
          if (_response != null)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResponseView(
                      response: _response,
                      request: _getCurrentRequest(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: const RequestSidebar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMethod,
                      items: _methods.map((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(
                            method,
                            style: TextStyle(
                              color: _getMethodColor(method),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMethod = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://api.example.com/v1/resource',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SEND'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Params'),
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
              Tab(text: 'Auth'),
              Tab(text: 'Settings'),
            ],
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKeyValueEditor(
                  _params,
                  (newList) => setState(() => _params = newList),
                  'params',
                ),
                _buildKeyValueEditor(
                  _headers,
                  (newList) => setState(() => _headers = newList),
                  'headers',
                ),
                _buildBodyEditor(),
                _buildAuthEditor(),
                _buildSettingsEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueEditor(
    List<KeyValue> items,
    Function(List<KeyValue>) onChanged,
    String type,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return TextButton.icon(
            onPressed: () {
              onChanged([...items, KeyValue(key: '', value: '')]);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Row'),
          );
        }

        final keyId = '$type-key-$index'.hashCode;
        final valueId = '$type-value-$index'.hashCode;

        final keyController = _keyControllers.putIfAbsent(
          keyId,
          () => TextEditingController(text: items[index].key),
        );
        final valueController = _valueControllers.putIfAbsent(
          valueId,
          () => TextEditingController(text: items[index].value),
        );

        if (keyController.text != items[index].key) {
          keyController.text = items[index].key;
        }
        if (valueController.text != items[index].value) {
          valueController.text = items[index].value;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Checkbox(
                value: items[index].enabled,
                onChanged: (val) {
                  final newList = List<KeyValue>.from(items);
                  newList[index] = newList[index].copyWith(
                    enabled: val ?? true,
                  );
                  onChanged(newList);
                },
              ),
              Expanded(
                child: TextField(
                  controller: keyController,
                  onChanged: (val) {
                    final newList = List<KeyValue>.from(items);
                    newList[index] = newList[index].copyWith(key: val);
                    onChanged(newList);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Key',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: valueController,
                  onChanged: (val) {
                    final newList = List<KeyValue>.from(items);
                    newList[index] = newList[index].copyWith(value: val);
                    onChanged(newList);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Value',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  final newList = List<KeyValue>.from(items);
                  newList.removeAt(index);
                  _keyControllers.remove(keyId)?.dispose();
                  _valueControllers.remove(valueId)?.dispose();
                  onChanged(newList);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBodyEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBodyTypeChip('none'),
                _buildBodyTypeChip('json'),
                _buildBodyTypeChip('form-data'),
                _buildBodyTypeChip('files'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_bodyType == 'json')
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '{\n  "key": "value"\n}',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            )
          else if (_bodyType == 'form-data')
            Expanded(
              child: _buildKeyValueEditor(
                _formData,
                (newList) => setState(() => _formData = newList),
                'form-data',
              ),
            )
          else if (_bodyType == 'files')
            Expanded(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          _filePaths.addAll(result.paths.whereType<String>());
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Select Files'),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filePaths.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.file_present),
                          title: Text(_filePaths[index].split('/').last),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                _filePaths.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeChip(String label) {
    final isSelected = _bodyType == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _bodyType = label);
        },
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.white54,
        ),
      ),
    );
  }

  Widget _buildAuthEditor() {
    return const Center(child: Text('Auth Configuration'));
  }

  Widget _buildSettingsEditor() {
    return const Center(child: Text('Request Settings'));
  }

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
}
