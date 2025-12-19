import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/entities/network_log.dart';
import '../../netify_main.dart';
import '../theme/netify_theme.dart';
import '../widgets/log_list_tile.dart';
import '../widgets/search_bar.dart';
import 'insights_page.dart';
import 'log_detail_page.dart';

enum StatusFilter { all, success, clientError, serverError }

enum MethodFilter { all, get, post, put, patch, delete }

enum SortOption { newest, oldest, slowest, fastest, largest, smallest }

enum ViewMode { list, grouped }

class NetifyPanel extends StatefulWidget {
  const NetifyPanel({super.key});

  @override
  State<NetifyPanel> createState() => _NetifyPanelState();
}

class _NetifyPanelState extends State<NetifyPanel> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StatusFilter _statusFilter = StatusFilter.all;
  MethodFilter _methodFilter = MethodFilter.all;
  SortOption _sortOption = SortOption.newest;
  ViewMode _viewMode = ViewMode.list;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<bool>(
      stream: NetifyThemeController().themeStream,
      initialData: NetifyThemeController().isDarkMode,
      builder: (context, themeSnapshot) {
        return Scaffold(
          backgroundColor: NetifyColors.background,
          appBar: AppBar(
            backgroundColor: NetifyColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: NetifyColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Netify', style: NetifyTextStyles.appBarTitle),
            actions: [
              IconButton(
                icon: Icon(
                  _viewMode == ViewMode.grouped
                      ? Icons.view_list_rounded
                      : Icons.folder_outlined,
                  color: NetifyColors.textPrimary,
                ),
                onPressed: () => setState(() {
                  _viewMode = _viewMode == ViewMode.list
                      ? ViewMode.grouped
                      : ViewMode.list;
                }),
                tooltip: _viewMode == ViewMode.grouped
                    ? 'List View'
                    : 'Group by Domain',
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _hasActiveFilters
                      ? NetifyColors.primary
                      : NetifyColors.textPrimary,
                ),
                onPressed: _showFilterModal,
                tooltip: 'Filter',
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: NetifyColors.textPrimary),
                color: NetifyColors.surface,
                onSelected: (value) {
                  switch (value) {
                    case 'insights':
                      _openInsights();
                      break;
                    case 'export':
                      _showExportOptions();
                      break;
                    case 'theme':
                      NetifyThemeController().toggleTheme();
                      break;
                    case 'clear':
                      _confirmClearLogs();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'insights',
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded,
                            size: 20, color: NetifyColors.textSecondary),
                        const SizedBox(width: NetifySpacing.md),
                        Text('Insights', style: NetifyTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share,
                            size: 20, color: NetifyColors.textSecondary),
                        const SizedBox(width: NetifySpacing.md),
                        Text('Export', style: NetifyTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          NetifyColors.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                          color: NetifyColors.textSecondary,
                        ),
                        const SizedBox(width: NetifySpacing.md),
                        Text(
                          NetifyColors.isDarkMode ? 'Light Mode' : 'Dark Mode',
                          style: NetifyTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 20, color: NetifyColors.error),
                        const SizedBox(width: NetifySpacing.md),
                        Text('Clear Logs',
                            style: NetifyTextStyles.bodyMedium
                                .copyWith(color: NetifyColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              NetifySearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              Expanded(
                child: StreamBuilder<List<NetworkLog>>(
                  stream: Netify.logsStream,
                  initialData: Netify.logs,
                  builder: (context, logsSnapshot) {
                    return StreamBuilder<Set<String>>(
                      stream: Netify.favoritesStream,
                      initialData: Netify.favoriteIds,
                      builder: (context, favoritesSnapshot) {
                        var logs = _searchQuery.isEmpty
                            ? (logsSnapshot.data ?? [])
                            : Netify.searchLogs(_searchQuery);

                        logs = _applyFilters(logs);
                        final favoriteIds = favoritesSnapshot.data ?? {};

                        if (logs.isEmpty) {
                          return _buildEmptyState();
                        }

                        if (_viewMode == ViewMode.grouped) {
                          return _buildGroupedView(
                              logs, favoriteIds, bottomPadding);
                        }

                        return ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: NetifySpacing.lg + bottomPadding,
                          ),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return LogListTile(
                              log: log,
                              isFavorite: favoriteIds.contains(log.id),
                              onTap: () => _openLogDetail(log),
                              onFavoriteToggle: () =>
                                  Netify.toggleFavorite(log.id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: NetifyColors.textHint,
          ),
          const SizedBox(height: NetifySpacing.lg),
          Text(
            _searchQuery.isEmpty
                ? 'No network requests captured'
                : 'No results found',
            style: NetifyTextStyles.bodyMedium.copyWith(
              color: NetifyColors.textSecondary,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: NetifySpacing.sm),
            Text(
              'Make some API calls to see them here',
              style: NetifyTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedView(
      List<NetworkLog> logs, Set<String> favoriteIds, double bottomPadding) {
    final groupedLogs = <String, List<NetworkLog>>{};

    for (final log in logs) {
      final domain = _extractDomain(log.url);
      groupedLogs.putIfAbsent(domain, () => []).add(log);
    }

    final sortedDomains = groupedLogs.keys.toList()
      ..sort(
          (a, b) => groupedLogs[b]!.length.compareTo(groupedLogs[a]!.length));

    return ListView.builder(
      padding: EdgeInsets.only(bottom: NetifySpacing.lg + bottomPadding),
      itemCount: sortedDomains.length,
      itemBuilder: (context, index) {
        final domain = sortedDomains[index];
        final domainLogs = groupedLogs[domain]!;

        return _DomainGroup(
          domain: domain,
          logs: domainLogs,
          favoriteIds: favoriteIds,
          onLogTap: _openLogDetail,
          onFavoriteToggle: (logId) => Netify.toggleFavorite(logId),
        );
      },
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty ? 'Unknown' : uri.host;
    } catch (_) {
      return 'Unknown';
    }
  }

  bool get _hasActiveFilters =>
      _statusFilter != StatusFilter.all ||
      _methodFilter != MethodFilter.all ||
      _sortOption != SortOption.newest;

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NetifyColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(NetifyRadius.xl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(NetifySpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter & Sort',
                            style: NetifyTextStyles.appBarTitle),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _statusFilter = StatusFilter.all;
                                _methodFilter = MethodFilter.all;
                                _sortOption = SortOption.newest;
                              });
                              setState(() {});
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: NetifySpacing.lg),
                    Text('SORT BY', style: NetifyTextStyles.sectionTitle),
                    const SizedBox(height: NetifySpacing.sm),
                    Wrap(
                      spacing: NetifySpacing.sm,
                      runSpacing: NetifySpacing.sm,
                      children: [
                        _buildSortChip(
                            'Newest', SortOption.newest, setModalState),
                        _buildSortChip(
                            'Oldest', SortOption.oldest, setModalState),
                        _buildSortChip(
                            'Slowest', SortOption.slowest, setModalState),
                        _buildSortChip(
                            'Fastest', SortOption.fastest, setModalState),
                        _buildSortChip(
                            'Largest', SortOption.largest, setModalState),
                        _buildSortChip(
                            'Smallest', SortOption.smallest, setModalState),
                      ],
                    ),
                    const SizedBox(height: NetifySpacing.lg),
                    Text('STATUS', style: NetifyTextStyles.sectionTitle),
                    const SizedBox(height: NetifySpacing.sm),
                    Wrap(
                      spacing: NetifySpacing.sm,
                      children: [
                        _buildFilterChip('All', StatusFilter.all,
                            _statusFilter == StatusFilter.all, (selected) {
                          setModalState(() => _statusFilter = StatusFilter.all);
                          setState(() {});
                        }),
                        _buildFilterChip('2xx Success', StatusFilter.success,
                            _statusFilter == StatusFilter.success, (selected) {
                          setModalState(() => _statusFilter = selected
                              ? StatusFilter.success
                              : StatusFilter.all);
                          setState(() {});
                        }, color: NetifyColors.success),
                        _buildFilterChip(
                            '4xx Client Error',
                            StatusFilter.clientError,
                            _statusFilter == StatusFilter.clientError,
                            (selected) {
                          setModalState(() => _statusFilter = selected
                              ? StatusFilter.clientError
                              : StatusFilter.all);
                          setState(() {});
                        }, color: NetifyColors.warning),
                        _buildFilterChip(
                            '5xx Server Error',
                            StatusFilter.serverError,
                            _statusFilter == StatusFilter.serverError,
                            (selected) {
                          setModalState(() => _statusFilter = selected
                              ? StatusFilter.serverError
                              : StatusFilter.all);
                          setState(() {});
                        }, color: NetifyColors.error),
                      ],
                    ),
                    const SizedBox(height: NetifySpacing.lg),
                    Text('METHOD', style: NetifyTextStyles.sectionTitle),
                    const SizedBox(height: NetifySpacing.sm),
                    Wrap(
                      spacing: NetifySpacing.sm,
                      children: [
                        _buildFilterChip('All', MethodFilter.all,
                            _methodFilter == MethodFilter.all, (selected) {
                          setModalState(() => _methodFilter = MethodFilter.all);
                          setState(() {});
                        }),
                        _buildFilterChip('GET', MethodFilter.get,
                            _methodFilter == MethodFilter.get, (selected) {
                          setModalState(() => _methodFilter =
                              selected ? MethodFilter.get : MethodFilter.all);
                          setState(() {});
                        }, color: NetifyColors.success),
                        _buildFilterChip('POST', MethodFilter.post,
                            _methodFilter == MethodFilter.post, (selected) {
                          setModalState(() => _methodFilter =
                              selected ? MethodFilter.post : MethodFilter.all);
                          setState(() {});
                        }, color: NetifyColors.primary),
                        _buildFilterChip('PUT', MethodFilter.put,
                            _methodFilter == MethodFilter.put, (selected) {
                          setModalState(() => _methodFilter =
                              selected ? MethodFilter.put : MethodFilter.all);
                          setState(() {});
                        }, color: NetifyColors.warning),
                        _buildFilterChip('DELETE', MethodFilter.delete,
                            _methodFilter == MethodFilter.delete, (selected) {
                          setModalState(() => _methodFilter = selected
                              ? MethodFilter.delete
                              : MethodFilter.all);
                          setState(() {});
                        }, color: NetifyColors.error),
                      ],
                    ),
                    const SizedBox(height: NetifySpacing.lg),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
      String label, SortOption option, StateSetter setModalState) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() => _sortOption = option);
        setState(() {});
      },
      selectedColor: NetifyColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? NetifyColors.primary : NetifyColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? NetifyColors.primary : NetifyColors.border,
      ),
    );
  }

  Widget _buildFilterChip<T>(
      String label, T value, bool isSelected, ValueChanged<bool> onSelected,
      {Color? color}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: (color ?? NetifyColors.primary).withValues(alpha: 0.2),
      checkmarkColor: color ?? NetifyColors.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? (color ?? NetifyColors.primary)
            : NetifyColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color:
            isSelected ? (color ?? NetifyColors.primary) : NetifyColors.border,
      ),
    );
  }

  List<NetworkLog> _applyFilters(List<NetworkLog> logs) {
    final filtered = logs.where((log) {
      // Apply status filter
      if (_statusFilter != StatusFilter.all) {
        final statusCode = log.statusCode;
        if (statusCode == null) return false;

        switch (_statusFilter) {
          case StatusFilter.success:
            if (statusCode < 200 || statusCode >= 300) return false;
            break;
          case StatusFilter.clientError:
            if (statusCode < 400 || statusCode >= 500) return false;
            break;
          case StatusFilter.serverError:
            if (statusCode < 500) return false;
            break;
          case StatusFilter.all:
            break;
        }
      }

      // Apply method filter
      if (_methodFilter != MethodFilter.all) {
        final method = log.method.toUpperCase();
        switch (_methodFilter) {
          case MethodFilter.get:
            if (method != 'GET') return false;
            break;
          case MethodFilter.post:
            if (method != 'POST') return false;
            break;
          case MethodFilter.put:
            if (method != 'PUT') return false;
            break;
          case MethodFilter.patch:
            if (method != 'PATCH') return false;
            break;
          case MethodFilter.delete:
            if (method != 'DELETE') return false;
            break;
          case MethodFilter.all:
            break;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => b.requestTime.compareTo(a.requestTime));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.requestTime.compareTo(b.requestTime));
        break;
      case SortOption.slowest:
        filtered.sort((a, b) => (b.duration?.inMilliseconds ?? 0)
            .compareTo(a.duration?.inMilliseconds ?? 0));
        break;
      case SortOption.fastest:
        filtered.sort((a, b) => (a.duration?.inMilliseconds ?? 0)
            .compareTo(b.duration?.inMilliseconds ?? 0));
        break;
      case SortOption.largest:
        filtered.sort(
            (a, b) => (b.responseSize ?? 0).compareTo(a.responseSize ?? 0));
        break;
      case SortOption.smallest:
        filtered.sort(
            (a, b) => (a.responseSize ?? 0).compareTo(b.responseSize ?? 0));
        break;
    }

    return filtered;
  }

  void _openLogDetail(NetworkLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogDetailPage(log: log),
      ),
    );
  }

  void _openInsights() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InsightsPage(),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NetifyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(NetifyRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(NetifySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Logs',
                  style: NetifyTextStyles.appBarTitle,
                ),
                const SizedBox(height: NetifySpacing.lg),
                _buildExportOption(
                  icon: Icons.copy,
                  title: 'Copy as JSON',
                  onTap: () {
                    Navigator.pop(context);
                    _copyAs('json');
                  },
                ),
                _buildExportOption(
                  icon: Icons.copy_all,
                  title: 'Copy as HAR',
                  onTap: () {
                    Navigator.pop(context);
                    _copyAs('har');
                  },
                ),
                const Divider(height: NetifySpacing.lg),
                _buildExportOption(
                  icon: Icons.save_alt,
                  title: 'Save to File (JSON)',
                  onTap: () {
                    Navigator.pop(context);
                    _saveToFile('json');
                  },
                ),
                _buildExportOption(
                  icon: Icons.save_alt,
                  title: 'Save to File (HAR)',
                  onTap: () {
                    Navigator.pop(context);
                    _saveToFile('har');
                  },
                ),
                const Divider(height: NetifySpacing.lg),
                _buildExportOption(
                  icon: Icons.share,
                  title: 'Share Logs',
                  onTap: () {
                    Navigator.pop(context);
                    _shareLogs();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: NetifyColors.primary),
      title: Text(title, style: NetifyTextStyles.bodyMedium),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _copyAs(String format) {
    String content;
    switch (format) {
      case 'json':
        content = Netify.exportAsJson();
        break;
      case 'har':
        content = Netify.exportAsHar();
        break;
      default:
        return;
    }

    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${format.toUpperCase()} copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveToFile(String format) async {
    try {
      String content;
      String extension;
      switch (format) {
        case 'json':
          content = Netify.exportAsJson();
          extension = 'json';
          break;
        case 'har':
          content = Netify.exportAsHar();
          extension = 'har';
          break;
        default:
          return;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/netify_logs_$timestamp.$extension');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Netify Logs ($extension)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: ${e.toString()}'),
            backgroundColor: NetifyColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareLogs() async {
    final json = Netify.exportAsJson();
    await Share.share(
      json,
      subject: 'Netify Network Logs',
    );
  }

  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Logs'),
          content:
              const Text('Are you sure you want to clear all network logs?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Netify.clearLogs();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: NetifyColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DomainGroup extends StatefulWidget {
  final String domain;
  final List<NetworkLog> logs;
  final Set<String> favoriteIds;
  final void Function(NetworkLog) onLogTap;
  final void Function(String) onFavoriteToggle;

  const _DomainGroup({
    required this.domain,
    required this.logs,
    required this.favoriteIds,
    required this.onLogTap,
    required this.onFavoriteToggle,
  });

  @override
  State<_DomainGroup> createState() => _DomainGroupState();
}

class _DomainGroupState extends State<_DomainGroup> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final successCount = widget.logs.where((l) => l.isSuccess).length;
    final errorCount = widget.logs.where((l) => l.isError).length;
    final pendingCount = widget.logs.where((l) => l.isPending).length;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: NetifySpacing.lg,
        vertical: NetifySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: NetifyColors.surface,
        borderRadius: BorderRadius.circular(NetifyRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(NetifyRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(NetifySpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.dns_outlined,
                    size: 20,
                    color: NetifyColors.primary,
                  ),
                  const SizedBox(width: NetifySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.domain,
                          style: NetifyTextStyles.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${widget.logs.length} requests',
                              style: NetifyTextStyles.bodySmall,
                            ),
                            if (successCount > 0) ...[
                              const SizedBox(width: NetifySpacing.sm),
                              _buildBadge(
                                  '$successCount', NetifyColors.success),
                            ],
                            if (errorCount > 0) ...[
                              const SizedBox(width: NetifySpacing.xs),
                              _buildBadge('$errorCount', NetifyColors.error),
                            ],
                            if (pendingCount > 0) ...[
                              const SizedBox(width: NetifySpacing.xs),
                              _buildBadge(
                                  '$pendingCount', NetifyColors.textHint),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: NetifyColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: NetifyColors.divider),
            ...widget.logs.map((log) => LogListTile(
                  log: log,
                  isFavorite: widget.favoriteIds.contains(log.id),
                  onTap: () => widget.onLogTap(log),
                  onFavoriteToggle: () => widget.onFavoriteToggle(log.id),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
