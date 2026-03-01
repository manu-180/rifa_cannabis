/// Estadísticas por comprador: cantidad de números y probabilidad de ganar.
class BuyerStats {
  final String buyerName;
  final int ticketCount;
  final double probabilityPercent;

  const BuyerStats({
    required this.buyerName,
    required this.ticketCount,
    required this.probabilityPercent,
  });
}
