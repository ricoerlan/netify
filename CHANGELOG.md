## 1.0.1

### Fixed

- Fixed README screenshots not displaying on pub.dev (using absolute URLs)
- Fixed code formatting issues for pub.dev scoring

### Updated

- Updated dependencies to latest versions:
  - dio: ^5.9.0
  - share_plus: ^12.0.1
  - package_info_plus: ^9.0.0
- Added explicit Android/iOS platform support
- Added dartdoc comments to public API (20%+ coverage)

## 1.0.0

### Features

- 📡 Network inspection via Dio interceptor
- 🫧 Draggable floating bubble with request count badge
- 🌙 Dark mode support with theme toggle
- 📁 Request grouping by domain
- ⭐ Favorites/bookmarks for important requests
- 📸 Share request details as image
- 🔍 Search and filter by status, method, URL
- 📤 Export as JSON or HAR format
- 🔄 cURL generation for any request
- 🔁 Replay requests
- 📊 Detailed metrics (time, size, duration)
- 🪶 Lightweight (~1.5MB APK impact)

### Architecture

- Clean architecture implementation
- Zero footprint in release builds
- In-memory only storage (no disk persistence)
