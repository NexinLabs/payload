import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final collectionsProvider =
    StateNotifierProvider<CollectionsNotifier, List<CollectionModel>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return CollectionsNotifier(storage);
    });

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HttpRequestModel>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return HistoryNotifier(storage);
    });

class CollectionsNotifier extends StateNotifier<List<CollectionModel>> {
  final StorageService _storage;

  CollectionsNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadCollections();
  }

  Future<void> addCollection(CollectionModel collection) async {
    state = [...state, collection];
    await _storage.saveCollections(state);
  }

  Future<void> updateCollection(CollectionModel collection) async {
    state = [
      for (final c in state)
        if (c.id == collection.id) collection else c,
    ];
    await _storage.saveCollections(state);
  }

  Future<void> deleteCollection(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage.saveCollections(state);
  }

  Future<void> addRequestToCollection(
    String collectionId,
    HttpRequestModel request,
  ) async {
    state = [
      for (final c in state)
        if (c.id == collectionId)
          c.copyWith(requests: [...c.requests, request])
        else
          c,
    ];
    await _storage.saveCollections(state);
  }

  Future<void> updateRequest(HttpRequestModel request) async {
    state = [
      for (final c in state)
        c.copyWith(
          requests: [
            for (final r in c.requests)
              if (r.id == request.id) request else r,
          ],
        ),
    ];
    await _storage.saveCollections(state);
  }
}

class HistoryNotifier extends StateNotifier<List<HttpRequestModel>> {
  final StorageService _storage;

  HistoryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadHistory();
  }

  Future<void> addToHistory(HttpRequestModel request) async {
    state = [request, ...state].take(50).toList(); // Keep last 50
    await _storage.saveHistory(state);
  }

  Future<void> clearHistory() async {
    state = [];
    await _storage.saveHistory(state);
  }
}
