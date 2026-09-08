import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/expense.dart';

int? parseAmountToPaise(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  final parts = text.split('.');
  if (parts.length > 2) return null;

  final rupees = int.tryParse(parts[0]);
  if (rupees == null || rupees < 0) return null;

  int paise = 0;
  if (parts.length == 2) {
    final decimal = parts[1];
    if (decimal.length > 2) return null;
    final padded = decimal.padRight(2, '0');
    paise = int.tryParse(padded) ?? 0;
  }

  final amountPaise = rupees * 100 + paise;
  if (amountPaise <= 0) return null;

  return amountPaise;
}

void main() {
  group('Safe Money Parsing (Paise)', () {
    test('parses whole rupees accurately', () {
      expect(parseAmountToPaise('700'), 70000);
      expect(parseAmountToPaise('1'), 100);
      expect(parseAmountToPaise('10000'), 1000000);
    });

    test('parses rupees with two decimal places', () {
      expect(parseAmountToPaise('700.50'), 70050);
      expect(parseAmountToPaise('0.01'), 1);
      expect(parseAmountToPaise('12.99'), 1299);
    });

    test('parses rupees with single decimal place (pads with 0)', () {
      expect(parseAmountToPaise('700.5'), 70050);
      expect(parseAmountToPaise('1.1'), 110);
    });

    test('rejects invalid, negative, or more than 2 decimal digits', () {
      expect(parseAmountToPaise(''), isNull);
      expect(parseAmountToPaise('   '), isNull);
      expect(parseAmountToPaise('-50'), isNull);
      expect(parseAmountToPaise('0'), isNull);
      expect(parseAmountToPaise('0.00'), isNull);
      expect(parseAmountToPaise('10.555'), isNull);
      expect(parseAmountToPaise('abc'), isNull);
      expect(parseAmountToPaise('12.34.56'), isNull);
    });
  });

  group('Expense Model & Split Modes', () {
    test('deserializes Expense with default EQUAL split_mode', () {
      final json = {
        'id': 'exp-1',
        'trip_id': 'trip-1',
        'wallet_id': 'wal-1',
        'paid_by': 'user-1',
        'amount_paise': 70000,
        'category': 'FOOD',
        'description': 'Dinner',
        'status': 'CONFIRMED',
        'created_at': '2026-09-08T10:00:00Z',
        'splits': [
          {'member_id': 'user-1', 'amount_paise': 35000},
          {'member_id': 'user-2', 'amount_paise': 35000},
        ],
      };

      final expense = Expense.fromJson(json);
      expect(expense.id, 'exp-1');
      expect(expense.splitMode, 'EQUAL');
      expect(expense.amountPaise, 70000);
      expect(expense.splits.length, 2);
      expect(expense.splits[0].amountPaise, 35000);
      expect(expense.splits[1].amountPaise, 35000);
    });

    test('deserializes Expense with CUSTOM split_mode', () {
      final json = {
        'id': 'exp-2',
        'trip_id': 'trip-1',
        'wallet_id': 'wal-1',
        'paid_by': 'user-1',
        'amount_paise': 10000,
        'category': 'TRAVEL',
        'description': 'Cab',
        'split_mode': 'CUSTOM',
        'status': 'CONFIRMED',
        'created_at': '2026-09-08T11:00:00Z',
        'splits': [
          {'member_id': 'user-1', 'amount_paise': 6000},
          {'member_id': 'user-2', 'amount_paise': 4000},
        ],
      };

      final expense = Expense.fromJson(json);
      expect(expense.splitMode, 'CUSTOM');
      expect(expense.splits.fold<int>(0, (s, e) => s + e.amountPaise), 10000);
    });

    test('deserializes Expense with PERCENTAGE split_mode', () {
      final json = {
        'id': 'exp-3',
        'trip_id': 'trip-1',
        'wallet_id': 'wal-1',
        'paid_by': 'user-1',
        'amount_paise': 100,
        'category': 'SHOPPING',
        'split_mode': 'PERCENTAGE',
        'status': 'CONFIRMED',
        'created_at': '2026-09-08T12:00:00Z',
        'splits': [
          {'member_id': 'user-1', 'amount_paise': 34},
          {'member_id': 'user-2', 'amount_paise': 33},
          {'member_id': 'user-3', 'amount_paise': 33},
        ],
      };

      final expense = Expense.fromJson(json);
      expect(expense.splitMode, 'PERCENTAGE');
      expect(expense.splits.fold<int>(0, (s, e) => s + e.amountPaise), 100);
    });
  });
}
