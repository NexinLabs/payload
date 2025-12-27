import 'http_request.dart';

class CollectionModel {
  final String id;
  final String name;
  final Map<String, HttpRequestModel> requests;
  final List<KeyValue> environments;
  final bool useCookies;

  CollectionModel({
    required this.id,
    required this.name,
    this.requests = const {},
    this.environments = const [],
    this.useCookies = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'requests': requests.map((key, value) => MapEntry(key, value.toJson())),
    'environments': environments.map((e) => e.toJson()).toList(),
    'useCookies': useCookies,
  };

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    final requestsJson = json['requests'];
    Map<String, HttpRequestModel> requestsMap = {};

    if (requestsJson is Map) {
      requestsMap = requestsJson.map(
        (key, value) => MapEntry(
          key.toString(),
          HttpRequestModel.fromJson(value as Map<String, dynamic>),
        ),
      );
    } else if (requestsJson is List) {
      // Migration for old data format
      for (var item in requestsJson) {
        final request = HttpRequestModel.fromJson(item as Map<String, dynamic>);
        requestsMap[request.id] = request;
      }
    }

    return CollectionModel(
      id: json['id'],
      name: json['name'],
      requests: requestsMap,
      environments:
          (json['environments'] as List?)
              ?.map((e) => KeyValue.fromJson(e))
              .toList() ??
          [],
      useCookies: json['useCookies'] ?? false,
    );
  }

  CollectionModel copyWith({
    String? id,
    String? name,
    Map<String, HttpRequestModel>? requests,
    List<KeyValue>? environments,
    bool? useCookies,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      requests: requests ?? this.requests,
      environments: environments ?? this.environments,
      useCookies: useCookies ?? this.useCookies,
    );
  }
}
