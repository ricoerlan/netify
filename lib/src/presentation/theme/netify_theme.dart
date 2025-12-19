import 'dart:async';

import 'package:flutter/material.dart';

class NetifyThemeController {
  static final NetifyThemeController _instance =
      NetifyThemeController._internal();
  factory NetifyThemeController() => _instance;
  NetifyThemeController._internal();

  bool _isDarkMode = false;
  final _themeController = StreamController<bool>.broadcast();

  bool get isDarkMode => _isDarkMode;
  Stream<bool> get themeStream => _themeController.stream;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeController.add(_isDarkMode);
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _themeController.add(_isDarkMode);
  }

  void dispose() {
    _themeController.close();
  }
}

class NetifyColors {
  static NetifyThemeController get _controller => NetifyThemeController();
  static bool get isDarkMode => _controller.isDarkMode;

  // Slate Scale
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Dynamic colors based on theme
  static Color get background => isDarkMode ? slate900 : slate50;
  static Color get surface => isDarkMode ? slate800 : Colors.white;
  static const Color primary = Color(0xFF3B82F6); // Blue 500

  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  static Color get textPrimary => isDarkMode ? slate50 : slate900;
  static Color get textSecondary => isDarkMode ? slate400 : slate500;
  static Color get textHint => isDarkMode ? slate500 : slate400;

  static Color get border => isDarkMode ? slate700 : slate200;
  static Color get divider => isDarkMode ? slate700 : slate100;

  // Softer backgrounds for alerts
  static Color get errorBackground =>
      isDarkMode ? error.withValues(alpha: 0.15) : const Color(0xFFFEF2F2);
  static Color get successBackground =>
      isDarkMode ? success.withValues(alpha: 0.15) : const Color(0xFFECFDF5);
  static Color get warningBackground =>
      isDarkMode ? warning.withValues(alpha: 0.15) : const Color(0xFFFFFBEB);

  static Color getStatusColor(int? statusCode) {
    if (statusCode == null) return textHint;
    if (statusCode >= 200 && statusCode < 300) return success;
    if (statusCode >= 300 && statusCode < 400) return warning;
    if (statusCode >= 400) return error;
    return textHint;
  }

  static Color getStatusBackgroundColor(int? statusCode) {
    final baseColor = isDarkMode ? slate700 : slate100;
    if (statusCode == null) return baseColor;
    if (statusCode >= 200 && statusCode < 300) {
      return success.withValues(alpha: 0.1);
    }
    if (statusCode >= 300 && statusCode < 400) {
      return warning.withValues(alpha: 0.1);
    }
    if (statusCode >= 400) return error.withValues(alpha: 0.1);
    return baseColor;
  }

  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF10B981); // Emerald 500
      case 'POST':
        return const Color(0xFF3B82F6); // Blue 500
      case 'PUT':
        return const Color(0xFFF59E0B); // Amber 500
      case 'DELETE':
        return const Color(0xFFEF4444); // Red 500
      case 'PATCH':
        return const Color(0xFF8B5CF6); // Violet 500
      default:
        return isDarkMode ? slate400 : slate500;
    }
  }
}

class NetifyTextStyles {
  static TextStyle get appBarTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NetifyColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: NetifyColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: NetifyColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: NetifyColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: NetifyColors.textSecondary,
        letterSpacing: 0.2,
      );

  static const TextStyle methodBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle statusBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get metricValue => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NetifyColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get metricLabel => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: NetifyColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get url => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: NetifyColors.textPrimary,
        height: 1.4,
      );

  static const TextStyle errorText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: NetifyColors.error,
    height: 1.5,
  );

  static TextStyle get monospace => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
        color: NetifyColors.textPrimary,
      );
}

class NetifySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class NetifyRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
}
