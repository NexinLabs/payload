import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
  late TabController _tabController;
  late TextEditingController _urlController;
  late TextEditingController _nameController;
  late TextEditingController _bodyController;
  String _selectedMethod = 'GET';
  String _bodyType = 'none';
  List<KeyValue> _headers = [];
  List<KeyValue> _params = [];

  dio.Response? _response;
  bool _isLoading = false;
  String _responseViewMode = 'Prettier';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });

    final request = HttpRequestModel(
      id:
          widget.request?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      method: _selectedMethod,
      url: _urlController.text,
      headers: _headers.where((h) => h.key.isNotEmpty).toList(),
      params: _params.where((p) => p.key.isNotEmpty).toList(),
      body: _bodyType == 'none' ? null : _bodyController.text,
      bodyType: _bodyType,
    );

    try {
      final response = await ref
          .read(requestServiceProvider)
          .sendRequest(request);
      setState(() {
        _response = response;
      });
      ref.read(historyProvider.notifier).addToHistory(request);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRequest() async {
    final request = HttpRequestModel(
      id:
          widget.request?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      method: _selectedMethod,
      url: _urlController.text,
      headers: _headers.where((h) => h.key.isNotEmpty).toList(),
      params: _params.where((p) => p.key.isNotEmpty).toList(),
      body: _bodyType == 'none' ? null : _bodyController.text,
      bodyType: _bodyType,
    );

    if (widget.request != null) {
      await ref.read(collectionsProvider.notifier).updateRequest(request);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveRequest),
        ],
      ),
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
                ),
                _buildKeyValueEditor(
                  _headers,
                  (newList) => setState(() => _headers = newList),
                ),
                _buildBodyEditor(),
                _buildAuthEditor(),
                _buildSettingsEditor(),
              ],
            ),
          ),
          if (_response != null) _buildResponseView(),
        ],
      ),
    );
  }

  Widget _buildResponseView() {
    final isHtml =
        _response?.headers.value('content-type')?.contains('text/html') ??
        false;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(
                  'Status: ${_response?.statusCode}',
                  style: TextStyle(
                    color: (_response?.statusCode ?? 0) < 400
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Time: ${_response?.extra['responseTime'] ?? 'N/A'}ms',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                _buildViewModeButton('Prettier'),
                _buildViewModeButton('Raw'),
                if (isHtml) _buildViewModeButton('Render'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResponseContent()),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String mode) {
    final isSelected = _responseViewMode == mode;
    return TextButton(
      onPressed: () => setState(() => _responseViewMode = mode),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      child: Text(
        mode,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResponseContent() {
    final data = _response?.data;
    if (data == null) return const Center(child: Text('No data'));

    switch (_responseViewMode) {
      case 'Prettier':
        if (data is Map || data is List) {
          return JsonView.string(json.encode(data));
        }
        try {
          final decoded = json.decode(data.toString());
          return JsonView.string(json.encode(decoded));
        } catch (_) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SelectableText(data.toString()),
          );
        }
      case 'Render':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: HtmlWidget(
            data.toString(),
            textStyle: const TextStyle(color: Colors.white),
          ),
        );
      case 'Raw':
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: SelectableText(
            data is Map || data is List
                ? const JsonEncoder.withIndent('  ').convert(data)
                : data.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        );
    }
  }

  Widget _buildKeyValueEditor(
    List<KeyValue> items,
    Function(List<KeyValue>) onChanged,
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
                  onChanged: (val) {
                    final newList = List<KeyValue>.from(items);
                    newList[index] = newList[index].copyWith(key: val);
                    onChanged(newList);
                  },
                  controller: TextEditingController(text: items[index].key)
                    ..selection = TextSelection.collapsed(
                      offset: items[index].key.length,
                    ),
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
                  onChanged: (val) {
                    final newList = List<KeyValue>.from(items);
                    newList[index] = newList[index].copyWith(value: val);
                    onChanged(newList);
                  },
                  controller: TextEditingController(text: items[index].value)
                    ..selection = TextSelection.collapsed(
                      offset: items[index].value.length,
                    ),
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
          Row(
            children: [
              _buildBodyTypeChip('none'),
              _buildBodyTypeChip('json'),
              _buildBodyTypeChip('form-data'),
              _buildBodyTypeChip('raw'),
            ],
          ),
          const SizedBox(height: 16),
          if (_bodyType != 'none')
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
