import 'package:flutter/material.dart';

import '../../models/member_financial_summary.dart';
import '../../models/trip.dart';
import '../../models/wallet_summary.dart';
import '../../models/wallet_transaction.dart';
import '../../services/auth_service.dart';
import '../../services/contribution_service.dart';
import '../../services/member_financial_service.dart';
import '../../services/wallet_service.dart';
import 'add_contribution_screen.dart';
import 'contribution_history_screen.dart';
import 'member_contribution_flow_screen.dart';
import 'online_payment_screen.dart';
import 'payment_history_screen.dart';
import 'pending_contributions_screen.dart';
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
  final ContributionService _contributionService = ContributionService();
  final MemberFinancialService _memberFinancialService = MemberFinancialService();
  final AuthService _authService = AuthService();

  WalletSummary? _summary;
  List<WalletTransaction> _transactions = [];
  List<MemberFinancialSummary> _memberSummaries = [];

  bool _isLoading = true;
  String? _error;
  int _pendingContributionsCount = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadWallet();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        final userId = user['id']?.toString();
        setState(() {
          _isAdmin = userId == widget.trip.adminId;
        });
      }
    } catch (_) {}
  }

  Future<void> _openOnlinePayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlinePaymentScreen(
          trip: widget.trip,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadWallet();
    }
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

  Future<void> _openMemberContribution() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberContributionFlowScreen(
          trip: widget.trip,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadWallet();
    }
  }

  Future<void> _openPendingReview() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingContributionsScreen(
          trip: widget.trip,
        ),
      ),
    );

    if (mounted) {
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

      int pendingCount = 0;
      try {
        final pending =
            await _contributionService.getPendingContributions(widget.trip.id);
        pendingCount = pending.length;
      } catch (_) {
        // Non-admin may get 403, which is normal
      }

      List<MemberFinancialSummary> memberSummaries = [];
      try {
        memberSummaries = await _memberFinancialService.getSummary(widget.trip.id);
      } catch (_) {
        // Non-critical fallback
      }

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _transactions = transactions;
        _memberSummaries = memberSummaries;
        _pendingContributionsCount = pendingCount;
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
          if (widget.trip.status != 'CLOSED') ...[
            // Admin Pending Review Icon with badge
            if (_isAdmin)
              Badge(
                isLabelVisible: _pendingContributionsCount > 0,
                label: Text('$_pendingContributionsCount'),
                child: IconButton(
                  onPressed: _isLoading ? null : _openPendingReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  tooltip: 'Review Pending Contributions ($_pendingContributionsCount)',
                ),
              ),
          ],
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
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(
                          trip: widget.trip,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadWallet();
                    });
                  },
            icon: const Icon(Icons.receipt_outlined),
            tooltip: 'Payment History',
          ),
          if (widget.trip.status != 'CLOSED' && _isAdmin)
            IconButton(
              onPressed: _isLoading ? null : _openPayExpense,
              icon: const Icon(Icons.payment),
              tooltip: 'Pay Expense (Admin Only)',
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
          if (_isAdmin && _pendingContributionsCount > 0) ...[
            InkWell(
              onTap: _openPendingReview,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_pendingContributionsCount contribution(s) pending your verification.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
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

          const SizedBox(height: 18),

          _buildMemberContributionsBreakdown(summary),

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
            if (widget.trip.status != 'CLOSED') ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openOnlinePayment,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Add Money (Instant Online Payment)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isAdmin ? _openAddContribution : _openMemberContribution,
                icon: const Icon(Icons.currency_rupee, size: 16),
                label: Text(
                  _isAdmin ? 'Record Offline Cash / Transfer' : 'Submit Manual Offline Transfer',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
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

  Widget _buildMemberContributionsBreakdown(WalletSummary summary) {
    final totalPaise = summary.totalContributionsPaise;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Member Contributions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_memberSummaries.length} members',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_memberSummaries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No member contributions recorded yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              )
            else
              ..._memberSummaries.map((m) {
                final pct = totalPaise > 0 ? (m.contributedPaise / totalPaise) : 0.0;
                final isAdminMember = m.memberId == widget.trip.adminId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdminMember) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.indigo.shade200, width: 0.5),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMoney(m.contributedPaise),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: m.contributedPaise > 0 ? const Color(0xFF10B981) : Colors.grey.shade600,
                                ),
                              ),
                              if (totalPaise > 0 && m.contributedPaise > 0)
                                Text(
                                  '${(pct * 100).toStringAsFixed(0)}% of pool',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            m.contributedPaise > 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaction(WalletTransaction transaction) {
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
        '${_formatMoney(transaction.amountPaise.abs())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
    ),
  );
}
}