import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';

/// Card que reemplaza la cuenta regresiva cuando hay ganador: nombre + cannabis / celebración.
class WinnerCard extends ConsumerWidget {
  const WinnerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winnerName = ref.watch(winnerNameProvider);

    if (winnerName == null || winnerName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(top: 1, left: 20, right: 20, bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0B1322),
        border: Border.all(
          color: AppColors.prizeGreen.op(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.op(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.prizeGreen.op(0.12),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  AppColors.prizeGreen.op(0.9),
                  AppColors.prizeGreenDark.op(0.8),
                  AppColors.prizeGreen.op(0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.trophy, color: AppColors.prizeGreen, size: 18),
              const SizedBox(width: 10),
              Text(
                'GANADOR DEL SORTEO',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.prizeGreen.op(0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.prizeGreen.op(0.08),
                  AppColors.prizeGreen.op(0.04),
                ],
              ),
              border: Border.all(
                color: AppColors.prizeGreen.op(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.prizeGreen.op(0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.cannabis,
                  color: AppColors.prizeGreen,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    winnerName,
                    style: const TextStyle(
                      fontFamily: 'Oxanium',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 14),
                FaIcon(
                  FontAwesomeIcons.cannabis,
                  color: AppColors.prizeGreen.op(0.85),
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_rounded, color: AppColors.textSecondary.op(0.8), size: 14),
              const SizedBox(width: 6),
              Text(
                '10g cannabis',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.op(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
