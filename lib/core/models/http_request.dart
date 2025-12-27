class KeyValue {
  final String key;
  final String value;
  final bool enabled;

  KeyValue({required this.key, required this.value, this.enabled = true});

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'enabled': enabled,
  };
  factory KeyValue.fromJson(Map<String, dynamic> json) => KeyValue(
    key: json['key'],
    value: json['value'],
    enabled: json['enabled'] ?? true,
  );

  KeyValue copyWith({String? key, String? value, bool? enabled}) {
    return KeyValue(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }
}

class HttpRequestModel {
  final String id;
  final String name;
  final String method;
  final String url;
  final List<KeyValue> headers;
  final List<KeyValue> params;
  final List<KeyValue> formData;
  final List<String> filePaths;
  final String? body;
  final String bodyType; // none, json, text, form-data, files

  HttpRequestModel({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers = const [],
    this.params = const [],
    this.formData = const [],
    this.filePaths = const [],
    this.body,
    this.bodyType = 'none',
  });

  String get fullUrl {
    if (params.isEmpty) return url;
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      for (var p in params) {
        if (p.enabled && p.key.isNotEmpty) {
          queryParams[p.key] = p.value;
        }
      }
      return uri.replace(queryParameters: queryParams).toString();
    } catch (_) {
      return url;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'method': method,
    'url': url,
    'headers': headers.map((e) => e.toJson()).toList(),
    'params': params.map((e) => e.toJson()).toList(),
    'formData': formData.map((e) => e.toJson()).toList(),
    'filePaths': filePaths,
    'body': body,
    'bodyType': bodyType,
  };

  factory HttpRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => HttpRequestModel(
    id: json['id'],
    name: json['name'],
    method: json['method'],
    url: json['url'],
    headers:
        (json['headers'] as List?)?.map((e) => KeyValue.fromJson(e)).toList() ??
        [],
    params:
        (json['params'] as List?)?.map((e) => KeyValue.fromJson(e)).toList() ??
        [],
    formData:
        (json['formData'] as List?)
            ?.map((e) => KeyValue.fromJson(e))
            .toList() ??
        [],
    filePaths: (json['filePaths'] as List?)?.cast<String>() ?? [],
    body: json['body'],
    bodyType: json['bodyType'] ?? 'none',
  );

  HttpRequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValue>? headers,
    List<KeyValue>? params,
    List<KeyValue>? formData,
    List<String>? filePaths,
    String? body,
    String? bodyType,
  }) {
    return HttpRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      formData: formData ?? this.formData,
      filePaths: filePaths ?? this.filePaths,
      body: body ?? this.body,
      bodyType: bodyType ?? this.bodyType,
    );
  }
}
