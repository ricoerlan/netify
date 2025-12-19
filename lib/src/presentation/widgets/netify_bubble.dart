import 'package:flutter/material.dart';

import '../../netify_main.dart';
import '../theme/netify_theme.dart';

class NetifyBubble extends StatefulWidget {
  final VoidCallback onTap;
  final Alignment initialAlignment;

  const NetifyBubble({
    super.key,
    required this.onTap,
    this.initialAlignment = Alignment.bottomRight,
  });

  @override
  State<NetifyBubble> createState() => _NetifyBubbleState();
}

class _NetifyBubbleState extends State<NetifyBubble>
    with SingleTickerProviderStateMixin {
  Offset? _position;
  bool _isDragging = false;
  bool _isPositionInitialized = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onNewRequest(int newCount) {
    if (newCount > _lastCount) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
    _lastCount = newCount;
  }

  void _initializePosition(Size screenSize, EdgeInsets safeArea) {
    if (!_isPositionInitialized) {
      _position = Offset(
        screenSize.width - 70 - safeArea.right,
        screenSize.height - 140 - safeArea.bottom,
      );
      _isPositionInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Initialize position only once
    _initializePosition(screenSize, safeArea);

    return StreamBuilder<List>(
      stream: Netify.logsStream,
      initialData: Netify.logs,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        // Trigger pulse animation on new requests
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onNewRequest(count);
        });

        return Positioned(
          left: _position?.dx ?? screenSize.width - 70,
          top: _position?.dy ?? screenSize.height - 140,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              if (_position == null) return;
              setState(() {
                _position = Offset(
                  (_position!.dx + details.delta.dx)
                      .clamp(0, screenSize.width - 56),
                  (_position!.dy + details.delta.dy).clamp(
                      safeArea.top, screenSize.height - 56 - safeArea.bottom),
                );
              });
            },
            onPanEnd: (_) {
              if (_position == null) return;
              setState(() => _isDragging = false);
              // Snap to nearest edge
              final centerX = _position!.dx + 28;
              final snapToRight = centerX > screenSize.width / 2;
              setState(() {
                _position = Offset(
                  snapToRight
                      ? screenSize.width - 70 - safeArea.right
                      : 14 + safeArea.left,
                  _position!.dy,
                );
              });
            },
            onTap: widget.onTap,
            child: AnimatedBuilder(
              listenable: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: _isDragging ? 0 : 200),
                curve: Curves.easeOut,
                child: _buildBubble(count),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubble(int count) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: NetifyColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: NetifyColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.bug_report_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: NetifyColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
