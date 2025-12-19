import 'package:flutter/material.dart';

import '../../core/entities/network_log.dart';
import '../theme/netify_theme.dart';

class LogListTile extends StatelessWidget {
  final NetworkLog log;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const LogListTile({
    super.key,
    required this.log,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: NetifySpacing.lg,
          vertical: NetifySpacing.sm,
        ),
        padding: const EdgeInsets.all(NetifySpacing.md),
        decoration: BoxDecoration(
          color: NetifyColors.surface,
          borderRadius: BorderRadius.circular(NetifyRadius.lg),
          border: isFavorite
              ? Border.all(
                  color: NetifyColors.warning.withValues(alpha: 0.3), width: 1)
              : null,
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
            _buildTopRow(),
            const SizedBox(height: NetifySpacing.xs),
            Text(
              _formatUrl(log.url),
              style: NetifyTextStyles.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: NetifySpacing.md),
            _buildMetricsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color:
                NetifyColors.getMethodColor(log.method).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(NetifyRadius.sm),
          ),
          child: Text(
            log.method.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NetifyColors.getMethodColor(log.method),
            ),
          ),
        ),
        if (isFavorite) ...[
          const SizedBox(width: NetifySpacing.sm),
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: NetifyColors.warning,
          ),
        ],
        const Spacer(),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final color = NetifyColors.getStatusColor(log.statusCode);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: NetifySpacing.xs),
        Text(
          log.statusCode?.toString() ?? '...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetricItem(
          log.formattedRequestTime,
          Icons.access_time_rounded,
        ),
        const SizedBox(width: NetifySpacing.lg),
        _buildMetricItem(
          log.formattedDuration,
          Icons.timer_outlined,
        ),
        const Spacer(),
        Text(
          log.formattedResponseSize,
          style: NetifyTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: NetifyColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: NetifyColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: NetifyTextStyles.bodySmall.copyWith(
            color: NetifyColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}${uri.path}';
    } catch (_) {
      return url;
    }
  }
}
