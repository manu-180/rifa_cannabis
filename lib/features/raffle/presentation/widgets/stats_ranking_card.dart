import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

/// Ranking de compradores por probabilidad de ganar (más números = más chances).
class StatsRankingCard extends ConsumerWidget {
  const StatsRankingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(buyerStatsProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'QUIÉN TIENE MÁS CHANCES',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (stats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aún no hay números vendidos.',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...stats.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return _RankRow(
                position: i + 1,
                stats: s,
              );
            }),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int position;
  final BuyerStats stats;

  const _RankRow({required this.position, required this.stats});

  @override
  Widget build(BuildContext context) {
    final medalColor = position == 1
        ? const Color(0xFFFFD700)
        : position == 2
            ? const Color(0xFFC0C0C0)
            : position == 3
                ? const Color(0xFFCD7F32)
                : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.op(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$position',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                stats.buyerName,
                style: const TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.op(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.op(0.3)),
              ),
              child: Text(
                '${stats.probabilityPercent.toStringAsFixed(0)}% de ganar',
                style: const TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
