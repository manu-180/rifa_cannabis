import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

/// Card con precios: 1 número $10.000 · 2 números $15.000. Hover y selección.
class PricesCard extends ConsumerWidget {
  const PricesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedQuantityProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'VALORES',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PriceRow(
            amount: '\$10.000',
            label: '1 número',
            isSelected: selected == 1,
            onTap: () => ref.read(selectedQuantityProvider.notifier).state = 1,
          ),
          const SizedBox(height: 10),
          _PriceRow(
            amount: '\$15.000',
            label: '2 números',
            isSelected: selected == 2,
            onTap: () => ref.read(selectedQuantityProvider.notifier).state = 2,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatefulWidget {
  final String amount;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceRow({
    required this.amount,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hover;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.op(widget.isSelected ? 0.18 : 0.1)
                : AppColors.background.op(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.primary.op(widget.isSelected ? 0.6 : 0.4)
                  : AppColors.borderGlass,
              width: active ? 1.2 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.op(0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Oxanium',
                      fontSize: 14,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Text(
                widget.amount,
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
