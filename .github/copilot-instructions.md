# Payload Copilot Instructions

## Project Context
Payload is a mobile-first API testing tool (Postman/Insomnia alternative) built with Flutter. It supports HTTP requests (GET, POST, etc.), WebSockets, collections, and environment variables.

## Core Tech Stack
- **Framework:** Flutter (Targeting Android, with Windows/Linux potential)
- **State Management:** Riverpod 2.0+ using `NotifierProvider` and `Notifier`.
- **Networking:** `dio` for HTTP, `web_socket_channel` for WebSockets.
- **Routing:** `go_router` (configured in [lib/core/router/app_router.dart](lib/core/router/app_router.dart)).
- **Persistence:** Custom file-based storage via `StorageService` in [lib/core/services/storage_service.dart](lib/core/services/storage_service.dart).

## Architectural Patterns
- **Feature-Based Structure:** Most logic is organized by feature in [lib/features/](lib/features/).
  - Example: [lib/features/request/](lib/features/request/) contains the request editor and its specific `components/`.
- **Shared Core:** [lib/core/](lib/core/) contains app-wide services, models, and shared providers.
- **Responsive Layout:** [lib/layout/navigation_shell.dart](lib/layout/navigation_shell.dart) handles the main shell, switching between a sidebar (desktop/tablet) and a drawer (mobile).
- **Service Layer:** Logic-heavy operations (API calls, storage) reside in [lib/core/services/](lib/core/services/).

## Coding Conventions
- **State Management:**
  - Define providers in [lib/core/providers/](lib/core/providers/) or within feature folders if local.
  - Use `Notifier` classes. Access them via `ref.watch(provider)`.
  - Example: `CollectionsNotifier` in [lib/core/providers/storage_providers.dart](lib/core/providers/storage_providers.dart).
- **Models:** Use plain classes in [lib/core/models/](lib/core/models/). Ensure they have `toMap`/`fromMap` if persisted.
- **UI Components:**
  - Put feature-specific widgets in a `components/` subfolder (e.g., [lib/features/request/components/](lib/features/request/components/)).
  - Use `ConsumerWidget` or `ConsumerStatefulWidget` to interact with Riverpod.
- **Styling:** Use `AppTheme` from [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart). Default is dark theme.
- **Environment Variables:** Requests support `{{variable_name}}` syntax, which is resolved by `RequestService` before sending.

## Critical Workflows
- **Running the App:** `flutter run`
- **Building for Android:** `bash build_apk.sh` (builds arm64 and installs via adb).
- **Adding a Request Field:** Update `HttpRequestModel`, update `RequestService` to handle the new field, and update `RequestEditorScreen`.

## Key Files to Reference
- [lib/core/models/http_request.dart](lib/core/models/http_request.dart): Core data structure for HTTP calls.
- [lib/core/services/request_service.dart](lib/core/services/request_service.dart): Logic for preparing and sending Dio requests.
- [lib/core/providers/storage_providers.dart](lib/core/providers/storage_providers.dart): Main state hub for collections and history.
