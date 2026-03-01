class RaffleTicket {
  final String id;
  final int number;
  final String buyerName;
  final DateTime createdAt;

  const RaffleTicket({
    required this.id,
    required this.number,
    required this.buyerName,
    required this.createdAt,
  });

  factory RaffleTicket.fromJson(Map<String, dynamic> json) {
    return RaffleTicket(
      id: json['id'] as String,
      number: json['number'] as int,
      buyerName: json['buyer_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
