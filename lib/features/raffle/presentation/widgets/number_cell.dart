import 'package:flutter/material.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';

/// Una casilla del talonario (1-100). Si está vendida muestra tooltip con el nombre al hover.
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.isSold ? SystemMouseCursors.basic : SystemMouseCursors.basic,
      child: Tooltip(
        message: widget.isSold && widget.buyerName != null
            ? widget.buyerName!
            : 'Nº ${widget.number}${widget.isSold ? '' : ' — Disponible'}',
        waitDuration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHighlight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        textStyle: const TextStyle(
          fontFamily: 'Oxanium',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
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
              width: _hover && widget.isSold ? 1.5 : 1,
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
