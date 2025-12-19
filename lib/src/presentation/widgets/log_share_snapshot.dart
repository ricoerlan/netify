import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/entities/network_log.dart';
import '../theme/netify_theme.dart';

class LogShareSnapshot extends StatefulWidget {
  final NetworkLog log;

  const LogShareSnapshot({
    super.key,
    required this.log,
  });

  @override
  State<LogShareSnapshot> createState() => _LogShareSnapshotState();
}

class _LogShareSnapshotState extends State<LogShareSnapshot> {
  Future<String> _getAppName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.appName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375, // Standard mobile width (iPhone)
      padding: const EdgeInsets.all(NetifySpacing.lg),
      color: NetifyColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: NetifyColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(NetifyRadius.sm),
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  color: NetifyColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: NetifySpacing.sm),
              Expanded(
                child: FutureBuilder<String>(
                  future: _getAppName(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'App',
                      style: NetifyTextStyles.appBarTitle.copyWith(
                        color: NetifyColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: NetifySpacing.sm),

          // Meta info row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: NetifySpacing.sm, vertical: NetifySpacing.xs),
            decoration: BoxDecoration(
              color: NetifyColors.surface,
              borderRadius: BorderRadius.circular(NetifyRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem(Icons.schedule, widget.log.formattedRequestTime),
                _buildMetaItem(
                    Icons.straighten, widget.log.formattedResponseSize),
                _buildMetaItem(
                    Icons.timer_outlined, widget.log.formattedDuration,
                    isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: NetifySpacing.md),

          // URL Section
          Container(
            padding: const EdgeInsets.all(NetifySpacing.sm),
            decoration: BoxDecoration(
              color: NetifyColors.surface,
              borderRadius: BorderRadius.circular(NetifyRadius.md),
              border: Border.all(color: NetifyColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: NetifyColors.getMethodColor(widget.log.method)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(NetifyRadius.sm),
                      ),
                      child: Text(
                        widget.log.method.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NetifyColors.getMethodColor(widget.log.method),
                        ),
                      ),
                    ),
                    const SizedBox(width: NetifySpacing.sm),
                    Expanded(
                      child: Text(
                        widget.log.url,
                        style: NetifyTextStyles.url.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (widget.log.error != null || widget.log.isError) ...[
            const SizedBox(height: NetifySpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(NetifySpacing.sm),
              decoration: BoxDecoration(
                color: NetifyColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(NetifyRadius.md),
                border: Border.all(
                    color: NetifyColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ERROR DETAILS',
                    style: NetifyTextStyles.sectionTitle.copyWith(
                      fontSize: 11,
                      color: NetifyColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.log.error ??
                        widget.log.statusMessage ??
                        _getStatusPhrase(widget.log.statusCode ?? 0),
                    style: NetifyTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: NetifyColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.log.requestBody != null ||
              (widget.log.requestHeaders?.isNotEmpty ?? false)) ...[
            const SizedBox(height: NetifySpacing.sm),
            _buildSection(
              title: 'REQUEST',
              headers: widget.log.requestHeaders,
              body: widget.log.requestBody,
            ),
          ],

          if (widget.log.responseBody != null ||
              (widget.log.responseHeaders?.isNotEmpty ?? false)) ...[
            const SizedBox(height: NetifySpacing.sm),
            _buildSection(
              title: 'RESPONSE',
              headers: widget.log.responseHeaders,
              body: widget.log.responseBody,
            ),
          ],

          // Footer Watermark
          const SizedBox(height: NetifySpacing.md),
          Center(
            child: Text(
              'Generated by Netify',
              style: NetifyTextStyles.bodySmall.copyWith(
                color: NetifyColors.textHint,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    return Container(
      padding: const EdgeInsets.all(NetifySpacing.sm),
      decoration: BoxDecoration(
        color: NetifyColors.surface,
        borderRadius: BorderRadius.circular(NetifyRadius.md),
        border: Border.all(color: NetifyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: NetifyTextStyles.sectionTitle.copyWith(fontSize: 11),
          ),
          const Divider(height: NetifySpacing.md),
          if (headers != null && headers.isNotEmpty) ...[
            Text(
              'HEADERS',
              style: NetifyTextStyles.labelSmall.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 2),
            ...headers.entries.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: NetifyTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: NetifyColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          style:
                              NetifyTextStyles.bodySmall.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            if (headers.length > 3)
              Text(
                '... (+${headers.length - 3} more)',
                style: NetifyTextStyles.bodySmall.copyWith(
                  color: NetifyColors.textHint,
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                ),
              ),
            const SizedBox(height: NetifySpacing.sm),
          ],
          if (body != null) ...[
            Text(
              'BODY',
              style: NetifyTextStyles.labelSmall.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(NetifySpacing.xs),
              decoration: BoxDecoration(
                color: NetifyColors.background,
                borderRadius: BorderRadius.circular(NetifyRadius.sm),
              ),
              child: Text(
                _formatBody(body),
                style: NetifyTextStyles.monospace.copyWith(
                  fontSize: 9,
                  color: NetifyColors.textPrimary,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBody(dynamic body) {
    if (body == null) return 'null';
    try {
      if (body is String) {
        try {
          final decoded = jsonDecode(body);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return body;
        }
      }
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  Widget _buildMetaItem(IconData icon, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isHighlight ? NetifyColors.success : NetifyColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: NetifyTextStyles.labelSmall.copyWith(
            fontSize: 10,
            color:
                isHighlight ? NetifyColors.success : NetifyColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = NetifyColors.getStatusColor(widget.log.statusCode);
    String statusText = 'Pending';

    if (widget.log.statusCode != null) {
      final code = widget.log.statusCode!;
      final message = widget.log.statusMessage ?? _getStatusPhrase(code);
      statusText = '$code${message.isNotEmpty ? ' $message' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(NetifyRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getStatusPhrase(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 204:
        return 'No Content';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 304:
        return 'Not Modified';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 408:
        return 'Request Timeout';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Internal Server Error';
      case 501:
        return 'Not Implemented';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return '';
    }
  }
}
