# Payload

A powerful and modern API client built with Flutter. Payload allows you to test, organize, and manage your HTTP and WebSocket requests with ease.

## Features

- **HTTP Client**: Support for GET, POST, PUT, DELETE, and more.
- **WebSocket Support**: Real-time communication testing.
- **Collections**: Organize your requests into logical groups.
- **Environments**: Manage variables across different environments (Development, Staging, Production).
- **History**: Keep track of your past requests.
- **Modern UI**: Clean, dark-themed interface built with Google Fonts and Flutter Animate.
- **JSON Viewer**: Integrated JSON viewer for easy response analysis.

## Getting Started

### Prerequisites

- Flutter SDK (Stable channel)
- Android Studio / VS Code with Flutter extension

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/hunter87ff/payload.git
   ```
2. Navigate to the project directory:
   ```bash
   cd payload
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## CI/CD

This project uses GitHub Actions to automatically build and release the APK.
- **Release Branch**: `release-main`
- **Workflow**: Builds a release APK and uploads it to GitHub Releases whenever code is pushed to the `release-main` branch.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
