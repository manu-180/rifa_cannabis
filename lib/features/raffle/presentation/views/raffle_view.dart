import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/core/widgets/premium_background.dart';
import 'package:rifa_cannabis/features/auth/presentation/providers/auth_provider.dart';
import 'package:rifa_cannabis/features/auth/presentation/widgets/login_modal.dart';
import 'package:rifa_cannabis/features/raffle/presentation/views/admin_view.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/chances_pie_chart.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/countdown_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/guaranteed_winner_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/prize_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/purchase_cta_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/raffle_board.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/stats_ranking_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/winner_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/presence_card.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';

/// Vista principal: talonario izquierda, estadísticas y cards derecha. Login y Admin en esquina.
class RaffleView extends ConsumerWidget {
  const RaffleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(raffleDrawHydrationProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          SafeArea(
            child: Column(
              children: [
                // Header con título y botón login / admin
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          FaIcon(FontAwesomeIcons.cannabis, color: AppColors.prizeGreen, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'RIFA',
                            style: TextStyle(
                              fontFamily: 'Oxanium',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PresenceCard(),
                          const SizedBox(width: 12),
                          if (isLoggedIn)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdminView()),
                                );
                              },
                              icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
                              label: const Text('Administrar'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () async {
                                await showDialog<bool>(
                                  context: context,
                                  barrierColor: Colors.black54,
                                  builder: (_) => const LoginModal(),
                                );
                              },
                              icon: const Icon(Icons.login_outlined, size: 20),
                              label: const Text('Iniciar sesión'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Contenido: dos columnas en desktop, una en móvil
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 900;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: const RaffleBoard(),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(right: 20, bottom: 24),
                                child: _RightPanel(),
                              ),
                            ),
                          ],
                        );
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const RaffleBoard(),
                            const SizedBox(height: 24),
                            const _RightPanel(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
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

class _RightPanel extends ConsumerWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winnerName = ref.watch(winnerNameProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (winnerName != null && winnerName.isNotEmpty)
          const WinnerCard()
        else
          const CountdownCard(),
        const SizedBox(height: 16),
        const PrizeCard(),
        const SizedBox(height: 16),
        const PurchaseCtaCard(),
        const SizedBox(height: 16),
        const GuaranteedWinnerCard(),
        const SizedBox(height: 20),
        const StatsRankingCard(),
        const SizedBox(height: 16),
        const ChancesPieChart(),
      ],
    );
  }
}
