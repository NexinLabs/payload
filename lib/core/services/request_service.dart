import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/http_request.dart';

class RequestService {
  final Dio _dio = Dio();

  Future<Response> sendRequest(HttpRequestModel request) async {
    if (request.url.isEmpty) {
      throw Exception('URL cannot be empty');
    }

    final options = Options(
      method: request.method,
      headers: {
        for (var h in request.headers)
          if (h.enabled && h.key.trim().isNotEmpty) h.key.trim(): h.value,
      },
      validateStatus: (status) => true,
    );

    final queryParameters = {
      for (var p in request.params)
        if (p.enabled && p.key.trim().isNotEmpty) p.key.trim(): p.value,
    };

    dynamic data = request.body;
    if (request.bodyType == 'form-data') {
      data = FormData.fromMap({
        for (var f in request.formData)
          if (f.enabled && f.key.trim().isNotEmpty) f.key.trim(): f.value,
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
      request.url,
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
