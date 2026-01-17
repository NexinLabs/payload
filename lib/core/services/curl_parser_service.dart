import '../models/http_request.dart';

class CurlParserService {
  static HttpRequestModel parse(String curlString) {
    // Clean the string: remove backslashes at end of lines and combine lines
    String cleanString = curlString
        .replaceAll('\\\n', ' ')
        .replaceAll('\\\r\n', ' ');

    // Basic regex for method
    final methodMatch = RegExp(r'-X\s+([A-Z]+)').firstMatch(cleanString);
    String method = methodMatch?.group(1) ?? 'GET';

    // Regex for URL (look for something starting with http)
    String url = '';
    // Try to find URL in quotes first
    final urlMatch = RegExp(
      '[\'"](https?://[^\'"]+)[\'"]',
    ).firstMatch(cleanString);
    if (urlMatch != null) {
      url = urlMatch.group(1) ?? '';
    } else {
      // Try to find URL without quotes
      final urlMatchNoQuotes = RegExp(
        r'(https?://[^\s]+)',
      ).firstMatch(cleanString);
      url = urlMatchNoQuotes?.group(1) ?? '';
    }

    // Headers
    final List<KeyValue> headers = [];
    // This regex looks for -H "Key: Value" or -H 'Key: Value' or -H Key:Value
    final headerMatches = RegExp(
      '-H\\s+("[^"]+"|\'[^\']+\'|[^\\s]+)',
    ).allMatches(cleanString);
    for (final match in headerMatches) {
      String h = match.group(1) ?? '';
      // Remove surrounding quotes if they exist
      if ((h.startsWith('"') && h.endsWith('"')) ||
          (h.startsWith('\'') && h.endsWith('\''))) {
        h = h.substring(1, h.length - 1);
      }

      if (h.contains(':')) {
        final index = h.indexOf(':');
        headers.add(
          KeyValue(
            key: h.substring(0, index).trim(),
            value: h.substring(index + 1).trim(),
          ),
        );
      }
    }

    // Body
    String? body;
    // Look for -d, --data, --data-raw, --data-binary
    final dataMatch = RegExp(
      '(?:--data(?:-raw|-binary)?|-d)\\s+("[^"]+"|\'[^\']+\'|[^\\s]+)',
      dotAll: true,
    ).firstMatch(cleanString);
    if (dataMatch != null) {
      String d = dataMatch.group(1) ?? '';
      // Remove surrounding quotes
      if ((d.startsWith('"') && d.endsWith('"')) ||
          (d.startsWith('\'') && d.endsWith('\''))) {
        d = d.substring(1, d.length - 1);
      }
      body = d;
      if (method == 'GET') {
        method = 'POST';
      }
    }

    String bodyType = 'none';
    if (body != null) {
      bodyType = 'text';
      final contentTypeHeader = headers.where(
        (h) => h.key.toLowerCase() == 'content-type',
      );
      if (contentTypeHeader.isNotEmpty) {
        final contentType = contentTypeHeader.first.value.toLowerCase();
        if (contentType.contains('application/json')) {
          bodyType = 'json';
        } else if (contentType.contains('application/x-www-form-urlencoded')) {
          bodyType = 'form-data';
        }
      }
    }

    // Extract params from URL if any
    final List<KeyValue> params = [];
    try {
      final uri = Uri.parse(url);
      uri.queryParameters.forEach((key, value) {
        params.add(KeyValue(key: key, value: value));
      });
      // Strip params from base URL for the model
      if (url.contains('?')) {
        url = url.split('?').first;
      }
    } catch (_) {}

    return HttpRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Imported CURL',
      method: method,
      url: url,
      headers: headers,
      params: params,
      body: body,
      bodyType: bodyType,
    );
  }
}
