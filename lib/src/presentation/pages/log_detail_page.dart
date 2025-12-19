import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:screenshot/screenshot.dart';

import '../../core/entities/network_log.dart';
import '../../netify_main.dart';
import '../theme/netify_theme.dart';
import '../widgets/detail_row.dart';
import '../widgets/error_card.dart';
import '../widgets/json_section_card.dart';
import '../widgets/log_share_snapshot.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_card.dart';

class LogDetailPage extends StatefulWidget {
  final NetworkLog log;

  const LogDetailPage({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetifyColors.background,
      appBar: AppBar(
        backgroundColor: NetifyColors.surface,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: NetifyColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.log.method.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NetifyColors.getMethodColor(widget.log.method),
              ),
            ),
            const SizedBox(width: NetifySpacing.md),
            Text(
              widget.log.statusCode?.toString() ?? '...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NetifyColors.getStatusColor(widget.log.statusCode),
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<Set<String>>(
            stream: Netify.favoritesStream,
            initialData: Netify.favoriteIds,
            builder: (context, snapshot) {
              final isFavorite = (snapshot.data ?? {}).contains(widget.log.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite
                      ? NetifyColors.warning
                      : NetifyColors.textPrimary,
                  size: 22,
                ),
                onPressed: () => Netify.toggleFavorite(widget.log.id),
                tooltip:
                    isFavorite ? 'Remove from favorites' : 'Add to favorites',
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: NetifyColors.textPrimary, size: 22),
            onPressed: _replayRequest,
            tooltip: 'Replay',
          ),
          IconButton(
            icon: Icon(Icons.share, color: NetifyColors.textPrimary, size: 22),
            onPressed: _showShareOptions,
            tooltip: 'Share',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: NetifyColors.primary,
          unselectedLabelColor: NetifyColors.textHint,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          indicatorColor: NetifyColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: NetifyColors.divider,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Request'),
            Tab(text: 'Response'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRequestTab(),
          _buildResponseTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg + bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsRow(),
          const SizedBox(height: NetifySpacing.md),
          SectionCard(
            title: 'Request URL',
            content: widget.log.url,
            showCopyButton: true,
          ),
          const SizedBox(height: NetifySpacing.md),
          _buildRequestDetails(),
          if (widget.log.error != null) ...[
            const SizedBox(height: NetifySpacing.md),
            ErrorCard(error: widget.log.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            icon: Icons.access_time,
            label: 'Time',
            value: widget.log.formattedRequestTime,
          ),
        ),
        const SizedBox(width: NetifySpacing.sm),
        Expanded(
          child: MetricCard(
            icon: Icons.data_usage,
            label: 'Size',
            value: widget.log.formattedResponseSize,
          ),
        ),
        const SizedBox(width: NetifySpacing.sm),
        Expanded(
          child: MetricCard(
            icon: Icons.bolt,
            label: 'Duration',
            value: widget.log.formattedDuration,
            valueColor: NetifyColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: NetifyColors.surface,
        borderRadius: BorderRadius.circular(NetifyRadius.md),
        border: Border.all(color: NetifyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(NetifySpacing.md),
            child: Text(
              'REQUEST DETAILS',
              style: NetifyTextStyles.sectionTitle,
            ),
          ),
          Divider(height: 1, color: NetifyColors.divider),
          Padding(
            padding: const EdgeInsets.all(NetifySpacing.md),
            child: Column(
              children: [
                DetailRow(label: 'Method', value: widget.log.method),
                DetailRow(
                  label: 'Status Code',
                  value: widget.log.statusCode?.toString() ?? '-',
                ),
                DetailRow(
                  label: 'Status',
                  value: _getStatusText(),
                  valueColor: _getStatusColor(),
                ),
                DetailRow(
                  label: 'Timestamp',
                  value: widget.log.formattedTimestamp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (widget.log.isPending) return 'Pending';
    if (widget.log.isSuccess) return 'Success';
    if (widget.log.isError) return 'Error';
    return 'Unknown';
  }

  Color _getStatusColor() {
    if (widget.log.isPending) return NetifyColors.textHint;
    if (widget.log.isSuccess) return NetifyColors.success;
    if (widget.log.isError) return NetifyColors.error;
    return NetifyColors.textSecondary;
  }

  Widget _buildRequestTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg + bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.log.requestHeaders != null &&
              widget.log.requestHeaders!.isNotEmpty) ...[
            SectionCard(
              title: 'Headers',
              content: _formatHeaders(widget.log.requestHeaders!),
            ),
            const SizedBox(height: NetifySpacing.lg),
          ],
          if (widget.log.requestBody != null) ...[
            JsonSectionCard(
              title: 'Body',
              data: widget.log.requestBody,
              showCopyButton: true,
            ),
          ],
          if (widget.log.requestHeaders == null &&
              widget.log.requestBody == null)
            _buildEmptySection('No request data'),
        ],
      ),
    );
  }

  Widget _buildResponseTab() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg,
        NetifySpacing.lg + bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.log.responseHeaders != null &&
              widget.log.responseHeaders!.isNotEmpty) ...[
            SectionCard(
              title: 'Headers',
              content: _formatHeaders(widget.log.responseHeaders!),
            ),
            const SizedBox(height: NetifySpacing.md),
          ],
          if (widget.log.responseBody != null) ...[
            JsonSectionCard(
              title: 'Body',
              data: widget.log.responseBody,
              showCopyButton: true,
            ),
          ],
          if (widget.log.responseHeaders == null &&
              widget.log.responseBody == null)
            _buildEmptySection('No response data'),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NetifySpacing.xl),
        child: Text(
          message,
          style: NetifyTextStyles.bodyMedium.copyWith(
            color: NetifyColors.textHint,
          ),
        ),
      ),
    );
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NetifyColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(NetifyRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NetifySpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share', style: NetifyTextStyles.appBarTitle),
                  const SizedBox(height: NetifySpacing.lg),
                  _buildShareOption(
                    icon: Icons.terminal,
                    title: 'Share as cURL',
                    subtitle: 'Command line format',
                    onTap: () {
                      Navigator.pop(context);
                      _shareAs('curl');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.code,
                    title: 'Share as JSON',
                    subtitle: 'Full request/response data',
                    onTap: () {
                      Navigator.pop(context);
                      _shareAs('json');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.link,
                    title: 'Share URL only',
                    subtitle: widget.log.url,
                    onTap: () {
                      Navigator.pop(context);
                      _shareAs('url');
                    },
                  ),
                  const Divider(height: NetifySpacing.lg),
                  _buildShareOption(
                    icon: Icons.copy,
                    title: 'Copy cURL to clipboard',
                    onTap: () {
                      Navigator.pop(context);
                      _copyToClipboard(widget.log.toCurl(), 'cURL');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy_all,
                    title: 'Copy JSON to clipboard',
                    onTap: () {
                      Navigator.pop(context);
                      _copyToClipboard(
                        const JsonEncoder.withIndent('  ')
                            .convert(widget.log.toJson()),
                        'JSON',
                      );
                    },
                  ),
                  const Divider(height: NetifySpacing.lg),
                  _buildShareOption(
                    icon: Icons.image_outlined,
                    title: 'Share as Image',
                    onTap: () {
                      Navigator.pop(context);
                      _shareAsImage();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: NetifyColors.primary),
      title: Text(title, style: NetifyTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: NetifyTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _shareAs(String format) async {
    String content;
    String subject = '${widget.log.method} ${widget.log.url}';

    switch (format) {
      case 'curl':
        content = widget.log.toCurl();
        break;
      case 'json':
        content =
            const JsonEncoder.withIndent('  ').convert(widget.log.toJson());
        break;
      case 'url':
        content = widget.log.url;
        subject = 'URL';
        break;
      default:
        return;
    }

    await Share.share(content, subject: subject);
  }

  void _copyToClipboard(String content, String label) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _shareAsImage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capturing screenshot...'),
          duration: Duration(seconds: 1),
        ),
      );

      final image = await _screenshotController.captureFromWidget(
        LogShareSnapshot(log: widget.log),
        pixelRatio: 4.0,
        context: context,
        delay: const Duration(milliseconds: 150),
      );

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/netify_log_$timestamp.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${widget.log.method} ${widget.log.url}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture screenshot: ${e.toString()}'),
            backgroundColor: NetifyColors.error,
          ),
        );
      }
    }
  }

  Future<void> _replayRequest() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Replaying request...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await Netify.replayRequest(widget.log);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request replayed successfully'),
            backgroundColor: NetifyColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request failed: ${e.toString().split('\n').first}'),
            backgroundColor: NetifyColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
