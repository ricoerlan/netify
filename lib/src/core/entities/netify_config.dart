/// Entry mode for accessing Netify panel
enum NetifyEntryMode {
  /// Draggable floating bubble showing request count (default)
  bubble,

  /// No automatic entry point, use Netify.show() manually
  none,
}

/// Configuration options for Netify.
///
/// Use this to customize Netify behavior such as max logs, debug mode, and entry point.
class NetifyConfig {
  /// Maximum number of logs to keep in memory. Defaults to 500.
  final int maxLogs;

  /// Only initialize in debug mode. Defaults to true.
  final bool showOnlyInDebug;

  /// Entry point mode for accessing Netify panel.
  final NetifyEntryMode entryMode;

  const NetifyConfig({
    this.maxLogs = 500,
    this.showOnlyInDebug = true,
    this.entryMode = NetifyEntryMode.bubble,
  });

  NetifyConfig copyWith({
    int? maxLogs,
    bool? showOnlyInDebug,
    NetifyEntryMode? entryMode,
  }) {
    return NetifyConfig(
      maxLogs: maxLogs ?? this.maxLogs,
      showOnlyInDebug: showOnlyInDebug ?? this.showOnlyInDebug,
      entryMode: entryMode ?? this.entryMode,
    );
  }
}
