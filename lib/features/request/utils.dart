import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/models/http_request.dart';
import '../../core/models/collection.dart';
import '../../core/services/request_service.dart';
import '../../core/providers/storage_providers.dart';
import '../../core/router/app_router.dart';

class RequestUtils {
  static CollectionModel? getCollection(WidgetRef ref, String requestId) {
    final collections = ref.read(collectionsProvider);
    final selectedId = ref.read(selectedCollectionIdProvider);

    // First check if request belongs to a collection
    for (var c in collections) {
      if (c.requests.containsKey(requestId)) {
        return c;
      }
    }

    // Then check selected collection
    if (selectedId != null) {
      try {
        return collections.firstWhere((c) => c.id == selectedId);
      } catch (_) {}
    }

    return null;
  }

  static List<KeyValue> getEnvironments(WidgetRef ref, String requestId) {
    return getCollection(ref, requestId)?.environments ?? [];
  }

  static Map<String, String> _parseCookies(
    String existing,
    List<String> newSetCookies,
  ) {
    Map<String, String> cookieMap = {};
    if (existing.isNotEmpty) {
      for (var part in existing.split(';')) {
        final kv = part.split('=');
        if (kv.length >= 2) {
          cookieMap[kv[0].trim()] = kv.sublist(1).join('=').trim();
        }
      }
    }
    for (var s in newSetCookies) {
      final part = s.split(';').first;
      final kv = part.split('=');
      if (kv.length >= 2) {
        cookieMap[kv[0].trim()] = kv.sublist(1).join('=').trim();
      }
    }
    return cookieMap;
  }

  static HttpRequestModel getCurrentRequest({
    required String requestId,
    required String name,
    required String method,
    required String url,
    required List<KeyValue> headers,
    required List<KeyValue> params,
    required List<KeyValue> formData,
    required List<String> filePaths,
    required String? body,
    required String bodyType,
  }) {
    return HttpRequestModel(
      id: requestId,
      name: name,
      method: method,
      url: url,
      headers: headers
          .where((h) => h.key.trim().isNotEmpty)
          .map((h) => h.copyWith(key: h.key.trim()))
          .toList(),
      params: params
          .where((p) => p.key.trim().isNotEmpty)
          .map((p) => p.copyWith(key: p.key.trim()))
          .toList(),
      formData: formData
          .where((f) => f.key.trim().isNotEmpty)
          .map((f) => f.copyWith(key: f.key.trim()))
          .toList(),
      filePaths: filePaths,
      body: bodyType == 'none' ? null : body,
      bodyType: bodyType,
    );
  }

  static Future<void> sendRequest({
    required WidgetRef ref,
    required BuildContext context,
    required HttpRequestModel request,
    required Function(bool) onLoadingChanged,
    required Function(dio.Response?) onResponseReceived,
    required bool Function() isMounted,
  }) async {
    onLoadingChanged(true);
    onResponseReceived(null);

    final settings = ref.read(settingsProvider);
    final collection = getCollection(ref, request.id);
    final environments = collection?.environments ?? [];

    HttpRequestModel finalRequest = request;
    if (collection != null && collection.useCookies) {
      bool hasCookieHeader = request.headers.any(
        (h) => h.key.toLowerCase() == 'cookies',
      );
      if (!hasCookieHeader) {
        finalRequest = request.copyWith(
          headers: [
            ...request.headers,
            KeyValue(key: 'Cookies', value: '<@Cookies>', enabled: true),
          ],
        );
      }
    }

    try {
      final response = await ref
          .read(requestServiceProvider)
          .sendRequest(
            finalRequest,
            settings: settings,
            environments: environments,
          );

      if (!isMounted()) return;
      onResponseReceived(response);

      if (collection != null && collection.useCookies) {
        final setCookies = response.headers['set-cookie'];
        if (setCookies != null && setCookies.isNotEmpty) {
          final existingCookies =
              collection.environments
                  .where((e) => e.key == 'Cookies')
                  .firstOrNull
                  ?.value ??
              '';

          final cookieMap = _parseCookies(existingCookies, setCookies);
          final updatedCookies = cookieMap.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');

          await ref
              .read(collectionsProvider.notifier)
              .updateCollectionEnvironments(collection.id, {
                'Cookies': updatedCookies,
                ...cookieMap,
              });
        }
      }

      // Save to collection if it's a new request or update if it exists
      final collections = ref.read(collectionsProvider);
      final selectedId = ref.read(selectedCollectionIdProvider);

      bool exists = false;
      for (var c in collections) {
        if (c.requests.containsKey(finalRequest.id)) {
          exists = true;
          break;
        }
      }

      if (exists) {
        await ref
            .read(collectionsProvider.notifier)
            .updateRequest(finalRequest);
      } else if (selectedId != null) {
        await ref
            .read(collectionsProvider.notifier)
            .addRequestToCollection(selectedId, finalRequest);
      } else {
        ref.read(historyProvider.notifier).addToHistory(finalRequest);
      }

      if (!isMounted()) return;
      AppRouter.push(
        context,
        AppRouter.responseView,
        arguments: ResponseViewArguments(
          response: response,
          request: finalRequest,
        ),
      );
    } catch (e) {
      if (!isMounted()) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (isMounted()) {
        onLoadingChanged(false);
      }
    }
  }

  static Future<void> saveRequest({
    required WidgetRef ref,
    required BuildContext context,
    required HttpRequestModel request,
    required bool isUpdate,
    required bool Function() isMounted,
  }) async {
    if (isUpdate) {
      await ref.read(collectionsProvider.notifier).updateRequest(request);

      if (!isMounted()) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request updated')));
    } else {
      final collections = ref.read(collectionsProvider);
      final selectedId = ref.read(selectedCollectionIdProvider);

      if (collections.isEmpty) {
        final newColl = CollectionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'My Requests',
          requests: {request.id: request},
        );
        await ref.read(collectionsProvider.notifier).addCollection(newColl);
      } else if (selectedId != null) {
        await ref
            .read(collectionsProvider.notifier)
            .addRequestToCollection(selectedId, request);
      } else {
        await ref
            .read(collectionsProvider.notifier)
            .addRequestToCollection(collections.first.id, request);
      }

      if (!isMounted()) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request saved')));
    }
  }
}
