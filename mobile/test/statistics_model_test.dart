import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/statistics.dart';

void main() {
  group('Statistics Models (Phase 2.4)', () {
    test('deserializes StatisticsResult with full analytics and top expenses', () {
      final json = {
        'total_expenses_paise': 45000,
        'total_contributions_paise': 45000,
        'wallet_balance_paise': 0,
        'expense_count': 3,
        'average_expense_paise': 15000,
        'highest_expense_paise': 18000,
        'lowest_expense_paise': 12000,
        'contributor_count': 3,
        'participating_member_count': 3,
        'highest_spending_day': '2026-09-08',
        'highest_spending_day_amount_paise': 45000,
        'by_category': [
          {
            'category': 'TRAVEL',
            'amount_paise': 18000,
            'expense_count': 1,
            'percentage_of_total': 40.0,
          },
          {
            'category': 'HOTEL',
            'amount_paise': 15000,
            'expense_count': 1,
            'percentage_of_total': 33.33,
          }
        ],
        'by_member': [
          {
            'user_id': 'u-1',
            'member_id': 'm-1',
            'name': 'Alice',
            'display_name': 'Alice Wonderland',
            'total_contributed_paise': 20000,
            'total_expense_share_paise': 16000,
            'net_position_paise': 4000,
            'percentage_of_total_expenses': 35.56,
            'amount_paise': 16000,
            'expense_count': 3,
          }
        ],
        'by_date': [
          {
            'date': '2026-09-08',
            'amount_paise': 45000,
            'expense_count': 3,
          }
        ],
        'top_expenses': [
          {
            'expense_id': 'e-1',
            'description': 'Taxi to Fort',
            'category': 'TRAVEL',
            'amount_paise': 18000,
            'paid_by': 'u-1',
            'paid_by_name': 'Alice Wonderland',
            'created_at': '2026-09-08T10:00:00',
          }
        ],
      };

      final stats = StatisticsResult.fromJson(json);

      expect(stats.totalExpensesPaise, 45000);
      expect(stats.totalContributionsPaise, 45000);
      expect(stats.walletBalancePaise, 0);
      expect(stats.expenseCount, 3);
      expect(stats.averageExpensePaise, 15000);
      expect(stats.highestExpensePaise, 18000);
      expect(stats.lowestExpensePaise, 12000);
      expect(stats.contributorCount, 3);
      expect(stats.participatingMemberCount, 3);
      expect(stats.highestSpendingDay, '2026-09-08');
      expect(stats.highestSpendingDayAmountPaise, 45000);

      // Categories
      expect(stats.byCategory.length, 2);
      expect(stats.byCategory[0].category, 'TRAVEL');
      expect(stats.byCategory[0].amountPaise, 18000);
      expect(stats.byCategory[0].percentageOfTotal, 40.0);

      // Members
      expect(stats.byMember.length, 1);
      expect(stats.byMember[0].displayName, 'Alice Wonderland');
      expect(stats.byMember[0].totalContributedPaise, 20000);
      expect(stats.byMember[0].totalExpenseSharePaise, 16000);
      expect(stats.byMember[0].netPositionPaise, 4000);
      expect(stats.byMember[0].percentageOfTotalExpenses, 35.56);

      // Top expenses
      expect(stats.topExpenses.length, 1);
      expect(stats.topExpenses[0].description, 'Taxi to Fort');
      expect(stats.topExpenses[0].paidByName, 'Alice Wonderland');
      expect(stats.topExpenses[0].amountPaise, 18000);
    });

    test('handles zero-expense empty statistics safely', () {
      final json = {
        'total_expenses_paise': 0,
        'total_contributions_paise': 0,
        'wallet_balance_paise': 0,
        'expense_count': 0,
        'average_expense_paise': 0,
        'highest_expense_paise': 0,
        'lowest_expense_paise': 0,
        'contributor_count': 0,
        'participating_member_count': 0,
        'highest_spending_day': null,
        'highest_spending_day_amount_paise': 0,
        'by_category': [],
        'by_member': [],
        'by_date': [],
        'top_expenses': [],
      };

      final stats = StatisticsResult.fromJson(json);

      expect(stats.totalExpensesPaise, 0);
      expect(stats.expenseCount, 0);
      expect(stats.averageExpensePaise, 0);
      expect(stats.highestSpendingDay, isNull);
      expect(stats.byCategory, isEmpty);
      expect(stats.byMember, isEmpty);
      expect(stats.topExpenses, isEmpty);
    });
  });
}
