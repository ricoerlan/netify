import 'package:flutter/material.dart';

import '../../core/entities/network_log.dart';
import '../../netify_main.dart';
import '../theme/netify_theme.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetifyColors.background,
      appBar: AppBar(
        backgroundColor: NetifyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: NetifyColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            Text('Performance Insights', style: NetifyTextStyles.appBarTitle),
      ),
      body: StreamBuilder<List<NetworkLog>>(
        stream: Netify.logsStream,
        initialData: Netify.logs,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          final stats = _calculateStats(logs);

          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(NetifySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(stats),
                const SizedBox(height: NetifySpacing.xl),
                _buildStatusBreakdown(stats),
                const SizedBox(height: NetifySpacing.xl),
                _buildMethodBreakdown(stats),
                const SizedBox(height: NetifySpacing.xl),
                _buildPerformanceMetrics(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: NetifyColors.textHint,
          ),
          const SizedBox(height: NetifySpacing.lg),
          Text(
            'No data to analyze',
            style: NetifyTextStyles.bodyMedium,
          ),
          const SizedBox(height: NetifySpacing.sm),
          Text(
            'Make some API calls to see insights',
            style: NetifyTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(_InsightStats stats) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.speed_rounded,
            label: 'Avg Response',
            value: '${stats.avgResponseTime.toStringAsFixed(0)}ms',
            color: NetifyColors.primary,
          ),
        ),
        const SizedBox(width: NetifySpacing.md),
        Expanded(
          child: _InsightCard(
            icon: Icons.error_outline_rounded,
            label: 'Error Rate',
            value: '${stats.errorRate.toStringAsFixed(1)}%',
            color: stats.errorRate > 10
                ? NetifyColors.error
                : NetifyColors.success,
          ),
        ),
        const SizedBox(width: NetifySpacing.md),
        Expanded(
          child: _InsightCard(
            icon: Icons.data_usage_rounded,
            label: 'Total Data',
            value: _formatBytes(stats.totalDataUsage),
            color: NetifyColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(_InsightStats stats) {
    return _SectionContainer(
      title: 'STATUS BREAKDOWN',
      child: Column(
        children: [
          _ProgressRow(
            label: '2xx Success',
            value: stats.successCount,
            total: stats.totalRequests,
            color: NetifyColors.success,
          ),
          const SizedBox(height: NetifySpacing.md),
          _ProgressRow(
            label: '3xx Redirect',
            value: stats.redirectCount,
            total: stats.totalRequests,
            color: NetifyColors.warning,
          ),
          const SizedBox(height: NetifySpacing.md),
          _ProgressRow(
            label: '4xx Client Error',
            value: stats.clientErrorCount,
            total: stats.totalRequests,
            color: NetifyColors.error,
          ),
          const SizedBox(height: NetifySpacing.md),
          _ProgressRow(
            label: '5xx Server Error',
            value: stats.serverErrorCount,
            total: stats.totalRequests,
            color: const Color(0xFFDC2626),
          ),
          const SizedBox(height: NetifySpacing.md),
          _ProgressRow(
            label: 'Pending',
            value: stats.pendingCount,
            total: stats.totalRequests,
            color: NetifyColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBreakdown(_InsightStats stats) {
    return _SectionContainer(
      title: 'METHOD BREAKDOWN',
      child: Wrap(
        spacing: NetifySpacing.md,
        runSpacing: NetifySpacing.md,
        children: stats.methodCounts.entries.map((entry) {
          return _MethodChip(
            method: entry.key,
            count: entry.value,
            color: NetifyColors.getMethodColor(entry.key),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceMetrics(_InsightStats stats) {
    return _SectionContainer(
      title: 'PERFORMANCE METRICS',
      child: Column(
        children: [
          _MetricRow(
            label: 'Total Requests',
            value: stats.totalRequests.toString(),
          ),
          Divider(height: NetifySpacing.lg, color: NetifyColors.divider),
          _MetricRow(
            label: 'Fastest Response',
            value: stats.fastestResponse != null
                ? '${stats.fastestResponse}ms'
                : '-',
          ),
          Divider(height: NetifySpacing.lg, color: NetifyColors.divider),
          _MetricRow(
            label: 'Slowest Response',
            value: stats.slowestResponse != null
                ? '${stats.slowestResponse}ms'
                : '-',
          ),
          Divider(height: NetifySpacing.lg, color: NetifyColors.divider),
          _MetricRow(
            label: 'Avg Response Size',
            value: _formatBytes(stats.avgResponseSize.toInt()),
          ),
        ],
      ),
    );
  }

  _InsightStats _calculateStats(List<NetworkLog> logs) {
    if (logs.isEmpty) {
      return _InsightStats.empty();
    }

    int successCount = 0;
    int redirectCount = 0;
    int clientErrorCount = 0;
    int serverErrorCount = 0;
    int pendingCount = 0;
    int totalDataUsage = 0;
    int totalResponseTime = 0;
    int responseTimeCount = 0;
    int? fastestResponse;
    int? slowestResponse;
    int totalResponseSize = 0;
    int responseSizeCount = 0;
    final Map<String, int> methodCounts = {};

    for (final log in logs) {
      // Status breakdown
      final statusCode = log.statusCode;
      if (statusCode == null) {
        pendingCount++;
      } else if (statusCode >= 200 && statusCode < 300) {
        successCount++;
      } else if (statusCode >= 300 && statusCode < 400) {
        redirectCount++;
      } else if (statusCode >= 400 && statusCode < 500) {
        clientErrorCount++;
      } else if (statusCode >= 500) {
        serverErrorCount++;
      }

      // Method breakdown
      final method = log.method.toUpperCase();
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;

      // Response time
      if (log.duration != null) {
        final ms = log.duration!.inMilliseconds;
        totalResponseTime += ms;
        responseTimeCount++;

        if (fastestResponse == null || ms < fastestResponse) {
          fastestResponse = ms;
        }
        if (slowestResponse == null || ms > slowestResponse) {
          slowestResponse = ms;
        }
      }

      // Data usage
      if (log.responseSize != null) {
        totalDataUsage += log.responseSize!;
        totalResponseSize += log.responseSize!;
        responseSizeCount++;
      }
    }

    final totalRequests = logs.length;
    final errorCount = clientErrorCount + serverErrorCount;
    final completedRequests = totalRequests - pendingCount;

    return _InsightStats(
      totalRequests: totalRequests,
      successCount: successCount,
      redirectCount: redirectCount,
      clientErrorCount: clientErrorCount,
      serverErrorCount: serverErrorCount,
      pendingCount: pendingCount,
      avgResponseTime:
          responseTimeCount > 0 ? totalResponseTime / responseTimeCount : 0,
      errorRate:
          completedRequests > 0 ? (errorCount / completedRequests) * 100 : 0,
      totalDataUsage: totalDataUsage,
      methodCounts: methodCounts,
      fastestResponse: fastestResponse,
      slowestResponse: slowestResponse,
      avgResponseSize:
          responseSizeCount > 0 ? totalResponseSize / responseSizeCount : 0,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _InsightStats {
  final int totalRequests;
  final int successCount;
  final int redirectCount;
  final int clientErrorCount;
  final int serverErrorCount;
  final int pendingCount;
  final double avgResponseTime;
  final double errorRate;
  final int totalDataUsage;
  final Map<String, int> methodCounts;
  final int? fastestResponse;
  final int? slowestResponse;
  final double avgResponseSize;

  _InsightStats({
    required this.totalRequests,
    required this.successCount,
    required this.redirectCount,
    required this.clientErrorCount,
    required this.serverErrorCount,
    required this.pendingCount,
    required this.avgResponseTime,
    required this.errorRate,
    required this.totalDataUsage,
    required this.methodCounts,
    required this.fastestResponse,
    required this.slowestResponse,
    required this.avgResponseSize,
  });

  factory _InsightStats.empty() {
    return _InsightStats(
      totalRequests: 0,
      successCount: 0,
      redirectCount: 0,
      clientErrorCount: 0,
      serverErrorCount: 0,
      pendingCount: 0,
      avgResponseTime: 0,
      errorRate: 0,
      totalDataUsage: 0,
      methodCounts: {},
      fastestResponse: null,
      slowestResponse: null,
      avgResponseSize: 0,
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NetifySpacing.md),
      decoration: BoxDecoration(
        color: NetifyColors.surface,
        borderRadius: BorderRadius.circular(NetifyRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: NetifySpacing.sm),
          Text(
            value,
            style: NetifyTextStyles.metricValue.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: NetifyTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetifySpacing.lg),
      decoration: BoxDecoration(
        color: NetifyColors.surface,
        borderRadius: BorderRadius.circular(NetifyRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NetifyTextStyles.sectionTitle),
          const SizedBox(height: NetifySpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: NetifyTextStyles.bodySmall),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(1)}%)',
              style: NetifyTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: NetifySpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: NetifyColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String method;
  final int count;
  final Color color;

  const _MethodChip({
    required this.method,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NetifySpacing.md,
        vertical: NetifySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(NetifyRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            method,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: NetifySpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: NetifyTextStyles.bodyMedium),
        Text(
          value,
          style: NetifyTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: NetifyColors.primary,
          ),
        ),
      ],
    );
  }
}
