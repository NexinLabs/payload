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
          if (h.enabled) h.key: h.value,
      },
      validateStatus: (status) => true,
    );

    final queryParameters = {
      for (var p in request.params)
        if (p.enabled) p.key: p.value,
    };

    final startTime = DateTime.now();
    final response = await _dio.request(
      request.url,
      data: request.body,
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
