import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../models/settings_model.dart';
import '../models/socket_model.dart';

class StorageService {
  static const String _collectionsFile = 'collections.json';
  static const String _historyFile = 'history.json';
  static const String _settingsFile = 'settings.json';
  static const String _socketsFile = 'sockets.json';

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

  Future<File> get _getSettingsFile async {
    final path = await _localPath;
    return File('$path/$_settingsFile');
  }

  Future<File> get _getSocketsFile async {
    final path = await _localPath;
    return File('$path/$_socketsFile');
  }

  Future<SettingsModel> loadSettings() async {
    try {
      final file = await _getSettingsFile;
      if (!await file.exists()) {
        return SettingsModel();
      }
      final contents = await file.readAsString();
      return SettingsModel.fromJson(json.decode(contents));
    } catch (e) {
      return SettingsModel();
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final file = await _getSettingsFile;
    await file.writeAsString(json.encode(settings.toJson()));
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

  Future<List<SocketConnectionModel>> loadSockets() async {
    try {
      final file = await _getSocketsFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList
          .map((json) => SocketConnectionModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSockets(List<SocketConnectionModel> sockets) async {
    try {
      final file = await _getSocketsFile;
      final jsonString = json.encode(sockets.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving sockets: $e');
    }
  }

  Future<void> saveRequestToFileSystem(
    CollectionModel collection,
    HttpRequestModel request,
  ) async {
    if (!Platform.isAndroid) return;

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      // getExternalStorageDirectory() returns Android/data/<packagename>/files
      // We go up one level to get to Android/data/<packagename>/
      final baseDir = directory.parent.path;
      final collectionsDir = Directory(
        '$baseDir/collections/${collection.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}',
      );

      if (!await collectionsDir.exists()) {
        await collectionsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'request-save-$timestamp.json';
      final file = File('${collectionsDir.path}/$fileName');

      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(request.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving to file system: $e');
    }
  }

  List<CollectionModel> _getInitialCollections() {
    return [
      CollectionModel(
        id: '1',
        name: 'Sample API',
        requests: {
          'req_1': HttpRequestModel(
            id: 'req_1',
            name: 'Get Users',
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/users',
          ),
          'req_2': HttpRequestModel(
            id: 'req_2',
            name: 'Create Post',
            method: 'POST',
            url: 'https://jsonplaceholder.typicode.com/posts',
            body: json.encode({'title': 'foo', 'body': 'bar', 'userId': 1}),
            bodyType: 'json',
            headers: [KeyValue(key: 'Content-Type', value: 'application/json')],
          ),
        },
      ),
    ];
  }
}
