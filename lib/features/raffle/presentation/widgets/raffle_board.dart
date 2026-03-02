import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/number_cell.dart';

/// Talonario 10x10 (números 1-100). Izquierda del layout.
class RaffleBoard extends ConsumerWidget {
  const RaffleBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberToBuyer = ref.watch(numberToBuyerProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.op(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGlass),
        boxShadow: [
          BoxShadow(
            color: Colors.black.op(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'TALONARIO',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(100, (i) {
              final n = i + 1;
              final sold = numberToBuyer.containsKey(n);
              return NumberCell(
                number: n,
                isSold: sold,
                buyerName: numberToBuyer[n],
              );
            }),
          ),
        ],
      ),
    );
  }
}
