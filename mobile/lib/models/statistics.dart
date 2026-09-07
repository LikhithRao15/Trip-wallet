class CategoryStatistics {
  final String category;
  final int amountPaise;
  final int expenseCount;

  CategoryStatistics({
    required this.category,
    required this.amountPaise,
    required this.expenseCount,
  });

  factory CategoryStatistics.fromJson(Map<String, dynamic> json) {
    return CategoryStatistics(
      category: json['category']?.toString() ?? 'OTHER',
      amountPaise: json['amount_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
    );
  }
}

class MemberStatistics {
  final String memberId;
  final String name;
  final int amountPaise;
  final int expenseCount;

  MemberStatistics({
    required this.memberId,
    required this.name,
    required this.amountPaise,
    required this.expenseCount,
  });

  factory MemberStatistics.fromJson(Map<String, dynamic> json) {
    return MemberStatistics(
      memberId: json['member_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amountPaise: json['amount_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
    );
  }
}

class DateStatistics {
  final String date;
  final int amountPaise;
  final int expenseCount;

  DateStatistics({
    required this.date,
    required this.amountPaise,
    required this.expenseCount,
  });

  factory DateStatistics.fromJson(Map<String, dynamic> json) {
    return DateStatistics(
      date: json['date']?.toString() ?? '',
      amountPaise: json['amount_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
    );
  }
}

class StatisticsResult {
  final int totalExpensesPaise;
  final int totalContributionsPaise;
  final int walletBalancePaise;
  final int expenseCount;

  final List<CategoryStatistics> byCategory;
  final List<MemberStatistics> byMember;
  final List<DateStatistics> byDate;

  StatisticsResult({
    required this.totalExpensesPaise,
    required this.totalContributionsPaise,
    required this.walletBalancePaise,
    required this.expenseCount,
    required this.byCategory,
    required this.byMember,
    required this.byDate,
  });

  factory StatisticsResult.fromJson(Map<String, dynamic> json) {
    return StatisticsResult(
      totalExpensesPaise: json['total_expenses_paise'] ?? 0,
      totalContributionsPaise:
          json['total_contributions_paise'] ?? 0,
      walletBalancePaise:
          json['wallet_balance_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
      byCategory: (json['by_category'] as List? ?? [])
          .map(
            (item) => CategoryStatistics.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      byMember: (json['by_member'] as List? ?? [])
          .map(
            (item) => MemberStatistics.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      byDate: (json['by_date'] as List? ?? [])
          .map(
            (item) => DateStatistics.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}