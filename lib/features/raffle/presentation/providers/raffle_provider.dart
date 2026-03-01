import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/raffle_config.dart';
import 'package:rifa_cannabis/core/providers/supabase_provider.dart';
import 'package:rifa_cannabis/features/raffle/data/raffle_repository.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/raffle_ticket.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';

final raffleRepositoryProvider = Provider<RaffleRepository>((ref) {
  return RaffleRepository(ref.watch(supabaseClientProvider));
});

final raffleTicketsStreamProvider = StreamProvider<List<RaffleTicket>>((ref) {
  return ref.watch(raffleRepositoryProvider).watchTickets();
});

final raffleTicketsProvider = Provider<List<RaffleTicket>>((ref) {
  return ref.watch(raffleTicketsStreamProvider).valueOrNull ?? [];
});

final buyerStatsProvider = Provider<List<BuyerStats>>((ref) {
  final tickets = ref.watch(raffleTicketsProvider);
  return ref.read(raffleRepositoryProvider).computeBuyerStats(tickets);
});

final numberToBuyerProvider = Provider<Map<int, String>>((ref) {
  final tickets = ref.watch(raffleTicketsProvider);
  return ref.read(raffleRepositoryProvider).numberToBuyerMap(tickets);
});

/// Cantidad de números elegida para comprar: 1 o 2.
final selectedQuantityProvider = StateProvider<int>((ref) => 1);

/// Ganador del sorteo (nombre). Se setea al sortear o al cargar desde la tabla.
final winnerNameProvider = StateProvider<String?>((ref) => null);

/// Índice del segmento ganador en el pie (aguja apunta ahí). Se setea al sortear o al cargar desde la tabla.
final winnerSectionIndexProvider = StateProvider<int?>((ref) => null);

/// Ángulo donde para la aguja (aleatorio dentro del segmento). Null = usar centro del segmento.
final winnerNeedleAngleProvider = StateProvider<double?>((ref) => null);

/// Carga el último sorteo desde la tabla. Solo muestra ganador si la fecha del sorteo ya pasó; si no, limpia el anterior.
final raffleDrawHydrationProvider = FutureProvider<void>((ref) async {
  final now = DateTime.now();
  if (now.isBefore(raffleDrawDate)) {
    ref.read(winnerNameProvider.notifier).update((_) => null);
    ref.read(winnerSectionIndexProvider.notifier).update((_) => null);
    ref.read(winnerNeedleAngleProvider.notifier).update((_) => null);
    return;
  }
  final draw = await ref.read(raffleRepositoryProvider).getDrawResult();
  if (draw != null) {
    ref.read(winnerNameProvider.notifier).update((_) => draw.winnerName);
    ref.read(winnerSectionIndexProvider.notifier).update((_) => draw.sectionIndex);
    ref.read(winnerNeedleAngleProvider.notifier).update((_) => draw.needleAngle);
  }
});
