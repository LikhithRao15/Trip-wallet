class WalletSummary {
  final String currency;
  final int balancePaise;
  final int totalContributionsPaise;
  final int totalExpensesPaise;
  final int transactionCount;

  WalletSummary({
    required this.currency,
    required this.balancePaise,
    required this.totalContributionsPaise,
    required this.totalExpensesPaise,
    required this.transactionCount,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      currency: json['currency'] ?? 'INR',
      balancePaise: json['balance_paise'] ?? 0,
      totalContributionsPaise:
          json['total_contributions_paise'] ?? 0,
      totalExpensesPaise:
          json['total_expenses_paise'] ?? 0,
      transactionCount:
          json['transaction_count'] ?? 0,
    );
  }

  double get balance => balancePaise / 100;
  double get totalContributions =>
      totalContributionsPaise / 100;
  double get totalExpenses =>
      totalExpensesPaise / 100;
}