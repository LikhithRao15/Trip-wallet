import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/settlement.dart';

void main() {
  group('Settlement Models (Phase 2.3)', () {
    test('deserializes balanced SettlementResult accurately', () {
      final json = {
        'trip_id': '11111111-1111-1111-1111-111111111111',
        'total_contributions_paise': 300000,
        'total_expenses_paise': 300000,
        'wallet_balance_paise': 0,
        'is_balanced': true,
        'total_unsettled_paise': 0,
        'status': 'OPEN',
        'member_positions': [
          {
            'user_id': 'user-1',
            'name': 'Rahul',
            'email': 'rahul@example.com',
            'total_contributed_paise': 200000,
            'total_expense_share_paise': 150000,
            'net_position_paise': 50000,
            'position_type': 'GETS_BACK',
          },
          {
            'user_id': 'user-2',
            'name': 'Priya',
            'email': 'priya@example.com',
            'total_contributed_paise': 100000,
            'total_expense_share_paise': 150000,
            'net_position_paise': -50000,
            'position_type': 'OWES',
          }
        ],
        'settlements': [
          {
            'from_user_id': 'user-2',
            'from_name': 'Priya',
            'to_user_id': 'user-1',
            'to_name': 'Rahul',
            'amount_paise': 50000,
          }
        ]
      };

      final result = SettlementResult.fromJson(json);

      expect(result.tripId, '11111111-1111-1111-1111-111111111111');
      expect(result.totalContributionsPaise, 300000);
      expect(result.totalExpensesPaise, 300000);
      expect(result.walletBalancePaise, 0);
      expect(result.isBalanced, isTrue);
      expect(result.totalUnsettledPaise, 0);
      expect(result.status, 'OPEN');

      expect(result.members.length, 2);
      expect(result.members[0].name, 'Rahul');
      expect(result.members[0].netPaise, 50000);
      expect(result.members[0].positionType, 'GETS_BACK');
      expect(result.members[0].totalContributedPaise, 200000);
      expect(result.members[0].totalExpenseSharePaise, 150000);

      expect(result.members[1].name, 'Priya');
      expect(result.members[1].netPaise, -50000);
      expect(result.members[1].positionType, 'OWES');

      expect(result.transfers.length, 1);
      expect(result.transfers[0].fromName, 'Priya');
      expect(result.transfers[0].toName, 'Rahul');
      expect(result.transfers[0].amountPaise, 50000);
    });

    test('deserializes unbalanced SettlementResult with remaining balance', () {
      final json = {
        'trip_id': '22222222-2222-2222-2222-222222222222',
        'total_contributions_paise': 500000,
        'total_expenses_paise': 300000,
        'wallet_balance_paise': 200000,
        'is_balanced': false,
        'total_unsettled_paise': 200000,
        'status': 'OPEN',
        'member_positions': [],
        'settlements': [],
      };

      final result = SettlementResult.fromJson(json);
      expect(result.isBalanced, isFalse);
      expect(result.walletBalancePaise, 200000);
      expect(result.totalUnsettledPaise, 200000);
      expect(result.transfers, isEmpty);
    });
  });
}
