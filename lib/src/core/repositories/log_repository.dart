import '../entities/network_log.dart';

abstract class LogRepository {
  Stream<List<NetworkLog>> get logsStream;
  List<NetworkLog> get logs;
  int get logCount;

  Set<String> get favoriteIds;
  Stream<Set<String>> get favoritesStream;

  void addLog(NetworkLog log);
  void updateLog(NetworkLog log);
  void clearLogs();
  List<NetworkLog> searchLogs(String query);

  void toggleFavorite(String logId);
  bool isFavorite(String logId);
  List<NetworkLog> get favoriteLogs;

  void dispose();
}
