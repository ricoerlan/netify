import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/netify_theme.dart';

class SectionCard extends StatefulWidget {
  final String title;
  final String content;
  final bool showCopyButton;

  const SectionCard({
    super.key,
    required this.title,
    required this.content,
    this.showCopyButton = false,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _isExpanded = false;
  static const int _maxLines = 6;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(
              horizontal: NetifySpacing.md,
              vertical: NetifySpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: NetifyTextStyles.sectionTitle,
                ),
                if (widget.showCopyButton)
                  GestureDetector(
                    onTap: () => _copyToClipboard(context),
                    child: Icon(
                      Icons.copy,
                      size: 18,
                      color: NetifyColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: NetifyColors.divider),
          Padding(
            padding: const EdgeInsets.all(NetifySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  widget.content,
                  style: NetifyTextStyles.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  maxLines: _isExpanded ? null : _maxLines,
                ),
                if (_shouldShowButton())
                  Padding(
                    padding: const EdgeInsets.only(top: NetifySpacing.sm),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'Show Less' : 'Show More',
                        style: NetifyTextStyles.bodySmall.copyWith(
                          color: NetifyColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowButton() {
    // We need layout constraints to calculate this properly.
    // For simplicity, let's assume if line count > max lines.
    // A better approach would be using LayoutBuilder, but simple line count check works for monospace.
    final lineCount = widget.content.split('\n').length;
    if (lineCount > _maxLines) return true;

    // If it's a long single line string, let it wrap (handled by SelectableText defaults)
    // but maybe we want to expand that too? For now, focused on vertical height.
    return widget.content.length > 300; // Fallback length check
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
