class Trip {
  final String id;
  final String name;
  final String? description;
  final String? destination;
  final String? startDate;
  final String? endDate;
  final String currency;
  final String adminId;
  final String status;
  final String settlementStatus;

  Trip({
    required this.id,
    required this.name,
    this.description,
    this.destination,
    this.startDate,
    this.endDate,
    required this.currency,
    required this.adminId,
    required this.status,
    this.settlementStatus = 'OPEN',
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      destination: json['destination'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      currency: json['currency'] ?? 'INR',
      adminId: json['admin_id'],
      status: json['status'] ?? 'ACTIVE',
      settlementStatus: json['settlement_status'] ?? 'OPEN',
    );
  }
}