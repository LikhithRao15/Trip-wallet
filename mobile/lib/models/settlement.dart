class SettlementMember {
  final String memberId;
  final String name;
  final String email;
  final int netPaise;
  final String position;
  final int totalContributedPaise;
  final int totalExpenseSharePaise;
  final String positionType;

  SettlementMember({
    required this.memberId,
    required this.name,
    required this.email,
    required this.netPaise,
    required this.position,
    this.totalContributedPaise = 0,
    this.totalExpenseSharePaise = 0,
    this.positionType = 'SETTLED',
  });

  factory SettlementMember.fromJson(
    Map<String, dynamic> json,
  ) {
    final net = json['net_position_paise'] ?? json['net_paise'] ?? 0;
    final pos = json['position_type'] ?? json['position'] ?? 'SETTLED';

    return SettlementMember(
      memberId: json['user_id']?.toString() ?? json['member_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      netPaise: net,
      position: json['position']?.toString() ?? pos,
      totalContributedPaise: json['total_contributed_paise'] ?? json['contributed_paise'] ?? 0,
      totalExpenseSharePaise: json['total_expense_share_paise'] ?? json['spent_paise'] ?? 0,
      positionType: pos,
    );
  }
}

class SettlementTransfer {
  final String fromMemberId;
  final String toMemberId;
  final String fromName;
  final String toName;
  final int amountPaise;

  SettlementTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    this.fromName = '',
    this.toName = '',
    required this.amountPaise,
  });

  factory SettlementTransfer.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementTransfer(
      fromMemberId: json['from_user_id']?.toString() ?? json['from_member_id']?.toString() ?? '',
      toMemberId: json['to_user_id']?.toString() ?? json['to_member_id']?.toString() ?? '',
      fromName: json['from_name']?.toString() ?? '',
      toName: json['to_name']?.toString() ?? '',
      amountPaise: json['amount_paise'] ?? 0,
    );
  }
}

class SettlementRefund {
  final String memberId;
  final int amountPaise;

  SettlementRefund({
    required this.memberId,
    required this.amountPaise,
  });

  factory SettlementRefund.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementRefund(
      memberId: json['member_id']?.toString() ?? '',
      amountPaise: json['amount_paise'] ?? 0,
    );
  }
}

class SettlementResult {
  final String tripId;
  final int totalContributionsPaise;
  final int totalExpensesPaise;
  final int walletBalancePaise;
  final List<SettlementMember> members;
  final List<SettlementTransfer> transfers;
  final bool isBalanced;
  final int totalUnsettledPaise;
  final String status;
  final List<SettlementRefund> refunds;

  SettlementResult({
    this.tripId = '',
    this.totalContributionsPaise = 0,
    this.totalExpensesPaise = 0,
    required this.walletBalancePaise,
    required this.members,
    required this.transfers,
    this.isBalanced = true,
    this.totalUnsettledPaise = 0,
    this.status = 'OPEN',
    required this.refunds,
  });

  factory SettlementResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawMembers = (json['member_positions'] ?? json['members']) as List? ?? [];
    final rawTransfers = (json['settlements'] ?? json['transfers']) as List? ?? [];

    return SettlementResult(
      tripId: json['trip_id']?.toString() ?? '',
      totalContributionsPaise: json['total_contributions_paise'] ?? 0,
      totalExpensesPaise: json['total_expenses_paise'] ?? 0,
      walletBalancePaise: json['wallet_balance_paise'] ?? 0,
      members: rawMembers
          .map(
            (item) => SettlementMember.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      transfers: rawTransfers
          .map(
            (item) => SettlementTransfer.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      isBalanced: json['is_balanced'] ?? true,
      totalUnsettledPaise: json['total_unsettled_paise'] ?? 0,
      status: json['status']?.toString() ?? 'OPEN',
      refunds: (json['refunds'] as List? ?? [])
          .map(
            (item) => SettlementRefund.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}