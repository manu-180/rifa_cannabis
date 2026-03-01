import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

/// Card del premio: 10g cannabis + REPROCAN. Estética que incita a comprar.
class PrizeCard extends StatelessWidget {
  const PrizeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: AppColors.prizeGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.prizeGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.prizeGreen.withValues(alpha: 0.4)),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.cannabis,
                  color: AppColors.prizeGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREMIO',
                      style: TextStyle(
                        fontFamily: 'Oxanium',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '10 gramos cannabis',
                      style: TextStyle(
                        fontFamily: 'Oxanium',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.prizeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.prizeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.prizeGreen.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: AppColors.prizeGreen),
                const SizedBox(width: 6),
                Text(
                  'REPROCAN',
                  style: TextStyle(
                    fontFamily: 'Oxanium',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.prizeGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
