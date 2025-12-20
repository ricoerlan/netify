# 🔍 Netify

A lightweight, debug-only network inspector for Flutter apps using Dio HTTP client. Features a modern UI with draggable floating bubble, dark mode, and share as image. Built with clean architecture principles and zero impact on release builds.

[![pub package](https://img.shields.io/pub/v/netify.svg)](https://pub.dev/packages/netify)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 📡 **Network Inspection** - Capture and inspect all HTTP requests/responses via Dio interceptor
- 🫧 **Floating Bubble** - Draggable floating bubble with request count badge
- 🌙 **Dark Mode** - Toggle between light and dark themes
- 📁 **Request Grouping** - Group requests by domain for better organization
- ⭐ **Favorites** - Bookmark important requests for quick access
- 📸 **Share as Image** - Export request details as shareable images
- 🔍 **Search & Filter** - Filter by status, method, and search by URL
- 📤 **Export Options** - Copy as JSON/HAR or save to file
- 🔄 **cURL Generation** - Generate cURL commands for any request
- 🔁 **Replay Requests** - Re-send any captured request
- 🌲 **Tree-Shakable** - Zero footprint in release builds
- 📊 **Detailed Metrics** - Request time, response size, duration with color-coded indicators
- 🪶 **Lightweight** - Minimal dependencies

## 📸 Screenshots

| Logs List                                                                                       | Log Detail                                                                                        | Dark Mode                                                                                   | Share as Image                                                                                  |
| ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| ![Logs List](https://raw.githubusercontent.com/ricoerlan/netify/main/screenshots/logs_list.png) | ![Log Detail](https://raw.githubusercontent.com/ricoerlan/netify/main/screenshots/log_detail.png) | ![Share](https://raw.githubusercontent.com/ricoerlan/netify/main/screenshots/log_share.png) | ![Dark Mode](https://raw.githubusercontent.com/ricoerlan/netify/main/screenshots/dark_mode.png) |

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  netify: ^1.0.0
  dio: ^5.4.0 # Required peer dependency
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Initialize Netify

```dart
import 'package:dio/dio.dart';
import 'package:netify/netify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = Dio();

  // Initialize Netify
  await Netify.init(dio: dio);

  runApp(MyApp(dio: dio));
}
```

### 2. Add the Floating Bubble

Wrap your home widget with `NetifyWrapper`:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NetifyWrapper(
        child: HomePage(),
      ),
    );
  }
}
```

### 3. (Optional) Manual Access

You can also open Netify programmatically:

```dart
// Open Netify panel
Netify.show(context);
```

That's it! 🎉 A draggable bubble will appear on your screen.

## 📖 API Reference

### Initialize

```dart
// Basic initialization
await Netify.init(dio: dio);

// With custom configuration
await Netify.init(
  dio: dio,
  config: const NetifyConfig(
    maxLogs: 1000,
    showOnlyInDebug: true,
    entryMode: NetifyEntryMode.bubble,
  ),
);
```

### Access Logs

```dart
// Get logs stream
Stream<List<NetworkLog>> stream = Netify.logsStream;

// Get current logs
List<NetworkLog> logs = Netify.logs;

// Get log count
int count = Netify.logCount;
```

### Search & Filter

```dart
// Search logs by URL, method, or status
List<NetworkLog> results = Netify.searchLogs('api/users');
```

### Export Logs

```dart
// Export as JSON
String json = Netify.exportAsJson();

// Export as HAR format (for Chrome DevTools, Postman, etc.)
String har = Netify.exportAsHar();
```

### Generate cURL

```dart
// Generate cURL command for a request
String curl = Netify.generateCurl(log);
```

### Clear Logs

```dart
// Clear all logs
Netify.clearLogs();
```

### Dispose

```dart
// Dispose resources
await Netify.dispose();
```

## 📱 UI Components

### NetifyPanel

The main UI for viewing all captured network requests:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NetifyPanel()),
);
```

### LogDetailPage

Detailed view of a single request (automatically opened from NetifyPanel):

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => LogDetailPage(log: networkLog)),
);
```

## ⚙️ Configuration Options

| Option            | Type              | Default                  | Description                              |
| ----------------- | ----------------- | ------------------------ | ---------------------------------------- |
| `maxLogs`         | `int`             | `500`                    | Maximum number of logs to keep in memory |
| `showOnlyInDebug` | `bool`            | `true`                   | Only initialize in debug mode            |
| `entryMode`       | `NetifyEntryMode` | `NetifyEntryMode.bubble` | Entry point mode (`bubble` or `none`)    |

## 🏗️ Architecture

Netify follows Clean Architecture principles:

```
lib/
├── netify.dart              # Public API
└── src/
    ├── core/                # Domain layer (pure Dart)
    │   ├── entities/        # Domain models
    │   └── repositories/    # Abstract contracts
    ├── data/                # Data layer
    │   ├── interceptor/     # Dio interceptor
    │   ├── repositories/    # Concrete implementations
    │   └── services/        # External services
    └── presentation/        # Presentation layer
        ├── pages/           # UI screens
        ├── widgets/         # Reusable widgets
        └── theme/           # Design tokens
```

## 🔒 Privacy & Security

- All data is stored **in-memory only** - nothing persists to disk
- Automatically disabled in release builds (when `showOnlyInDebug: true`)
- No data is sent to external servers
- Logs are cleared when the app is closed

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
