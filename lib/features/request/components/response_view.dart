import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../core/models/http_request.dart';
import '../../../core/router/app_router.dart';

class ResponseView extends StatefulWidget {
  final dio.Response? response;
  final HttpRequestModel request;

  const ResponseView({
    super.key,
    required this.response,
    required this.request,
  });

  @override
  State<ResponseView> createState() => _ResponseViewState();
}

class _ResponseViewState extends State<ResponseView>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _responseBodyTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _responseBodyTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _responseBodyTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusCode = widget.response?.statusCode ?? 0;
    final isSuccess = statusCode >= 200 && statusCode < 300;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSuccess
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$statusCode ${widget.response?.statusMessage ?? ""}',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '|',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.response?.extra['responseTime'] ?? '0'} ms',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Request'),
            Tab(text: 'Response'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => AppRouter.pop(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [_buildRequestTab(), _buildResponseTab()],
      ),
    );
  }

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('General'),
          _buildInfoRow('URL', widget.request.url),
          _buildInfoRow('Method', widget.request.method),
          const SizedBox(height: 16),
          _buildSectionTitle('Headers'),
          if (widget.request.headers.isEmpty)
            const Text('No headers', style: TextStyle(color: Colors.grey))
          else
            ...widget.request.headers.map((h) => _buildInfoRow(h.key, h.value)),
          const SizedBox(height: 16),
          _buildSectionTitle('Body'),
          if (widget.request.body == null || widget.request.body!.isEmpty)
            const Text('No body', style: TextStyle(color: Colors.grey))
          else
            SelectableText(widget.request.body!),
        ],
      ),
    );
  }

  Widget _buildResponseTab() {
    if (widget.response == null) {
      return const Center(child: Text('No response data'));
    }

    return Column(
      children: [
        TabBar(
          controller: _responseBodyTabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Headers'),
            Tab(text: 'JSON Text'),
            Tab(text: 'Raw'),
            Tab(text: 'Preview'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _responseBodyTabController,
            children: [
              _buildResponseHeaders(),
              _buildResponseBody(pretty: true),
              _buildResponseBody(pretty: false),
              _buildResponsePreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseHeaders() {
    final headers = widget.response?.headers.map;
    if (headers == null || headers.isEmpty) {
      return const Center(child: Text('No headers'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        final key = headers.keys.elementAt(index);
        final value = headers[key]?.join(', ') ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: SelectableText(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(child: SelectableText(value)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponseBody({required bool pretty}) {
    final data = widget.response?.data;
    if (data == null) return const Center(child: Text('No data'));

    String content = '';
    if (pretty) {
      try {
        if (data is Map || data is List) {
          const encoder = JsonEncoder.withIndent('  ');
          content = encoder.convert(data);
        } else {
          final decoded = json.decode(data.toString());
          const encoder = JsonEncoder.withIndent('  ');
          content = encoder.convert(decoded);
        }
      } catch (e) {
        content = data.toString();
      }
    } else {
      content = data.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Widget _buildResponsePreview() {
    final contentType = widget.response?.headers.value('content-type');
    final data = widget.response?.data;

    if (contentType?.contains('text/html') == true) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: HtmlWidget(data.toString()),
      );
    } else if (contentType?.contains('image') == true) {
      // Handle image preview if needed, but for now just text
      return const Center(child: Text('Image preview not supported yet'));
    }

    return const Center(
      child: Text('Preview not available for this content type'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: SelectableText(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
