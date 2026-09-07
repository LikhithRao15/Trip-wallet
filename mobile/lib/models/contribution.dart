class Contribution {
  final String id;
  final String tripId;
  final String memberId;
  final int amountPaise;
  final String paymentMethod;
  final String status;
  final String? note;
  final String createdAt;

  Contribution({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.amountPaise,
    required this.paymentMethod,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      amountPaise: json['amount_paise'] ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
      status: json['status']?.toString() ?? 'CONFIRMED',
      note: json['note'],
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  double get amount => amountPaise / 100;
}