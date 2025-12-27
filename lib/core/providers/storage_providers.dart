import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../models/settings_model.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return SettingsNotifier(storage);
  },
);

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

final selectedCollectionIdProvider = StateProvider<String?>((ref) => null);

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(SettingsModel()) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadSettings();
  }

  Future<void> updateSettings(SettingsModel settings) async {
    state = settings;
    await _storage.saveSettings(state);
  }
}

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
    if (collection.requests.isNotEmpty) {
      await _storage.saveRequestToFileSystem(
        collection,
        collection.requests.values.last,
      );
    }
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
    CollectionModel? updatedCollection;
    state = [
      for (final c in state)
        if (c.id == collectionId)
          (() {
            updatedCollection = c.copyWith(
              requests: {...c.requests, request.id: request},
            );
            return updatedCollection!;
          })()
        else
          c,
    ];
    await _storage.saveCollections(state);
    if (updatedCollection != null) {
      await _storage.saveRequestToFileSystem(updatedCollection!, request);
    }
  }

  Future<void> updateRequest(HttpRequestModel request) async {
    CollectionModel? updatedCollection;
    state = [
      for (final c in state)
        (() {
          if (c.requests.containsKey(request.id)) {
            final newColl = c.copyWith(
              requests: {...c.requests, request.id: request},
            );
            updatedCollection = newColl;
            return newColl;
          }
          return c;
        })(),
    ];
    await _storage.saveCollections(state);
    if (updatedCollection != null) {
      await _storage.saveRequestToFileSystem(updatedCollection!, request);
    }
  }

  Future<void> deleteRequest(String requestId) async {
    state = [
      for (final c in state)
        if (c.requests.containsKey(requestId))
          c.copyWith(requests: Map.from(c.requests)..remove(requestId))
        else
          c,
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
    // Remove if already exists to move it to top
    final filtered = state.where((r) => r.id != request.id).toList();
    state = [request, ...filtered].take(50).toList(); // Keep last 50
    await _storage.saveHistory(state);
  }

  Future<void> clearHistory() async {
    state = [];
    await _storage.saveHistory(state);
  }
}
