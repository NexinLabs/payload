import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/socket_model.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import 'storage_providers.dart';

final socketServiceProvider = Provider.autoDispose((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final socketConnectionsProvider =
    NotifierProvider<SocketConnectionsNotifier, List<SocketConnectionModel>>(
      SocketConnectionsNotifier.new,
    );

class SelectedSocketIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final selectedSocketIdProvider =
    NotifierProvider<SelectedSocketIdNotifier, String?>(
      SelectedSocketIdNotifier.new,
    );

final currentSocketProvider = Provider<SocketConnectionModel?>((ref) {
  final id = ref.watch(selectedSocketIdProvider);
  final connections = ref.watch(socketConnectionsProvider);
  if (id == null) return null;
  return connections.firstWhere(
    (c) => c.id == id,
    orElse: () => connections.first,
  );
});

class SocketConnectionsNotifier extends Notifier<List<SocketConnectionModel>> {
  late SocketService _service;
  late StorageService _storageService;
  StreamSubscription? _messageSub;
  StreamSubscription? _statusSub;

  @override
  List<SocketConnectionModel> build() {
    _service = ref.watch(socketServiceProvider);
    _storageService = ref.watch(storageServiceProvider);

    _loadConnections();
    _listenToService();

    ref.onDispose(() {
      _messageSub?.cancel();
      _statusSub?.cancel();
    });

    return [];
  }

  Future<void> _loadConnections() async {
    final connections = await _storageService.loadSockets();
    state = connections;
  }

  Future<void> _saveConnections() async {
    await _storageService.saveSockets(state);
  }

  void _listenToService() {
    _messageSub?.cancel();
    _messageSub = _service.messages.listen((update) async {
      await addMessage(update.socketId, update.message);
    });

    _statusSub?.cancel();
    _statusSub = _service.status.listen((update) {
      updateStatus(update.socketId, update.status);
    });
  }

  Future<void> addConnection(SocketConnectionModel connection) async {
    state = [...state, connection];
    await _saveConnections();
  }

  Future<void> setConnections(List<SocketConnectionModel> connections) async {
    state = connections;
    await _saveConnections();
  }

  Future<void> updateConnection(SocketConnectionModel connection) async {
    state = [
      for (final c in state)
        if (c.id == connection.id) connection else c,
    ];
    await _saveConnections();
  }

  Future<void> deleteConnection(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _saveConnections();
  }

  Future<void> addMessage(String socketId, SocketMessage message) async {
    state = [
      for (final c in state)
        if (c.id == socketId)
          c.copyWith(messages: [...c.messages, message])
        else
          c,
    ];
    await _saveConnections();
  }

  void updateStatus(String socketId, SocketStatus status) {
    state = [
      for (final c in state)
        if (c.id == socketId) c.copyWith(status: status) else c,
    ];
    // No need to save status to disk, as it will always be disconnected on start
  }

  Future<void> addEvent(String socketId, String eventName) async {
    state = [
      for (final c in state)
        if (c.id == socketId)
          c.copyWith(events: [...c.events, eventName])
        else
          c,
    ];
    await _saveConnections();
  }

  Future<void> deleteEvent(String socketId, String eventName) async {
    state = [
      for (final c in state)
        if (c.id == socketId)
          c.copyWith(events: c.events.where((e) => e != eventName).toList())
        else
          c,
    ];
    await _saveConnections();
  }

  Future<void> clearMessages(String socketId) async {
    state = [
      for (final c in state)
        if (c.id == socketId) c.copyWith(messages: []) else c,
    ];
    await _saveConnections();
  }
}
