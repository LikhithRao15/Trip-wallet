import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isExporting = false;
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
      final result = await _statisticsService.getStatistics(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _statistics = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatMoney(int paise) {
    return '${widget.trip.currency} ${(paise / 100).toStringAsFixed(2)}';
  }

  String _sanitizeName(String name) {
    final cleaned = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _exportCsv({required bool isSummary}) async {
    setState(() {
      _isExporting = true;
    });

    final typeName = isSummary ? 'Financial Summary' : 'Expenses';
    final safeTripName = _sanitizeName(widget.trip.name);
    final filename = 'trip_${safeTripName.isNotEmpty ? safeTripName : widget.trip.id}_${isSummary ? 'summary' : 'expenses'}.csv';

    try {
      final csvData = isSummary
          ? await _statisticsService.exportSummaryCsv(widget.trip.id)
          : await _statisticsService.exportExpensesCsv(widget.trip.id);

      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });

      _showExportDialog(title: typeName, filename: filename, csvContent: csvData);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExportDialog({
    required String title,
    required String filename,
    required String csvContent,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_chart_outlined, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text('Export $title')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        filename,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'CSV Preview:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvContent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: csvContent));
              if (!mounted || !ctx.mounted) return;
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('$title CSV copied to clipboard as $filename'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Statistics'),
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export Reports',
              onSelected: (val) {
                if (val == 'expenses') {
                  _exportCsv(isSummary: false);
                } else if (val == 'summary') {
                  _exportCsv(isSummary: true);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'expenses',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 20),
                      SizedBox(width: 8),
                      Text('Export Expenses CSV'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'summary',
                  child: Row(
                    children: [
                      Icon(Icons.assessment_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Export Summary CSV'),
                    ],
                  ),
                ),
              ],
            ),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
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
          // Section 1: Trip Overview
          _buildTripOverview(stats),
          const SizedBox(height: 24),

          // Section 2: Category Breakdown
          _buildSectionTitle('Spending by Category', Icons.category_outlined),
          const SizedBox(height: 10),
          _buildCategorySection(stats),
          const SizedBox(height: 24),

          // Section 3: Member Spending
          _buildSectionTitle('Member Balances & Spending', Icons.people_outline),
          const SizedBox(height: 10),
          _buildMemberSection(stats),
          const SizedBox(height: 24),

          // Section 4: Daily Spending
          _buildSectionTitle('Daily Spending', Icons.calendar_month_outlined),
          const SizedBox(height: 10),
          _buildDateSection(stats),
          const SizedBox(height: 24),

          // Section 5: Top Expenses
          _buildSectionTitle('Top Expenses', Icons.star_border),
          const SizedBox(height: 10),
          _buildTopExpensesSection(stats),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section 1: Trip Overview
  // -------------------------------------------------------------
  Widget _buildTripOverview(StatisticsResult stats) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.analytics_outlined, size: 40, color: Colors.teal),
                const SizedBox(height: 8),
                const Text('Total Trip Spending', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(stats.totalExpensesPaise),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOverviewSubMetric('Avg Expense', _formatMoney(stats.averageExpensePaise)),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    _buildOverviewSubMetric('Highest', _formatMoney(stats.highestExpensePaise)),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    _buildOverviewSubMetric('Lowest', _formatMoney(stats.lowestExpensePaise)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                'Contributions',
                _formatMoney(stats.totalContributionsPaise),
                '${stats.contributorCount} contributors',
                Icons.savings_outlined,
                Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                'Wallet Balance',
                _formatMoney(stats.walletBalancePaise),
                stats.walletBalancePaise == 0 ? 'Balanced' : 'Remaining',
                Icons.account_balance_wallet_outlined,
                stats.walletBalancePaise == 0 ? Colors.green.shade700 : Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                'Expenses Count',
                '${stats.expenseCount}',
                'Recorded transactions',
                Icons.receipt_long_outlined,
                Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                'Participants',
                '${stats.participatingMemberCount}',
                'Involved in splits',
                Icons.groups_outlined,
                Colors.indigo.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewSubMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSmallCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 2: Category Breakdown
  // -------------------------------------------------------------
  Widget _buildCategorySection(StatisticsResult stats) {
    if (stats.byCategory.isEmpty) {
      return _emptyCard('No category data recorded yet.');
    }

    final maxAmount = stats.byCategory
        .map((item) => item.amountPaise)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: stats.byCategory.map((item) {
        final progress = maxAmount == 0 ? 0.0 : item.amountPaise / maxAmount;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatMoney(item.amountPaise),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.percentageOfTotal.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.teal.shade600,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.expenseCount} expense${item.expenseCount == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // Section 3: Member Spending
  // -------------------------------------------------------------
  Widget _buildMemberSection(StatisticsResult stats) {
    if (stats.byMember.isEmpty) {
      return _emptyCard('No active members recorded yet.');
    }

    return Column(
      children: stats.byMember.map((m) {
        final net = m.netPositionPaise;
        final String statusLabel;
        final Color statusColor;

        if (net > 0) {
          statusLabel = 'Gets Back ${_formatMoney(net)}';
          statusColor = Colors.green.shade800;
        } else if (net < 0) {
          statusLabel = 'Owes ${_formatMoney(net.abs())}';
          statusColor = Colors.red.shade800;
        } else {
          statusLabel = 'Settled';
          statusColor = Colors.grey.shade700;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.displayName.isNotEmpty ? m.displayName : 'Member',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Expense Share: ${_formatMoney(m.totalExpenseSharePaise)} (${m.percentageOfTotalExpenses.toStringAsFixed(1)}%)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contributed: ${_formatMoney(m.totalContributedPaise)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      '${m.expenseCount} expense${m.expenseCount == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // Section 4: Daily Spending
  // -------------------------------------------------------------
  Widget _buildDateSection(StatisticsResult stats) {
    if (stats.byDate.isEmpty) {
      return _emptyCard('No daily transactions recorded yet.');
    }

    return Column(
      children: [
        if (stats.highestSpendingDay != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Peak Spending: ${stats.highestSpendingDay} (${_formatMoney(stats.highestSpendingDayAmountPaise)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...stats.byDate.map((item) {
          final isPeak = item.date == stats.highestSpendingDay;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPeak ? Colors.amber.shade100 : Colors.grey.shade100,
                child: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isPeak ? Colors.amber.shade900 : Colors.black87,
                ),
              ),
              title: Text(
                item.date,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                '${item.expenseCount} transaction${item.expenseCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                _formatMoney(item.amountPaise),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPeak ? Colors.amber.shade900 : Colors.black87,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section 5: Top Expenses
  // -------------------------------------------------------------
  Widget _buildTopExpensesSection(StatisticsResult stats) {
    if (stats.topExpenses.isEmpty) {
      return _emptyCard('No expenses recorded yet.');
    }

    return Column(
      children: stats.topExpenses.map((exp) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: Icon(Icons.arrow_upward, color: Colors.teal.shade800, size: 20),
            ),
            title: Text(
              exp.description.isNotEmpty ? exp.description : 'Expense',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${exp.category} • Paid by ${exp.paidByName}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            trailing: Text(
              _formatMoney(exp.amountPaise),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
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
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}