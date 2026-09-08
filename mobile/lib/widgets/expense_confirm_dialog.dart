import 'package:flutter/material.dart';

class ExpenseSplitBreakdown {
  final String memberName;
  final int amountPaise;
  final String? percentage;

  const ExpenseSplitBreakdown({
    required this.memberName,
    required this.amountPaise,
    this.percentage,
  });
}

class ExpenseConfirmDialog extends StatelessWidget {
  final String tripCurrency;
  final int totalAmountPaise;
  final String category;
  final String? description;
  final int currentWalletBalancePaise;
  final List<ExpenseSplitBreakdown> splits;

  const ExpenseConfirmDialog({
    super.key,
    required this.tripCurrency,
    required this.totalAmountPaise,
    required this.category,
    this.description,
    required this.currentWalletBalancePaise,
    required this.splits,
  });

  String _formatMoney(int paise) {
    return '$tripCurrency ${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final projectedBalancePaise = currentWalletBalancePaise - totalAmountPaise;
    final isNegative = projectedBalancePaise < 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Confirm Expense'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Expense Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(totalAmountPaise),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (description != null && description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Note: ${description!.trim()}',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),

            // Splits Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Split Breakdown',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${splits.length} participant${splits.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(),

            // Itemized Splits List
            ...splits.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.memberName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatMoney(s.amountPaise),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            const Text(
              'Wallet Impact',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Wallet Impact details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Balance:', style: TextStyle(fontSize: 13)),
                Text(_formatMoney(currentWalletBalancePaise),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Projected Balance:', style: TextStyle(fontSize: 13)),
                Text(
                  _formatMoney(projectedBalancePaise),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            if (isNegative) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This expense exceeds the current wallet balance.',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm Expense'),
        ),
      ],
    );
  }
}
