import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/wallet_summary.dart';
import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import 'add_contribution_screen.dart';
import 'contribution_history_screen.dart';
import 'wallet_transactions_screen.dart';
import '../expenses/pay_expense_screen.dart';

class WalletScreen extends StatefulWidget {
  final Trip trip;

  const WalletScreen({
    super.key,
    required this.trip,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  WalletSummary? _summary;
  List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }
  Future<void> _openAddContribution() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddContributionScreen(
        trip: widget.trip,
      ),
    ),
  );

  if (result == true && mounted) {
    await _loadWallet();
  }
}

Future<void> _openPayExpense() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PayExpenseScreen(
        trip: widget.trip,
      ),
    ),
  );

  if (result == true && mounted) {
    await _loadWallet();
  }
}

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary =
          await _walletService.getWalletSummary(widget.trip.id);

      final transactions =
          await _walletService.getTransactions(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatMoney(int paise) {
    return '${widget.trip.currency} ${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Wallet'),
        actions: [
  IconButton(
    onPressed: _isLoading ? null : _openAddContribution,
    icon: const Icon(Icons.add),
    tooltip: 'Add Contribution',
  ),
  IconButton(
    onPressed: _isLoading
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContributionHistoryScreen(
                  trip: widget.trip,
                ),
              ),
            );
          },
    icon: const Icon(Icons.history),
    tooltip: 'Contribution History',
  ),
  IconButton(
    onPressed: _isLoading ? null : _openPayExpense,
    icon: const Icon(Icons.payment),
    tooltip: 'Pay Expense',
  ),
  IconButton(
    onPressed: _loadWallet,
    icon: const Icon(Icons.refresh),
    tooltip: 'Refresh',
  ),
  IconButton(
  onPressed: _isLoading
      ? null
      : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalletTransactionsScreen(
                trip: widget.trip,
              ),
            ),
          );
        },
  icon: const Icon(Icons.receipt_long_outlined),
  tooltip: 'All Transactions',
),
],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
                onPressed: _loadWallet,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = _summary!;

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(summary),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contributions',
                  _formatMoney(
                    summary.totalContributionsPaise,
                  ),
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  _formatMoney(
                    summary.totalExpensesPaise,
                  ),
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_transactions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No transactions yet',
                  ),
                ),
              ),
            )
          else
            ..._transactions.map(_buildTransaction),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(WalletSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Available Balance',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMoney(summary.balancePaise),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${summary.transactionCount} transactions',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaction(WalletTransaction transaction) {
  final isCredit = transaction.amountPaise > 0;

  String title;

  switch (transaction.transactionType) {
    case 'CONTRIBUTION':
      title = 'Contribution';
      break;

    case 'CONTRIBUTION_ADJUSTMENT':
      title = 'Contribution Correction';
      break;

    case 'EXPENSE':
      title = 'Expense';
      break;

    case 'EXPENSE_ADJUSTMENT':
      title = 'Expense Correction';
      break;

    case 'EXPENSE_REVERSAL':
      title = 'Expense Reversal';
      break;

    default:
      title = transaction.transactionType;
  }

  IconData icon;

  switch (transaction.transactionType) {
    case 'CONTRIBUTION':
      icon = Icons.add_circle_outline;
      break;

    case 'CONTRIBUTION_ADJUSTMENT':
      icon = Icons.edit_outlined;
      break;

    case 'EXPENSE':
      icon = Icons.remove_circle_outline;
      break;

    case 'EXPENSE_ADJUSTMENT':
      icon = Icons.edit_outlined;
      break;

    case 'EXPENSE_REVERSAL':
      icon = Icons.undo_outlined;
      break;

    default:
      icon = Icons.account_balance_wallet_outlined;
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(
        transaction.description ?? 'Wallet transaction',
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}'
        '₹${_formatMoney(transaction.amountPaise.abs())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
    ),
  );
}
}