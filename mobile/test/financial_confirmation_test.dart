import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/expense_confirm_dialog.dart';

void main() {
  group('ExpenseConfirmDialog Tests', () {
    testWidgets('renders all financial details and split breakdowns accurately',
        (WidgetTester tester) async {
      const splits = [
        ExpenseSplitBreakdown(
          memberName: 'Alice',
          amountPaise: 35000,
          percentage: '50.00',
        ),
        ExpenseSplitBreakdown(
          memberName: 'Bob',
          amountPaise: 35000,
          percentage: '50.00',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseConfirmDialog(
              tripCurrency: 'INR',
              totalAmountPaise: 70000,
              category: 'FOOD',
              description: 'Dinner at Beach Shack',
              currentWalletBalancePaise: 100000,
              splits: splits,
            ),
          ),
        ),
      );

      // Verify title and confirm button
      expect(find.text('Confirm Expense'), findsNWidgets(2));

      // Verify amount (70000 paise = 700.00)
      expect(find.text('INR 700.00'), findsOneWidget);

      // Verify category
      expect(find.text('FOOD'), findsOneWidget);

      // Verify description
      expect(find.text('Note: Dinner at Beach Shack'), findsOneWidget);

      // Verify split participants
      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('INR 350.00'), findsNWidgets(2));

      // Verify wallet impact
      expect(find.text('Current Balance:'), findsOneWidget);
      expect(find.text('INR 1000.00'), findsOneWidget);
      expect(find.text('Projected Balance:'), findsOneWidget);
      expect(find.text('INR 300.00'), findsOneWidget);

      // Verify actions
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays warning banner when expense exceeds wallet balance',
        (WidgetTester tester) async {
      const splits = [
        ExpenseSplitBreakdown(
          memberName: 'Charlie',
          amountPaise: 50000,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpenseConfirmDialog(
              tripCurrency: 'INR',
              totalAmountPaise: 50000,
              category: 'TRAVEL',
              currentWalletBalancePaise: 20000,
              splits: splits,
            ),
          ),
        ),
      );

      // Projected balance: 200.00 - 500.00 = -300.00
      expect(find.text('INR -300.00'), findsOneWidget);

      // Warning message should be visible
      expect(
        find.text('This expense exceeds the current wallet balance.'),
        findsOneWidget,
      );
    });
  });
}
