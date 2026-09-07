import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';

class WalletTransactionsScreen extends StatefulWidget {
  final Trip trip;

  const WalletTransactionsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState
    extends State<WalletTransactionsScreen> {
  final WalletService _walletService = WalletService();

  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final transactions =
          await _walletService.getTransactions(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _loading = false;
      });
    }
  }

  String _formatMoney(int paise) {
    return '${widget.trip.currency} '
        '${(paise.abs() / 100).toStringAsFixed(2)}';
  }

  String _transactionTitle(
    String type,
  ) {
    switch (type) {
      case 'CONTRIBUTION':
        return 'Contribution';

      case 'CONTRIBUTION_ADJUSTMENT':
        return 'Contribution Correction';

      case 'EXPENSE':
        return 'Expense';

      case 'EXPENSE_ADJUSTMENT':
        return 'Expense Correction';

      case 'EXPENSE_REVERSAL':
        return 'Expense Reversal';

      default:
        return type;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type) {
      case 'CONTRIBUTION':
      case 'CONTRIBUTION_ADJUSTMENT':
        return Icons.add_circle_outline;

      case 'EXPENSE':
        return Icons.remove_circle_outline;

      case 'EXPENSE_ADJUSTMENT':
        return Icons.edit_outlined;

      case 'EXPENSE_REVERSAL':
        return Icons.undo_outlined;

      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Transactions'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTransactions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No wallet transactions yet.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];

          bool isCredit;

switch (transaction.transactionType) {
  case 'CONTRIBUTION':
    isCredit = true;
    break;

  case 'CONTRIBUTION_ADJUSTMENT':
    isCredit = transaction.amountPaise >= 0;
    break;

  case 'EXPENSE':
    isCredit = false;
    break;

  case 'EXPENSE_ADJUSTMENT':
    isCredit = transaction.amountPaise <= 0;
    break;

  case 'EXPENSE_REVERSAL':
    isCredit = true;
    break;

  default:
    isCredit = transaction.amountPaise >= 0;
}

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  _transactionIcon(
                    transaction.transactionType,
                  ),
                ),
              ),
              title: Text(
                _transactionTitle(
                  transaction.transactionType,
                ),
              ),
              subtitle: Text(
                transaction.description ??
                    'Wallet transaction',
              ),
              trailing: Text(
                '${isCredit ? '+' : '-'}'
                '${_formatMoney(transaction.amountPaise)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isCredit
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}