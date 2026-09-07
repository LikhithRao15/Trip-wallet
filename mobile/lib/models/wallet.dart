class Wallet {
  final String id;
  final String tripId;
  final String currency;
  final int balancePaise;
  final String status;

  Wallet({
    required this.id,
    required this.tripId,
    required this.currency,
    required this.balancePaise,
    required this.status,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      tripId: json['trip_id'],
      currency: json['currency'] ?? 'INR',
      balancePaise: json['balance_paise'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  double get balance => balancePaise / 100;
}