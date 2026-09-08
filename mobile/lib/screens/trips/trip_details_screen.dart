import 'package:flutter/material.dart';

import '../../core/constants/expense_categories.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../models/member_financial_summary.dart';
import '../../models/trip_member.dart';
import '../../models/wallet_summary.dart';
import '../../services/auth_service.dart';
import '../../services/member_financial_service.dart';
import '../../services/trip_service.dart';
import '../expenses/expense_details_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../expenses/pay_expense_screen.dart';
import '../settlement/settlement_screen.dart';
import '../wallet/contribution_history_screen.dart';
import '../wallet/wallet_screen.dart';
import 'close_trip_screen.dart';
import '../../core/network/network_info.dart';
import '../../data/repositories/trip_repository.dart';
import '../../widgets/sync_status_badge.dart';
import 'member_financial_screen.dart';
import 'members_screen.dart';
import 'statistics_screen.dart';
import 'trip_activity_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Trip _trip;
  final AuthService _authService = AuthService();

  WalletSummary? _walletSummary;
  int? _memberCount;
  int? _expenseCount;
  int? _contributionCount;
  List<Expense> _recentExpenses = [];
  List<Contribution> _recentContributions = [];
  List<MemberFinancialSummary> _memberSummaries = [];
  Map<String, String> _memberNames = {};
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = TripRepository.instance;
      final tripFuture =
          repo.getTrip(_trip.id).then((t) => t ?? _trip).catchError((_) => _trip);
      final walletFuture =
          repo.getWallet(_trip.id).catchError((_) => null);
      final membersFuture =
          repo.getMembers(_trip.id).catchError((_) => <TripMember>[]);
      final expensesFuture =
          repo.getExpenses(_trip.id).catchError((_) => <Expense>[]);
      final contributionsFuture =
          repo.getContributions(_trip.id).catchError((_) => <Contribution>[]);
      final userFuture = _authService.getCurrentUser().catchError((_) => null);
      final financialSummaryFuture =
          MemberFinancialService().getSummary(_trip.id).catchError((_) => <MemberFinancialSummary>[]);

      final results = await Future.wait([
        tripFuture,
        walletFuture,
        membersFuture,
        expensesFuture,
        contributionsFuture,
        userFuture,
        financialSummaryFuture,
      ]);

      if (!mounted) return;

      final updatedTrip = results[0] as Trip;
      final summary = results[1] as WalletSummary?;
      final members = results[2] as List<TripMember>;
      final expenses = results[3] as List<Expense>;
      final contributions = results[4] as List<Contribution>;
      final currentUser = results[5] as Map<String, dynamic>?;
      final memberSummaries = results[6] as List<MemberFinancialSummary>;

      final names = <String, String>{};
      for (final m in members) {
        names[m.userId] = m.name;
        names[m.id] = m.name;
      }

      setState(() {
        _trip = updatedTrip;
        _walletSummary = summary;
        _memberCount = members.length;
        _expenseCount = expenses.length;
        _contributionCount = contributions.length;
        _recentExpenses = expenses.take(3).toList();
        _recentContributions = contributions.take(3).toList();
        _memberSummaries = memberSummaries;
        _memberNames = names;
        _isAdmin = currentUser != null && currentUser['id'] == _trip.adminId;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatMoney(int paise) {
    return '${_trip.currency} ${(paise / 100).toStringAsFixed(2)}';
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _showEditTripDialog() async {
    final nameController = TextEditingController(text: _trip.name);
    final destinationController =
        TextEditingController(text: _trip.destination ?? '');
    final descriptionController =
        TextEditingController(text: _trip.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Trip Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Trip Name *',
                  hintText: 'e.g. Goa Vacation',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g. North Goa',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Trip itinerary notes...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updated = await TripService().updateTrip(
          _trip.id,
          name: nameController.text.trim(),
          destination: destinationController.text.trim().isNotEmpty
              ? destinationController.text.trim()
              : null,
          description: descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
        );
        if (mounted) {
          setState(() {
            _trip = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip details updated successfully')),
          );
          _loadDashboard();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _trip.status == 'CLOSED';

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        actions: [
          if (_isAdmin && !isClosed)
            IconButton(
              onPressed: _showEditTripDialog,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Trip Details',
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripActivityScreen(
                    tripId: _trip.id,
                    tripName: _trip.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Activity Timeline',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(isClosed),
    );
  }

  Widget _buildBody(bool isClosed) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _walletSummary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: SyncStatusBadge(),
            ),
          ),
          _buildTripHeader(),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 16),
          _buildMemberFinancialSnapshotSection(),
          const SizedBox(height: 20),
          _buildRecentExpensesSection(),
          _buildRecentContributionsSection(),
          const SizedBox(height: 8),
          const Text(
            'Trip Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            icon: Icons.people_outline,
            title: 'Members',
            subtitle: isClosed
                ? 'View trip members (${_memberCount ?? 0})'
                : 'Manage trip members (${_memberCount ?? 0})',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MembersScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          _buildSection(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: _walletSummary != null
                ? 'Balance: ${_formatMoney(_walletSummary!.balancePaise)}'
                : 'View common trip wallet',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          _buildSection(
            context,
            icon: Icons.payments_outlined,
            title: 'Contributions',
            subtitle: isClosed
                ? 'View all contributions (${_contributionCount ?? 0})'
                : 'Record and view contributions (${_contributionCount ?? 0})',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContributionHistoryScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          _buildSection(
            context,
            icon: Icons.account_balance_outlined,
            title: 'Member Finances',
            subtitle: 'View contributions and spending by member',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberFinancialScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          _buildSection(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Pay / Expenses',
            subtitle: isClosed
                ? 'View trip expenses (${_expenseCount ?? 0})'
                : 'Record expenses from the common wallet (${_expenseCount ?? 0})',
            onTap: () {
              if (isClosed) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseHistoryScreen(trip: _trip),
                  ),
                ).then((_) => _loadDashboard());
                return;
              }

              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.payment),
                          title: const Text('Pay New Expense'),
                          subtitle: const Text(
                            'Record an expense from the common wallet',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PayExpenseScreen(trip: _trip),
                              ),
                            ).then((_) => _loadDashboard());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Expense History'),
                          subtitle: const Text('View all trip expenses'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExpenseHistoryScreen(trip: _trip),
                              ),
                            ).then((_) => _loadDashboard());
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          _buildSection(
            context,
            icon: Icons.bar_chart_outlined,
            title: 'Statistics',
            subtitle: 'View trip spending statistics',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          _buildSection(
            context,
            icon: Icons.history_rounded,
            title: 'Activity Timeline',
            subtitle: 'View full audit log of trip events',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripActivityScreen(
                    tripId: _trip.id,
                    tripName: _trip.name,
                  ),
                ),
              );
            },
          ),
          _buildSection(
            context,
            icon: Icons.handshake_outlined,
            title: 'Settlement',
            subtitle: 'Calculate who should receive or pay',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettlementScreen(trip: _trip),
                ),
              );
              _loadDashboard();
            },
          ),
          if (!isClosed && _isAdmin)
            _buildSection(
              context,
              icon: Icons.lock_outline,
              title: 'Close Trip',
              subtitle: 'Finalise the trip and lock financial changes',
              onTap: () async {
                final isOnline = await NetworkInfo.instance.isConnected;
                if (!mounted) return;
                if (!isOnline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Internet connection required for this operation.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CloseTripScreen(trip: _trip),
                  ),
                );

                if (result == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final balanceStr = _walletSummary != null
        ? _formatMoney(_walletSummary!.balancePaise)
        : '—';
    final totalContribStr = _walletSummary != null
        ? _formatMoney(_walletSummary!.totalContributionsPaise)
        : '—';
    final totalExpenseStr = _walletSummary != null
        ? _formatMoney(_walletSummary!.totalExpensesPaise)
        : '—';
    final memberStr = _memberCount != null ? '$_memberCount' : '—';
    final expenseStr = _expenseCount != null ? '$_expenseCount' : '—';
    final contributionStr =
        _contributionCount != null ? '$_contributionCount' : '—';

    return Column(
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 34,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Common Wallet Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        balanceStr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Inflow',
                totalContribStr,
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Total Outflow',
                totalExpenseStr,
                Icons.arrow_upward,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Members',
                memberStr,
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Expenses',
                expenseStr,
                Icons.receipt_long,
                Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Contributions',
                contributionStr,
                Icons.payments,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberFinancialSnapshotSection() {
    if (_memberSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_rounded, size: 20, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Member Net Positions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemberFinancialScreen(trip: _trip),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._memberSummaries.take(4).map((member) {
              final net = member.netPaise;
              final isPositive = net > 0;
              final isNegative = net < 0;

              final Color color = isPositive
                  ? Colors.green.shade700
                  : isNegative
                      ? Colors.red.shade700
                      : Colors.grey.shade700;
              final String label = isPositive
                  ? '+${_formatMoney(net)} (gets back)'
                  : isNegative
                      ? '-${_formatMoney(net.abs())} (owes)'
                      : '${_formatMoney(0)} (settled)';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
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

  Widget _buildRecentExpensesSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseHistoryScreen(trip: _trip),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            if (_recentExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No expenses recorded yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ..._recentExpenses.map((expense) {
                final payerName = _memberNames[expense.paidBy] ?? 'Member';
                final catColor = getExpenseCategoryColor(expense.category);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: catColor.withValues(alpha: 0.15),
                    child: Icon(
                      getExpenseCategoryIcon(expense.category),
                      color: catColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    expense.description?.isNotEmpty == true
                        ? expense.description!
                        : expense.category,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Paid by $payerName • ${_formatDate(expense.createdAt)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    _formatMoney(expense.amountPaise),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseDetailsScreen(
                          trip: _trip,
                          expenseId: expense.id,
                        ),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentContributionsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Contributions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ContributionHistoryScreen(trip: _trip),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            if (_recentContributions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No contributions recorded yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ..._recentContributions.map((contrib) {
                final memberName = _memberNames[contrib.memberId] ?? 'Member';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      memberName.isNotEmpty
                          ? memberName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    memberName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${contrib.paymentMethod} • ${_formatDate(contrib.createdAt)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    _formatMoney(contrib.amountPaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    _trip.name.isNotEmpty ? _trip.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _trip.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_trip.destination != null)
                        Text(
                          _trip.destination!,
                          style: const TextStyle(fontSize: 15),
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_trip.status),
                  backgroundColor: _trip.status == 'CLOSED'
                      ? Colors.grey.shade300
                      : Colors.green.shade100,
                ),
              ],
            ),
            if (_trip.description != null && _trip.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_trip.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.currency_exchange, size: 20),
                const SizedBox(width: 8),
                Text('Currency: ${_trip.currency}'),
              ],
            ),
            if (_trip.startDate != null || _trip.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Text('${_trip.startDate ?? '—'} → ${_trip.endDate ?? '—'}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
