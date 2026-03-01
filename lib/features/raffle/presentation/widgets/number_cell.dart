import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';

/// Una casilla del talonario (1-100). Desktop: cartel al pasar el mouse. Móvil: cartel al tocar. Mismo cartel animado en ambos.
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
  OverlayEntry? _hoverOverlayEntry;

  String get _tooltipMessage => widget.isSold && widget.buyerName != null
      ? widget.buyerName!
      : 'Nº ${widget.number}${widget.isSold ? '' : ' — Disponible'}';

  void _showHoverCartel() {
    _removeHoverCartel();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CellCartelOverlay(
        message: _tooltipMessage,
        cellRect: rect,
        persistThenFadeOut: false,
        onDismiss: () => entry.remove(),
      ),
    );
    _hoverOverlayEntry = entry;
    overlay.insert(entry);
  }

  void _removeHoverCartel() {
    _hoverOverlayEntry?.remove();
    _hoverOverlayEntry = null;
  }

  void _showTapCartel() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CellCartelOverlay(
        message: _tooltipMessage,
        cellRect: rect,
        persistThenFadeOut: true,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        _showHoverCartel();
      },
      onExit: (_) {
        setState(() => _hover = false);
        _removeHoverCartel();
      },
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (details.kind == PointerDeviceKind.touch) _showTapCartel();
        },
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
    );
  }
}

/// Cartel del número. Hover: solo fade in y se mantiene (lo quita el padre). Tap: fade in, espera, fade out y onDismiss.
class _CellCartelOverlay extends StatefulWidget {
  final String message;
  final Rect cellRect;
  final bool persistThenFadeOut;
  final VoidCallback onDismiss;

  const _CellCartelOverlay({
    required this.message,
    required this.cellRect,
    required this.persistThenFadeOut,
    required this.onDismiss,
  });

  @override
  State<_CellCartelOverlay> createState() => _CellCartelOverlayState();
}

class _CellCartelOverlayState extends State<_CellCartelOverlay>
    with SingleTickerProviderStateMixin {
  static const _fadeInMs = 180;
  static const _visibleMs = 1500;
  static const _fadeOutMs = 250;

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.persistThenFadeOut) {
      const totalMs = _fadeInMs + _visibleMs + _fadeOutMs;
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: totalMs),
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
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _fadeInMs),
      );
      _opacity = Tween<double>(begin: 0, end: 1)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(_controller);
      _controller.forward();
    }
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

