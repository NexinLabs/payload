import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/http_request.dart';

class SettingsUtils {
  static Future<void> exportData({
    required List<CollectionModel> collections,
    required List<HttpRequestModel> history,
  }) async {
    final data = {
      'collections': collections.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/payload_export.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], subject: 'Payload Data Export');
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
