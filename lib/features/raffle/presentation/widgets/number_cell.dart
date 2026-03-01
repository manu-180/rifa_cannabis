import 'package:flutter/material.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';

/// Una casilla del talonario (1-100). Hover: tooltip con dueño o "Disponible". Tap (móvil): mismo mensaje en cartel que se desvanece.
class NumberCell extends StatefulWidget {
  final int number;
  final bool isSold;
  final String? buyerName;

  const NumberCell({
    super.key,
    required this.number,
    required this.isSold,
    this.buyerName,
  });

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  bool _hover = false;

  String get _tooltipMessage => widget.isSold && widget.buyerName != null
      ? widget.buyerName!
      : 'Nº ${widget.number}${widget.isSold ? '' : ' — Disponible'}';

  void _showTapOverlay() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CellTapOverlay(
        message: _tooltipMessage,
        cellRect: rect,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.basic,
      child: Tooltip(
        message: _tooltipMessage,
        waitDuration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GestureDetector(
          onTap: _showTapOverlay,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSold
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hover && widget.isSold
                    ? AppColors.primary
                    : AppColors.borderGlass,
                width: 1,
              ),
              boxShadow: _hover && widget.isSold
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${widget.number}',
              style: TextStyle(
                fontFamily: 'Oxanium',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: widget.isSold ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay que muestra el mensaje del número, con fade in, espera y fade out.
class _CellTapOverlay extends StatefulWidget {
  final String message;
  final Rect cellRect;
  final VoidCallback onDismiss;

  const _CellTapOverlay({
    required this.message,
    required this.cellRect,
    required this.onDismiss,
  });

  @override
  State<_CellTapOverlay> createState() => _CellTapOverlayState();
}

class _CellTapOverlayState extends State<_CellTapOverlay>
    with SingleTickerProviderStateMixin {
  static const _fadeInMs = 200;
  static const _visibleMs = 2200;
  static const _fadeOutMs = 280;
  static const _totalMs = _fadeInMs + _visibleMs + _fadeOutMs;

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: _fadeInMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: _visibleMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: _fadeOutMs.toDouble(),
      ),
    ]).animate(_controller);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    const margin = 8.0;
    const cardWidth = 200.0;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final showAbove = widget.cellRect.bottom > screenHeight * 0.55;
    final left = (widget.cellRect.left + (widget.cellRect.width / 2) - (cardWidth / 2))
        .clamp(12.0, screenWidth - cardWidth - 12);
    const cardHeight = 44.0;
    final top = showAbove
        ? widget.cellRect.top - cardHeight - margin
        : widget.cellRect.bottom + margin;

    final card = Material(
      color: Colors.transparent,
      child: Container(
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHighlight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          widget.message,
          style: const TextStyle(
            fontFamily: 'Oxanium',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Positioned(
      left: left,
      width: cardWidth,
      top: top,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: card,
        ),
      ),
    );
  }
}
