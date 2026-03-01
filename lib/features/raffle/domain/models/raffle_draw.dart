/// Resultado del sorteo guardado en DB para que persista y todos vean al ganador.
class RaffleDraw {
  final String winnerName;
  final int winningNumber;
  final int sectionIndex;
  final double? needleAngle;
  final DateTime drawnAt;

  const RaffleDraw({
    required this.winnerName,
    required this.winningNumber,
    required this.sectionIndex,
    this.needleAngle,
    required this.drawnAt,
  });

  factory RaffleDraw.fromJson(Map<String, dynamic> json) {
    return RaffleDraw(
      winnerName: json['winner_name'] as String,
      winningNumber: json['winning_number'] as int,
      sectionIndex: json['section_index'] as int,
      needleAngle: json['needle_angle'] != null ? (json['needle_angle'] as num).toDouble() : null,
      drawnAt: DateTime.parse(json['drawn_at'] as String),
    );
  }
}
