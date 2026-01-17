import 'http_request.dart';

enum SocketStatus { disconnected, connecting, connected, error }

class SocketMessage {
  final String event;
  final String payload;
  final DateTime timestamp;
  final bool isSent;

  SocketMessage({
    required this.event,
    required this.payload,
    required this.timestamp,
    required this.isSent,
  });

  Map<String, dynamic> toJson() => {
    'event': event,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'isSent': isSent,
  };

  factory SocketMessage.fromJson(Map<String, dynamic> json) => SocketMessage(
    event: json['event'],
    payload: json['payload'],
    timestamp: DateTime.parse(json['timestamp']),
    isSent: json['isSent'],
  );
}

class SocketConnectionModel {
  final String id;
  final String name;
  final String url;
  final SocketStatus status;
  final List<String> events;
  final List<SocketMessage> messages;
  final List<KeyValue> headers;

  SocketConnectionModel({
    required this.id,
    required this.name,
    required this.url,
    this.status = SocketStatus.disconnected,
    this.events = const ['message'],
    this.messages = const [],
    this.headers = const [],
  });

  SocketConnectionModel copyWith({
    String? id,
    String? name,
    String? url,
    SocketStatus? status,
    List<String>? events,
    List<SocketMessage>? messages,
    List<KeyValue>? headers,
  }) {
    return SocketConnectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      status: status ?? this.status,
      events: events ?? this.events,
      messages: messages ?? this.messages,
      headers: headers ?? this.headers,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'events': events,
    'headers': headers.map((e) => e.toJson()).toList(),
    // We might not want to save all messages to disk, or maybe we do.
    'messages': messages.map((e) => e.toJson()).toList(),
  };

  factory SocketConnectionModel.fromJson(Map<String, dynamic> json) =>
      SocketConnectionModel(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        events: List<String>.from(json['events'] ?? ['message']),
        headers:
            (json['headers'] as List?)
                ?.map((e) => KeyValue.fromJson(e))
                .toList() ??
            [],
        messages:
            (json['messages'] as List?)
                ?.map((e) => SocketMessage.fromJson(e))
                .toList() ??
            [],
      );
}
