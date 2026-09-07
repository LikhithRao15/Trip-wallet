class WalletTransaction {
  final String id;
  final String walletId;
  final String transactionType;
  final int amountPaise;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final String createdBy;
  final String createdAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amountPaise,
    this.referenceType,
    this.referenceId,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
      transactionType:
          json['transaction_type']?.toString() ?? 'UNKNOWN',
      amountPaise: json['amount_paise'] ?? 0,
      referenceType:
          json['reference_type']?.toString(),
      referenceId:
          json['reference_id']?.toString(),
      description:
          json['description']?.toString(),
      createdBy:
          json['created_by']?.toString() ?? '',
      createdAt:
          json['created_at']?.toString() ?? '',
    );
  }

  double get amount => amountPaise / 100;
}