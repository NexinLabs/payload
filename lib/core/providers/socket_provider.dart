import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/socket_model.dart';
import '../services/socket_service.dart';

final socketServiceProvider = Provider.autoDispose((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final socketConnectionsProvider =
    StateNotifierProvider<
      SocketConnectionsNotifier,
      List<SocketConnectionModel>
    >((ref) {
      final service = ref.watch(socketServiceProvider);
      return SocketConnectionsNotifier(service);
    });

final selectedSocketIdProvider = StateProvider<String?>((ref) => null);

final currentSocketProvider = Provider<SocketConnectionModel?>((ref) {
  final id = ref.watch(selectedSocketIdProvider);
  final connections = ref.watch(socketConnectionsProvider);
  if (id == null) return null;
  return connections.firstWhere(
    (c) => c.id == id,
    orElse: () => connections.first,
  );
});

class SocketConnectionsNotifier
    extends StateNotifier<List<SocketConnectionModel>> {
  final SocketService _service;
  StreamSubscription? _messageSub;
  StreamSubscription? _statusSub;

  SocketConnectionsNotifier(this._service) : super([]) {
    _listenToService();
  }

  void _listenToService() {
    _messageSub?.cancel();
    _messageSub = _service.messages.listen((msg) {
      if (state.isEmpty) return;
      final activeIndex = state.indexWhere(
        (s) =>
            s.status == SocketStatus.connected ||
            s.status == SocketStatus.connecting,
      );
      final socketId = activeIndex != -1
          ? state[activeIndex].id
          : state.first.id;
      addMessage(socketId, msg);
    });

    _statusSub?.cancel();
    _statusSub = _service.status.listen((status) {
      if (state.isEmpty) return;
      final activeIndex = state.indexWhere(
        (s) =>
            s.status == SocketStatus.connected ||
            s.status == SocketStatus.connecting ||
            s.status == SocketStatus.error,
      );
      final socketId = activeIndex != -1
          ? state[activeIndex].id
          : state.first.id;
      updateStatus(socketId, status);
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void addConnection(SocketConnectionModel connection) {
    state = [...state, connection];
  }

  void updateConnection(SocketConnectionModel connection) {
    state = [
      for (final c in state)
        if (c.id == connection.id) connection else c,
    ];
  }

  void deleteConnection(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void addMessage(String socketId, SocketMessage message) {
    state = [
      for (final c in state)
        if (c.id == socketId)
          c.copyWith(messages: [...c.messages, message])
        else
          c,
    ];
  }

  void updateStatus(String socketId, SocketStatus status) {
    state = [
      for (final c in state)
        if (c.id == socketId) c.copyWith(status: status) else c,
    ];
  }

  void addEvent(String socketId, String eventName) {
    state = [
      for (final c in state)
        if (c.id == socketId)
          c.copyWith(events: [...c.events, eventName])
        else
          c,
    ];
  }
}
