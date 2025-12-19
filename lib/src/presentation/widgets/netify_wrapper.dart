import 'package:flutter/material.dart';

import '../../core/entities/netify_config.dart';
import '../pages/netify_panel.dart';
import 'netify_bubble.dart';

/// A wrapper widget that adds Netify entry point to your app.
///
/// Wrap your home widget with this to show the floating bubble.
///
/// Example:
/// ```dart
/// NetifyWrapper(
///   child: HomePage(),
/// )
/// ```
class NetifyWrapper extends StatelessWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Entry mode for accessing Netify panel.
  final NetifyEntryMode entryMode;

  const NetifyWrapper({
    super.key,
    required this.child,
    this.entryMode = NetifyEntryMode.bubble,
  });

  void _openNetifyPanel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NetifyPanel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // Add bubble overlay if needed
    if (entryMode == NetifyEntryMode.bubble) {
      result = Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            result,
            NetifyBubble(
              onTap: () => _openNetifyPanel(context),
            ),
          ],
        ),
      );
    }

    return result;
  }
}
