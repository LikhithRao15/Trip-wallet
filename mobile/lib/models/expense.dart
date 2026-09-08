class Expense {
  final String id;
  final String tripId;
  final String walletId;
  final String paidBy;
  final int amountPaise;
  final String category;
  final String? description;
  final String splitMode;
  final String status;
  final String createdAt;
  final List<ExpenseSplit> splits;

  Expense({
    required this.id,
    required this.tripId,
    required this.walletId,
    required this.paidBy,
    required this.amountPaise,
    required this.category,
    this.description,
    this.splitMode = 'EQUAL',
    required this.status,
    required this.createdAt,
    required this.splits,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final splitsJson = json['splits'] as List<dynamic>? ?? [];

    return Expense(
      id: json['id'],
      tripId: json['trip_id'],
      walletId: json['wallet_id'],
      paidBy: json['paid_by'],
      amountPaise: json['amount_paise'],
      category: json['category'],
      description: json['description'],
      splitMode: json['split_mode'] ?? 'EQUAL',
      status: json['status'] ?? 'CONFIRMED',
      createdAt: json['created_at']?.toString() ?? '',
      splits: splitsJson
          .map(
            (item) => ExpenseSplit.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class ExpenseSplit {
  final String memberId;
  final int amountPaise;

  ExpenseSplit({
    required this.memberId,
    required this.amountPaise,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      memberId: json['member_id'],
      amountPaise: json['amount_paise'],
    );
  }
}