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
    return MemberFinancialSummary(
      memberId: json['member_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contributedPaise: json['contributed_paise'] ?? 0,
      spentPaise: json['spent_paise'] ?? 0,
      netPaise: json['net_paise'] ?? 0,
    );
  }
}