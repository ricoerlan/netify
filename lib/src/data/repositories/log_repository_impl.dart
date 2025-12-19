import 'dart:async';
import 'dart:convert';

import '../../core/entities/network_log.dart';
import '../../core/entities/netify_config.dart';
import '../../core/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  final NetifyConfig config;
  final List<NetworkLog> _logs = [];
  final Set<String> _favoriteIds = {};
  final _logsController = StreamController<List<NetworkLog>>.broadcast();
  final _favoritesController = StreamController<Set<String>>.broadcast();

  LogRepositoryImpl({required this.config});

  @override
  Stream<List<NetworkLog>> get logsStream => _logsController.stream;

  @override
  List<NetworkLog> get logs => List.unmodifiable(_logs);

  @override
  int get logCount => _logs.length;

  @override
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  @override
  Stream<Set<String>> get favoritesStream => _favoritesController.stream;

  @override
  void addLog(NetworkLog log) {
    _logs.insert(0, log);

    if (_logs.length > config.maxLogs) {
      _logs.removeLast();
    }

    _notifyListeners();
  }

  @override
  void updateLog(NetworkLog log) {
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      _logs[index] = log;
      _notifyListeners();
    }
  }

  @override
  void clearLogs() {
    _logs.clear();
    _notifyListeners();
  }

  @override
  List<NetworkLog> searchLogs(String query) {
    if (query.isEmpty) return logs;

    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      // Search in URL
      if (log.url.toLowerCase().contains(lowerQuery)) return true;

      // Search in method
      if (log.method.toLowerCase().contains(lowerQuery)) return true;

      // Search in status code
      if (log.statusCode?.toString().contains(lowerQuery) ?? false) return true;

      // Search in request body
      if (_searchInBody(log.requestBody, lowerQuery)) return true;

      // Search in response body
      if (_searchInBody(log.responseBody, lowerQuery)) return true;

      return false;
    }).toList();
  }

  bool _searchInBody(dynamic body, String query) {
    if (body == null) return false;

    String bodyString;
    if (body is String) {
      bodyString = body;
    } else if (body is Map || body is List) {
      try {
        bodyString = jsonEncode(body);
      } catch (_) {
        bodyString = body.toString();
      }
    } else {
      bodyString = body.toString();
    }

    return bodyString.toLowerCase().contains(query);
  }

  @override
  void toggleFavorite(String logId) {
    if (_favoriteIds.contains(logId)) {
      _favoriteIds.remove(logId);
    } else {
      _favoriteIds.add(logId);
    }
    _notifyFavorites();
  }

  @override
  bool isFavorite(String logId) => _favoriteIds.contains(logId);

  @override
  List<NetworkLog> get favoriteLogs =>
      _logs.where((log) => _favoriteIds.contains(log.id)).toList();

  @override
  void dispose() {
    _logsController.close();
    _favoritesController.close();
  }

  void _notifyListeners() {
    _logsController.add(List.unmodifiable(_logs));
  }

  void _notifyFavorites() {
    _favoritesController.add(Set.unmodifiable(_favoriteIds));
  }
}
