import 'package:rifa_cannabis/features/raffle/domain/models/raffle_ticket.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/raffle_draw.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Primera letra de cada palabra en mayúscula; comparaciones siempre en minúscula.
String _toTitleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class RaffleRepository {
  RaffleRepository(this._client);
  final SupabaseClient _client;

  static const String _table = 'raffle_tickets';
  static const String _drawTable = 'raffle_draw';

  /// Todos los números vendidos (para talonario y estadísticas).
  Future<List<RaffleTicket>> getTickets() async {
    final res = await _client.from(_table).select().order('number');
    return (res as List).map((e) => RaffleTicket.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Stream en tiempo real para actualizar UI.
  Stream<List<RaffleTicket>> watchTickets() {
    return _client.from(_table).stream(primaryKey: ['id']).order('number').map((data) {
      return data.map((e) => RaffleTicket.fromJson(e)).toList();
    });
  }

  /// Asignar un número a un comprador (mismo nombre = más números = más chances).
  /// Si el número ya existe, falla (UNIQUE). Admin debe asignar números libres.
  Future<void> assignTicket({required int number, required String buyerName}) async {
    await _client.from(_table).insert({
      'number': number,
      'buyer_name': buyerName.trim(),
    });
  }

  /// Estadísticas: compradores agrupados por nombre (insensible a may/min), sumados y mostrados en título.
  List<BuyerStats> computeBuyerStats(List<RaffleTicket> tickets) {
    final byKey = <String, int>{};
    for (final t in tickets) {
      final key = t.buyerName.trim().toLowerCase();
      byKey[key] = (byKey[key] ?? 0) + 1;
    }
    final total = tickets.length;
    if (total == 0) return [];
    return byKey.entries
        .map((e) => BuyerStats(
              buyerName: _toTitleCase(e.key),
              ticketCount: e.value,
              probabilityPercent: total > 0 ? (e.value / total) * 100 : 0,
            ))
        .toList()
      ..sort((a, b) => b.ticketCount.compareTo(a.ticketCount));
  }

  /// Mapa número -> nombre para talonario y tooltips (nombre en formato título).
  Map<int, String> numberToBuyerMap(List<RaffleTicket> tickets) {
    return {for (final t in tickets) t.number: _toTitleCase(t.buyerName.trim())};
  }

  /// Último resultado del sorteo (para mostrar ganador y aguja). Null si aún no hubo sorteo.
  Future<RaffleDraw?> getDrawResult() async {
    final res = await _client
        .from(_drawTable)
        .select()
        .order('drawn_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return RaffleDraw.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Guarda el resultado del sorteo para que persista y todos lo vean.
  Future<void> saveDrawResult({
    required String winnerName,
    required int winningNumber,
    required int sectionIndex,
    double? needleAngle,
  }) async {
    final data = <String, dynamic>{
      'winner_name': winnerName,
      'winning_number': winningNumber,
      'section_index': sectionIndex,
    };
    if (needleAngle != null) data['needle_angle'] = needleAngle;
    await _client.from(_drawTable).insert(data);
  }
}
