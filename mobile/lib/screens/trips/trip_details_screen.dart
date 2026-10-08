import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/expense_categories.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/member_financial_summary.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../models/wallet_summary.dart';
import '../../services/auth_service.dart';
import '../../services/member_financial_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/sync_status_badge.dart';
import '../expenses/expense_details_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../expenses/pay_expense_screen.dart';
import '../settlement/settlement_screen.dart';
import '../wallet/add_contribution_screen.dart';
import '../wallet/contribution_history_screen.dart';
import '../wallet/online_payment_screen.dart';
import '../wallet/wallet_screen.dart';
import 'close_trip_screen.dart';
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

class _TripDetailsScreenState extends State<TripDetailsScreen> with SingleTickerProviderStateMixin {
  late Trip _trip;
  final AuthService _authService = AuthService();
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = TripRepository.instance;
      final tripFuture = repo.getTrip(_trip.id).then((t) => t ?? _trip).catchError((_) => _trip);
      final walletFuture = repo.getWallet(_trip.id).catchError((_) => null);
      final membersFuture = repo.getMembers(_trip.id).catchError((_) => <TripMember>[]);
      final expensesFuture = repo.getExpenses(_trip.id).catchError((_) => <Expense>[]);
      final contributionsFuture = repo.getContributions(_trip.id).catchError((_) => <Contribution>[]);
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
        _recentExpenses = expenses.take(5).toList();
        _recentContributions = contributions.take(5).toList();
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
    final absPaise = paise.abs();
    final inr = (absPaise / 100).toStringAsFixed(2);
    final sign = paise < 0 ? '-' : '';
    return '$sign${_trip.currency} $inr';
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
    final destinationController = TextEditingController(text: _trip.destination ?? '');
    final descriptionController = TextEditingController(text: _trip.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Trip Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Trip Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updated = await TripService().updateTrip(
          _trip.id,
          name: nameController.text.trim(),
          destination: destinationController.text.trim().isNotEmpty ? destinationController.text.trim() : null,
          description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
        );
        if (mounted) {
          setState(() => _trip = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip updated successfully')),
          );
          _loadDashboard();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = _trip.status == 'CLOSED';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _trip.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_trip.destination != null && _trip.destination!.isNotEmpty)
              Text(
                _trip.destination!,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          const SyncStatusBadge(),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Activity Timeline',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripActivityScreen(tripId: _trip.id, tripName: _trip.name),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') _showEditTripDialog();
              if (value == 'members') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MembersScreen(trip: _trip)),
                );
              }
              if (value == 'analytics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatisticsScreen(trip: _trip)),
                );
              }
              if (value == 'close' && _isAdmin && !isClosed) {
                final closed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => CloseTripScreen(trip: _trip)),
                );
                if (closed == true) _loadDashboard();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.group_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Manage Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Spending Analytics'),
                  ],
                ),
              ),
              if (_isAdmin && !isClosed) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Edit Trip Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Text('Close & Settle Trip', style: TextStyle(color: Colors.amber)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded, size: 20)),
            Tab(text: 'Expenses', icon: Icon(Icons.receipt_long_rounded, size: 20)),
            Tab(text: 'Settlement', icon: Icon(Icons.balance_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, isClosed),
                _buildExpensesTab(theme, isClosed),
                _buildSettlementTab(theme, isClosed),
              ],
            ),
      floatingActionButton: (isClosed || !_isAdmin)
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PayExpenseScreen(trip: _trip)),
                );
                _loadDashboard();
              },
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Add Expense'),
            ),
    );
  }

  // =========================================================
  // TAB 1: OVERVIEW
  // =========================================================
  Widget _buildOverviewTab(ThemeData theme, bool isClosed) {
    final balancePaise = _walletSummary?.balancePaise ?? 0;
    final totalSpentPaise = _walletSummary?.totalExpensesPaise ?? 0;
    final totalInPaise = _walletSummary?.totalContributionsPaise ?? 0;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Hero Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trip Wallet Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isClosed ? 'Closed' : 'Active',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(balancePaise),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Contributed', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  Text(
                                    _formatMoney(totalInPaise),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 24, width: 1, color: Colors.white24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Spent', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  Text(
                                    _formatMoney(totalSpentPaise),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Quick Action Grid
          Row(
            children: [
              _buildQuickActionButton(
                theme: theme,
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Money',
                onTap: isClosed
                    ? null
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OnlinePaymentScreen(trip: _trip)),
                        );
                        if (result == true) {
                          _loadDashboard();
                        }
                      },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                theme: theme,
                icon: Icons.receipt_long_rounded,
                label: _isAdmin ? 'Pay Expense' : 'Expenses',
                onTap: isClosed
                    ? null
                    : () async {
                        if (!_isAdmin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Only the Trip Admin can record and pay expenses from the common wallet.'),
                              backgroundColor: Colors.indigo,
                            ),
                          );
                          _tabController.animateTo(1);
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PayExpenseScreen(trip: _trip)),
                        );
                        _loadDashboard();
                      },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                theme: theme,
                icon: Icons.group_rounded,
                label: 'Members (${_memberCount ?? 0})',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MembersScreen(trip: _trip)),
                  );
                  _loadDashboard();
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionButton(
                theme: theme,
                icon: Icons.pie_chart_rounded,
                label: 'Analytics',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StatisticsScreen(trip: _trip)),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3. Member Contributions & Balances Glance
          if (_memberSummaries.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Contributions & Balances',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MemberFinancialScreen(trip: _trip)),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 115,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _memberSummaries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final summary = _memberSummaries[index];
                  final isPositive = summary.netPaise >= 0;

                  return Container(
                    width: 155,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          summary.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Paid: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              _formatMoney(summary.contributedPaise),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPositive ? 'Surplus' : 'Owes',
                          style: TextStyle(
                            fontSize: 10,
                            color: isPositive ? const Color(0xFF10B981) : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatMoney(summary.netPaise),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isPositive ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],

          // 4. Recent Transactions List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Spending',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_recentExpenses.isNotEmpty)
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('See All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('No expenses recorded yet.'),
              ),
            )
          else
            ..._recentExpenses.map((expense) => _buildExpenseTile(theme, expense)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseTile(ThemeData theme, Expense expense) {
    final catColor = getExpenseCategoryColor(expense.category);
    final catIcon = getExpenseCategoryIcon(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(catIcon, color: catColor, size: 20),
        ),
        title: Text(
          expense.description ?? 'Expense',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(expense.createdAt)} • ${_memberNames[expense.paidBy] ?? 'Member'}',
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Text(
          _formatMoney(expense.amountPaise),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseDetailsScreen(trip: _trip, expenseId: expense.id),
            ),
          );
          _loadDashboard();
        },
      ),
    );
  }

  // =========================================================
  // TAB 2: EXPENSES
  // =========================================================
  Widget _buildExpensesTab(ThemeData theme, bool isClosed) {
    if (_recentExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No expenses recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Record group expenses paid from the wallet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Expenses (${_expenseCount ?? _recentExpenses.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExpenseHistoryScreen(trip: _trip)),
                  );
                },
                tooltip: 'Filter & Search',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentExpenses.map((e) => _buildExpenseTile(theme, e)),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExpenseHistoryScreen(trip: _trip)),
                );
              },
              icon: const Icon(Icons.list_rounded),
              label: const Text('Open Full Expense Ledger'),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 3: SETTLEMENT
  // =========================================================
  Widget _buildSettlementTab(ThemeData theme, bool isClosed) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.balance_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    const Text('Trip Balance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'When the trip concludes, debt simplification calculates the minimal transfers required so everyone settles their exact share.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettlementScreen(trip: _trip)),
                    );
                  },
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Open Settlement Matrix'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Member Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._memberSummaries.map((summary) {
            final isPositive = summary.netPaise >= 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
              ),
              child: ListTile(
                title: Text(summary.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Spent: ${_formatMoney(summary.spentPaise)} • Contributed: ${_formatMoney(summary.contributedPaise)}'),
                trailing: Text(
                  _formatMoney(summary.netPaise),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
