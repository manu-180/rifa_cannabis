import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

/// Card que explica: "Sí o sí hay ganador el 15/03". Incita a comprar.
class GuaranteedWinnerCard extends StatelessWidget {
  const GuaranteedWinnerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accentColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.trophy,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'HAY GANADOR SÍ O SÍ',
                  style: TextStyle(
                    fontFamily: 'Oxanium',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'El sorteo se realiza el 15 de marzo a las 15:00. Siempre hay un ganador: si un solo número fue comprado, ese número gana.',
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
