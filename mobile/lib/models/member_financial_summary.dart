class MemberFinancialSummary {
  final String memberId;
  final String name;
  final String email;
  final int contributedPaise;
  final int spentPaise;
  final int netPaise;

  MemberFinancialSummary({
    required this.memberId,
    required this.name,
    required this.email,
    required this.contributedPaise,
    required this.spentPaise,
    required this.netPaise,
  });

  factory MemberFinancialSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    final cPaise = json['total_contributed_paise'] ?? json['contributed_paise'] ?? 0;
    final sPaise = json['total_expense_share_paise'] ?? json['spent_paise'] ?? 0;
    final nPaise = json['net_position_paise'] ?? json['net_paise'] ?? 0;

    return MemberFinancialSummary(
      memberId: json['user_id']?.toString() ?? json['member_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contributedPaise: cPaise,
      spentPaise: sPaise,
      netPaise: nPaise,
    );
  }
}