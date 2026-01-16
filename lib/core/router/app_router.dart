import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart' as dio;
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/collections/collections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/request/request_editor_screen.dart';
import '../../features/socket/socket_screen.dart';
import '../../features/request/components/response_view.dart';
import '../../layout/navigation_shell.dart';
import '../models/http_request.dart';

import '../../features/collections/collection_settings_screen.dart';
import '../../core/models/collection.dart';

class ResponseViewArguments {
  final dio.Response? response;
  final HttpRequestModel request;
  ResponseViewArguments({required this.response, required this.request});
}

class AppRouter {
  static const String root = '/';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String collections = '/collections';
  static const String settings = '/settings';
  static const String requestEditor = '/request-editor';
  static const String socket = '/socket';
  static const String responseView = '/response-view';
  static const String collectionSettings = '/collection-settings';

  static final router = GoRouter(
    initialLocation: root,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(path: root, builder: (context, state) => const NavigationShell()),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: collections,
        builder: (context, state) => const CollectionsScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: requestEditor,
        builder: (context, state) {
          final request = state.extra as HttpRequestModel?;
          return RequestEditorScreen(request: request);
        },
      ),
      GoRoute(
        path: socket,
        builder: (context, state) => const WebSocketScreen(),
      ),
      GoRoute(
        path: responseView,
        builder: (context, state) {
          final args = state.extra as ResponseViewArguments;
          return ResponseView(response: args.response, request: args.request);
        },
      ),
      GoRoute(
        path: collectionSettings,
        builder: (context, state) {
          final collection = state.extra as CollectionModel;
          return CollectionSettingsScreen(collection: collection);
        },
      ),
    ],
  );

  static void push(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    context.push(routeName, extra: arguments);
  }

  static void replace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    context.go(routeName, extra: arguments);
  }

  static void pop(BuildContext context) {
    context.pop();
  }
}
