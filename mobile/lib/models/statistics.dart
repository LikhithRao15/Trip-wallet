class CategoryStatistics {
  final String category;
  final int amountPaise;
  final int expenseCount;
  final double percentageOfTotal;

  CategoryStatistics({
    required this.category,
    required this.amountPaise,
    required this.expenseCount,
    this.percentageOfTotal = 0.0,
  });

  factory CategoryStatistics.fromJson(Map<String, dynamic> json) {
    final pct = json['percentage_of_total'];
    return CategoryStatistics(
      category: json['category']?.toString() ?? 'OTHER',
      amountPaise: json['amount_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
      percentageOfTotal: pct is num ? pct.toDouble() : 0.0,
    );
  }
}

class MemberStatistics {
  final String memberId;
  final String userId;
  final String name;
  final String displayName;
  final int amountPaise;
  final int totalContributedPaise;
  final int totalExpenseSharePaise;
  final int netPositionPaise;
  final double percentageOfTotalExpenses;
  final int expenseCount;

  MemberStatistics({
    required this.memberId,
    this.userId = '',
    required this.name,
    this.displayName = '',
    required this.amountPaise,
    this.totalContributedPaise = 0,
    this.totalExpenseSharePaise = 0,
    this.netPositionPaise = 0,
    this.percentageOfTotalExpenses = 0.0,
    required this.expenseCount,
  });

  factory MemberStatistics.fromJson(Map<String, dynamic> json) {
    final pct = json['percentage_of_total_expenses'];
    final mName = json['display_name']?.toString() ?? json['name']?.toString() ?? '';
    final mId = json['user_id']?.toString() ?? json['member_id']?.toString() ?? '';
    final spent = json['total_expense_share_paise'] ?? json['amount_paise'] ?? 0;

    return MemberStatistics(
      memberId: mId,
      userId: mId,
      name: mName,
      displayName: mName,
      amountPaise: spent,
      totalContributedPaise: json['total_contributed_paise'] ?? 0,
      totalExpenseSharePaise: spent,
      netPositionPaise: json['net_position_paise'] ?? 0,
      percentageOfTotalExpenses: pct is num ? pct.toDouble() : 0.0,
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

class TopExpenseItem {
  final String expenseId;
  final String description;
  final String category;
  final int amountPaise;
  final String paidBy;
  final String paidByName;
  final String createdAt;

  TopExpenseItem({
    required this.expenseId,
    required this.description,
    required this.category,
    required this.amountPaise,
    required this.paidBy,
    required this.paidByName,
    required this.createdAt,
  });

  factory TopExpenseItem.fromJson(Map<String, dynamic> json) {
    return TopExpenseItem(
      expenseId: json['expense_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      amountPaise: json['amount_paise'] ?? 0,
      paidBy: json['paid_by']?.toString() ?? '',
      paidByName: json['paid_by_name']?.toString() ?? 'Member',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class StatisticsResult {
  final int totalExpensesPaise;
  final int totalContributionsPaise;
  final int walletBalancePaise;
  final int expenseCount;
  final int averageExpensePaise;
  final int highestExpensePaise;
  final int lowestExpensePaise;
  final int contributorCount;
  final int participatingMemberCount;
  final String? highestSpendingDay;
  final int highestSpendingDayAmountPaise;

  final List<CategoryStatistics> byCategory;
  final List<MemberStatistics> byMember;
  final List<DateStatistics> byDate;
  final List<TopExpenseItem> topExpenses;

  StatisticsResult({
    required this.totalExpensesPaise,
    required this.totalContributionsPaise,
    required this.walletBalancePaise,
    required this.expenseCount,
    this.averageExpensePaise = 0,
    this.highestExpensePaise = 0,
    this.lowestExpensePaise = 0,
    this.contributorCount = 0,
    this.participatingMemberCount = 0,
    this.highestSpendingDay,
    this.highestSpendingDayAmountPaise = 0,
    required this.byCategory,
    required this.byMember,
    required this.byDate,
    this.topExpenses = const [],
  });

  factory StatisticsResult.fromJson(Map<String, dynamic> json) {
    return StatisticsResult(
      totalExpensesPaise: json['total_expenses_paise'] ?? 0,
      totalContributionsPaise: json['total_contributions_paise'] ?? 0,
      walletBalancePaise: json['wallet_balance_paise'] ?? 0,
      expenseCount: json['expense_count'] ?? 0,
      averageExpensePaise: json['average_expense_paise'] ?? 0,
      highestExpensePaise: json['highest_expense_paise'] ?? 0,
      lowestExpensePaise: json['lowest_expense_paise'] ?? 0,
      contributorCount: json['contributor_count'] ?? 0,
      participatingMemberCount: json['participating_member_count'] ?? 0,
      highestSpendingDay: json['highest_spending_day']?.toString(),
      highestSpendingDayAmountPaise: json['highest_spending_day_amount_paise'] ?? 0,
      byCategory: (json['by_category'] as List? ?? [])
          .map((item) => CategoryStatistics.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      byMember: (json['by_member'] as List? ?? [])
          .map((item) => MemberStatistics.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      byDate: (json['by_date'] as List? ?? [])
          .map((item) => DateStatistics.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      topExpenses: (json['top_expenses'] as List? ?? [])
          .map((item) => TopExpenseItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}