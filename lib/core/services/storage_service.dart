import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/collection.dart';
import '../models/http_request.dart';

class StorageService {
  static const String _collectionsFile = 'collections.json';
  static const String _historyFile = 'history.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _getCollectionsFile async {
    final path = await _localPath;
    return File('$path/$_collectionsFile');
  }

  Future<File> get _getHistoryFile async {
    final path = await _localPath;
    return File('$path/$_historyFile');
  }

  Future<List<CollectionModel>> loadCollections() async {
    try {
      final file = await _getCollectionsFile;
      if (!await file.exists()) {
        return _getInitialCollections();
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => CollectionModel.fromJson(json)).toList();
    } catch (e) {
      return _getInitialCollections();
    }
  }

  Future<void> saveCollections(List<CollectionModel> collections) async {
    final file = await _getCollectionsFile;
    final jsonString = json.encode(collections.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<List<HttpRequestModel>> loadHistory() async {
    try {
      final file = await _getHistoryFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => HttpRequestModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistory(List<HttpRequestModel> history) async {
    final file = await _getHistoryFile;
    final jsonString = json.encode(history.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  List<CollectionModel> _getInitialCollections() {
    return [
      CollectionModel(
        id: '1',
        name: 'Sample API',
        requests: [
          HttpRequestModel(
            id: 'req_1',
            name: 'Get Users',
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/users',
          ),
          HttpRequestModel(
            id: 'req_2',
            name: 'Create Post',
            method: 'POST',
            url: 'https://jsonplaceholder.typicode.com/posts',
            body: json.encode({'title': 'foo', 'body': 'bar', 'userId': 1}),
            bodyType: 'json',
            headers: [KeyValue(key: 'Content-Type', value: 'application/json')],
          ),
        ],
      ),
    ];
  }
}
