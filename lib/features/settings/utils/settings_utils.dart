import '../../../config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/http_request.dart';
import '../../../core/models/socket_model.dart';

class SettingsUtils {
  static Future<void> exportData({
    required List<CollectionModel> collections,
    required List<HttpRequestModel> history,
    required List<SocketConnectionModel> sockets,
  }) async {
    final data = {
      'collections': collections.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
      'sockets': sockets.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': Config.appVersion,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/payload_export.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], subject: 'Payload Data Export');
  }

  static Future<Map<String, dynamic>?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final dynamic decoded = json.decode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid JSON format: Root must be an object',
        );
      }

      final data = decoded;

      // Basic validation
      if (!data.containsKey('collections') || !data.containsKey('history')) {
        throw const FormatException(
          'Invalid backup file: Missing collections or history',
        );
      }

      final collectionsJson = data['collections'];
      final historyJson = data['history'];
      final socketsJson = data['sockets'] ?? [];

      if (collectionsJson is! List ||
          historyJson is! List ||
          socketsJson is! List) {
        throw const FormatException(
          'Invalid backup file: collections, history and sockets must be lists',
        );
      }

      final collections = collectionsJson.map((e) {
        if (e is! Map<String, dynamic>) {
          throw const FormatException('Invalid collection data');
        }
        return CollectionModel.fromJson(e);
      }).toList();

      final history = historyJson.map((e) {
        if (e is! Map<String, dynamic>) {
          throw const FormatException('Invalid history data');
        }
        return HttpRequestModel.fromJson(e);
      }).toList();

      final sockets = socketsJson.map((e) {
        if (e is! Map<String, dynamic>) {
          throw const FormatException('Invalid socket data');
        }
        return SocketConnectionModel.fromJson(e);
      }).toList();

      return {
        'collections': collections,
        'history': history,
        'sockets': sockets,
      };
    } on FormatException catch (e) {
      throw Exception('Format Error: ${e.message}');
    } catch (e) {
      throw Exception('Import failed: ${e.toString()}');
    }
  }

  static Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error clearing cache: $e');
    }
  }
}
