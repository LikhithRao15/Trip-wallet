class SettlementMember {
  final String memberId;
  final String name;
  final String email;
  final int netPaise;
  final String position;

  SettlementMember({
    required this.memberId,
    required this.name,
    required this.email,
    required this.netPaise,
    required this.position,
  });

  factory SettlementMember.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementMember(
      memberId: json['member_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      netPaise: json['net_paise'] ?? 0,
      position: json['position']?.toString() ?? 'SETTLED',
    );
  }
}

class SettlementTransfer {
  final String fromMemberId;
  final String toMemberId;
  final int amountPaise;

  SettlementTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountPaise,
  });

  factory SettlementTransfer.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementTransfer(
      fromMemberId:
          json['from_member_id']?.toString() ?? '',
      toMemberId:
          json['to_member_id']?.toString() ?? '',
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
  final List<SettlementMember> members;
  final List<SettlementTransfer> transfers;
  final int walletBalancePaise;
  final List<SettlementRefund> refunds;

  SettlementResult({
    required this.members,
    required this.transfers,
    required this.walletBalancePaise,
    required this.refunds,
  });

  factory SettlementResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return SettlementResult(
      members: (json['members'] as List? ?? [])
          .map(
            (item) => SettlementMember.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      transfers: (json['transfers'] as List? ?? [])
          .map(
            (item) => SettlementTransfer.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      walletBalancePaise:
          json['wallet_balance_paise'] ?? 0,
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