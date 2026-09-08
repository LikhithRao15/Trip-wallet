import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/wallet_summary.dart';
import '../../models/trip_member.dart';
import '../../models/expense.dart';
import '../../models/contribution.dart';
import 'members_screen.dart';
import '../wallet/wallet_screen.dart';
import 'statistics_screen.dart';
import 'member_financial_screen.dart';
import 'close_trip_screen.dart';
import '../expenses/pay_expense_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../settlement/settlement_screen.dart';
import '../wallet/contribution_history_screen.dart';
import '../../services/wallet_service.dart';
import '../../services/members_service.dart';
import '../../services/expense_service.dart';
import '../../services/contribution_service.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Trip _trip;
  final WalletService _walletService = WalletService();
  final MemberService _memberService = MemberService();
  final ExpenseService _expenseService = ExpenseService();
  final ContributionService _contributionService = ContributionService();
  final AuthService _authService = AuthService();
  final TripService _tripService = TripService();

  WalletSummary? _walletSummary;
  int? _memberCount;
  int? _expenseCount;
  int? _contributionCount;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final tripFuture =
          _tripService.getTrip(_trip.id).catchError((_) => _trip);
      final walletFuture = _walletService
          .getWalletSummary(_trip.id)
          .then<WalletSummary?>((w) => w)
          .catchError((_) => null);
      final membersFuture = _memberService
          .getMembers(_trip.id)
          .then<List<TripMember>>((m) => m)
          .catchError((_) => <TripMember>[]);
      final expensesFuture = _expenseService
          .getExpenses(_trip.id)
          .then<List<Expense>>((e) => e)
          .catchError((_) => <Expense>[]);
      final contributionsFuture = _contributionService
          .getContributions(_trip.id)
          .then<List<Contribution>>((c) => c)
          .catchError((_) => <Contribution>[]);
      final userFuture = _authService.getMe().catchError((_) => null);

      final results = await Future.wait([
        tripFuture,
        walletFuture,
        membersFuture,
        expensesFuture,
        contributionsFuture,
        userFuture,
      ]);

      if (!mounted) return;

      final updatedTrip = results[0] as Trip;
      final summary = results[1] as WalletSummary?;
      final members = results[2] as List<TripMember>;
      final expenses = results[3] as List<Expense>;
      final contributions = results[4] as List<Contribution>;
      final currentUser = results[5] as Map<String, dynamic>?;

      setState(() {
        _trip = updatedTrip;
        _walletSummary = summary;
        _memberCount = members.length;
        _expenseCount = expenses.length;
        _contributionCount = contributions.length;
        _isAdmin = currentUser != null && currentUser['id'] == _trip.adminId;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatMoney(int paise) {
    return '${_trip.currency} ${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _trip.status == 'CLOSED';

    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.name),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            _buildTripHeader(),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 20),

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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CloseTripScreen(trip: _trip),
                    ),
                  );

                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final balanceStr = _walletSummary != null
        ? _formatMoney(_walletSummary!.balancePaise)
        : '—';
    final memberStr = _memberCount != null ? '$_memberCount' : '—';
    final expenseStr = _expenseCount != null ? '$_expenseCount' : '—';
    final contributionStr =
        _contributionCount != null ? '$_contributionCount' : '—';

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Wallet Balance',
            balanceStr,
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
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
            Colors.orange,
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
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
