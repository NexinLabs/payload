import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../models/settings_model.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);

final collectionsProvider =
    NotifierProvider<CollectionsNotifier, List<CollectionModel>>(
      CollectionsNotifier.new,
    );

final historyProvider =
    NotifierProvider<HistoryNotifier, List<HttpRequestModel>>(
      HistoryNotifier.new,
    );

class SelectedCollectionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final selectedCollectionIdProvider =
    NotifierProvider<SelectedCollectionIdNotifier, String?>(
      SelectedCollectionIdNotifier.new,
    );

class SettingsNotifier extends Notifier<SettingsModel> {
  late StorageService _storage;

  @override
  SettingsModel build() {
    _storage = ref.watch(storageServiceProvider);
    _load();
    return SettingsModel();
  }

  Future<void> _load() async {
    state = await _storage.loadSettings();
  }

  Future<void> updateSettings(SettingsModel settings) async {
    state = settings;
    await _storage.saveSettings(state);
  }
}

class CollectionsNotifier extends Notifier<List<CollectionModel>> {
  late StorageService _storage;

  @override
  List<CollectionModel> build() {
    _storage = ref.watch(storageServiceProvider);
    _load();
    return [];
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

  Future<void> updateCollectionEnvironments(
    String collectionId,
    Map<String, String> updates,
  ) async {
    state = [
      for (final c in state)
        if (c.id == collectionId)
          (() {
            final envs = List<KeyValue>.from(c.environments);
            updates.forEach((key, value) {
              final index = envs.indexWhere((e) => e.key == key);
              if (index != -1) {
                envs[index] = envs[index].copyWith(value: value, enabled: true);
              } else {
                envs.add(KeyValue(key: key, value: value, enabled: true));
              }
            });
            return c.copyWith(environments: envs);
          })()
        else
          c,
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

  Future<void> setCollections(List<CollectionModel> collections) async {
    state = collections;
    await _storage.saveCollections(state);
  }
}

class HistoryNotifier extends Notifier<List<HttpRequestModel>> {
  late StorageService _storage;

  @override
  List<HttpRequestModel> build() {
    _storage = ref.watch(storageServiceProvider);
    _load();
    return [];
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

  Future<void> setHistory(List<HttpRequestModel> history) async {
    state = history;
    await _storage.saveHistory(state);
  }
}
