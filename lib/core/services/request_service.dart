import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/http_request.dart';
import '../models/settings_model.dart';
import "../../config.dart";

class RequestService {
  final Dio _dio = Dio();

  String _replacePlaceholders(String text, List<KeyValue> environments) {
    var result = text;
    for (var env in environments) {
      if (env.enabled && env.key.isNotEmpty) {
        result = result.replaceAll(
          '<@${env.key}>',
          env.value,
        ); //trigger format : <@KEY_NAME>
      }
    }
    return result;
  }

  Future<Response> sendRequest(
    HttpRequestModel request, {
    SettingsModel? settings,
    List<KeyValue> environments = const [],
  }) async {
    if (request.url.isEmpty) {
      throw Exception('URL cannot be empty');
    }

    final currentSettings = settings ?? SettingsModel();

    // Configure Dio based on settings
    _dio.options.connectTimeout = Duration(seconds: currentSettings.timeout);
    _dio.options.receiveTimeout = Duration(seconds: currentSettings.timeout);
    _dio.options.followRedirects = currentSettings.followRedirects;

    // SSL Verification
    if (!currentSettings.sslVerification) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    } else {
      // Reset to default if needed
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = null;
    }

    // final url = _replacePlaceholders(request.url, environments);
    final url = request.url;

    final options = Options(
      method: request.method,
      headers: {
        // static headers
        "user-agent": Config.client,
        for (var h in request.headers)
          if (h.enabled && h.key.trim().isNotEmpty)
            h.key.trim(): _replacePlaceholders(h.value, environments),
      },
      validateStatus: (status) => true,
    );

    final queryParameters = {
      for (var p in request.params)
        if (p.enabled && p.key.trim().isNotEmpty) p.key.trim(): p.value,
    };

    dynamic data = request.body;
    if (data is String) {
      data = _replacePlaceholders(data, environments);
    }

    if (request.bodyType == 'form-data') {
      data = FormData.fromMap({
        for (var f in request.formData)
          if (f.enabled && f.key.trim().isNotEmpty)
            f.key.trim(): _replacePlaceholders(f.value, environments),
      });
    } else if (request.bodyType == 'files') {
      data = FormData();
      for (var path in request.filePaths) {
        final fileName = path.split('/').last;
        data.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(path, filename: fileName),
          ),
        );
      }
    }

    final startTime = DateTime.now();
    final response = await _dio.request(
      url,
      data: data,
      options: options,
      queryParameters: queryParameters,
    );
    final endTime = DateTime.now();
    response.extra['responseTime'] = endTime
        .difference(startTime)
        .inMilliseconds;

    return response;
  }
}

final requestServiceProvider = Provider((ref) => RequestService());
