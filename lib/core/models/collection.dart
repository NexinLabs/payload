import 'http_request.dart';

class CollectionModel {
  final String id;
  final String name;
  final List<HttpRequestModel> requests;

  CollectionModel({
    required this.id,
    required this.name,
    this.requests = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'requests': requests.map((e) => e.toJson()).toList(),
  };

  factory CollectionModel.fromJson(Map<String, dynamic> json) =>
      CollectionModel(
        id: json['id'],
        name: json['name'],
        requests:
            (json['requests'] as List?)
                ?.map((e) => HttpRequestModel.fromJson(e))
                .toList() ??
            [],
      );

  CollectionModel copyWith({
    String? id,
    String? name,
    List<HttpRequestModel>? requests,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      requests: requests ?? this.requests,
    );
  }
}
