import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/statistics.dart';
import '../../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  final Trip trip;

  const StatisticsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();

  StatisticsResult? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await _statisticsService.getStatistics(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _statistics = result;
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
        title: const Text('Trip Statistics'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadStatistics,
            icon: const Icon(Icons.refresh),
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
                onPressed: _loadStatistics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _statistics!;

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverview(stats),

          const SizedBox(height: 24),

          _buildSectionTitle(
            'Spending by Category',
            Icons.category_outlined,
          ),

          const SizedBox(height: 12),

          _buildCategorySection(stats),

          const SizedBox(height: 24),

          _buildSectionTitle(
            'Spending by Member',
            Icons.people_outline,
          ),

          const SizedBox(height: 12),

          _buildMemberSection(stats),

          const SizedBox(height: 24),

          _buildSectionTitle(
            'Spending by Date',
            Icons.calendar_month_outlined,
          ),

          const SizedBox(height: 12),

          _buildDateSection(stats),
        ],
      ),
    );
  }

  Widget _buildOverview(StatisticsResult stats) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Trip Spending',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(stats.totalExpensesPaise),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildSmallStat(
                'Contributions',
                _formatMoney(stats.totalContributionsPaise),
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallStat(
                'Wallet',
                _formatMoney(stats.walletBalancePaise),
                Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildSmallStat(
          'Expenses',
          '${stats.expenseCount}',
          Icons.receipt_long_outlined,
        ),
      ],
    );
  }

  Widget _buildSmallStat(
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

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(StatisticsResult stats) {
    if (stats.byCategory.isEmpty) {
      return _emptyCard('No category data yet');
    }

    final maxAmount = stats.byCategory
        .map((item) => item.amountPaise)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: stats.byCategory.map((item) {
        final progress = maxAmount == 0
            ? 0.0
            : item.amountPaise / maxAmount;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatMoney(item.amountPaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.expenseCount} expense${item.expenseCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberSection(StatisticsResult stats) {
    if (stats.byMember.isEmpty) {
      return _emptyCard('No member spending data yet');
    }

    return Column(
      children: stats.byMember.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                item.name.isEmpty
                    ? '?'
                    : item.name[0].toUpperCase(),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.expenseCount} expense${item.expenseCount == 1 ? '' : 's'}',
            ),
            trailing: Text(
              _formatMoney(item.amountPaise),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSection(StatisticsResult stats) {
    if (stats.byDate.isEmpty) {
      return _emptyCard('No date-wise data yet');
    }

    return Column(
      children: stats.byDate.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.calendar_today),
            ),
            title: Text(
              item.date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.expenseCount} expense${item.expenseCount == 1 ? '' : 's'}',
            ),
            trailing: Text(
              _formatMoney(item.amountPaise),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message),
        ),
      ),
    );
  }
}