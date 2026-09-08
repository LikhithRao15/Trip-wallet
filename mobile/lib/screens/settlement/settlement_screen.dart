import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/settlement.dart';
import '../../services/auth_service.dart';
import '../../services/settlement_service.dart';

class SettlementScreen extends StatefulWidget {
  final Trip trip;

  const SettlementScreen({
    super.key,
    required this.trip,
  });

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final SettlementService _settlementService = SettlementService();
  final AuthService _authService = AuthService();

  SettlementResult? _settlement;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isCompleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettlement();
  }

  Future<void> _loadSettlement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getMe();
      final result = await _settlementService.getSettlement(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _settlement = result;
        _isAdmin = user != null && user['id'] == widget.trip.adminId;
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

  Future<void> _confirmCompleteSettlement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Settlement'),
        content: const Text(
          'Are you sure you want to finalize settlement? This will lock all expenses, contributions, and member changes for this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Finalize Settlement'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final updated = await _settlementService.completeSettlement(widget.trip.id);
      if (!mounted) return;

      setState(() {
        _settlement = updated;
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settlement finalized successfully. Group ledger is now locked.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMoney(int paise) {
    return '${widget.trip.currency} ${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSettlement,
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
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSettlement,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final settlement = _settlement!;

    return RefreshIndicator(
      onRefresh: _loadSettlement,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Wallet Summary
          _buildWalletSummarySection(settlement),
          const SizedBox(height: 20),

          // Section 4: Settlement Status & Completion
          _buildStatusAndActionSection(settlement),
          const SizedBox(height: 20),

          // Section 2: Member Balances
          _buildMemberBalancesSection(settlement),
          const SizedBox(height: 20),

          // Section 3: Settlement Transfers
          _buildTransfersSection(settlement),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWalletSummarySection(SettlementResult settlement) {
    final isBalanced = settlement.isBalanced;

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
                const Text(
                  'Wallet Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBalanced ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBalanced ? Colors.green.shade400 : Colors.amber.shade700,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 14,
                        color: isBalanced ? Colors.green.shade700 : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBalanced ? 'BALANCED' : 'UNBALANCED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isBalanced ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Contributions',
                    amountPaise: settlement.totalContributionsPaise,
                    icon: Icons.savings_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Expenses',
                    amountPaise: settlement.totalExpensesPaise,
                    icon: Icons.receipt_long_outlined,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining Wallet Balance',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatMoney(settlement.walletBalancePaise),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: settlement.walletBalancePaise == 0
                        ? Colors.green.shade700
                        : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            if (!isBalanced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total contributions do not match total expenses. Remaining unspent balance: ${_formatMoney(settlement.walletBalancePaise)}.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int amountPaise,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(amountPaise),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBalancesSection(SettlementResult settlement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member Balances',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (settlement.members.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No members found')),
            ),
          )
        else
          ...settlement.members.map(_buildMemberBalanceCard),
      ],
    );
  }

  Widget _buildMemberBalanceCard(SettlementMember member) {
    final net = member.netPaise;
    final String statusLabel;
    final Color badgeColor;
    final Color textColor;
    final IconData icon;

    if (net > 0) {
      statusLabel = 'Gets Back ${_formatMoney(net)}';
      badgeColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      icon = Icons.arrow_downward_rounded;
    } else if (net < 0) {
      statusLabel = 'Owes ${_formatMoney(net.abs())}';
      badgeColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      icon = Icons.arrow_upward_rounded;
    } else {
      statusLabel = 'Settled ${_formatMoney(0)}';
      badgeColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.check_circle_outline;
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
                  radius: 18,
                  backgroundColor: textColor.withValues(alpha: 0.12),
                  child: Icon(icon, size: 20, color: textColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name.isNotEmpty ? member.name : 'Unknown Member',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (member.email.isNotEmpty)
                        Text(
                          member.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                  'Contributed: ${_formatMoney(member.totalContributedPaise)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  'Expense Share: ${_formatMoney(member.totalExpenseSharePaise)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersSection(SettlementResult settlement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settlement Transfers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (!settlement.isBalanced)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transfers can only be calculated when the group wallet is balanced (total contributions = total expenses). Current wallet balance: ${_formatMoney(settlement.walletBalancePaise)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (settlement.transfers.isEmpty)
          Card(
            color: Colors.grey.shade50,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'All balances are settled. No transfers required.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...settlement.transfers.map(
            (t) => _buildTransferCard(t, settlement.members),
          ),
      ],
    );
  }

  Widget _buildTransferCard(
    SettlementTransfer transfer,
    List<SettlementMember> members,
  ) {
    String fromName = transfer.fromName;
    if (fromName.isEmpty) {
      final m = members.where((item) => item.memberId == transfer.fromMemberId);
      fromName = m.isNotEmpty && m.first.name.isNotEmpty ? m.first.name : 'Member';
    }

    String toName = transfer.toName;
    if (toName.isEmpty) {
      final m = members.where((item) => item.memberId == transfer.toMemberId);
      toName = m.isNotEmpty && m.first.name.isNotEmpty ? m.first.name : 'Member';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.swap_horiz,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '$fromName pays $toName ${_formatMoney(transfer.amountPaise)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Settles share of ${_formatMoney(transfer.amountPaise)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            _formatMoney(transfer.amountPaise),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAndActionSection(SettlementResult settlement) {
    final status = settlement.status.toUpperCase();
    final isSettled = status == 'SETTLED';
    final isTripClosed = widget.trip.status.toUpperCase() == 'CLOSED';

    Color chipBg;
    Color chipFg;
    if (isSettled) {
      chipBg = Colors.green.shade100;
      chipFg = Colors.green.shade800;
    } else if (status == 'READY') {
      chipBg = Colors.blue.shade100;
      chipFg = Colors.blue.shade800;
    } else {
      chipBg = Colors.grey.shade200;
      chipFg = Colors.grey.shade800;
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settlement Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: chipFg,
                    ),
                  ),
                  backgroundColor: chipBg,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isSettled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade800, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Settlement Finalized — No further transactions allowed',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isTripClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This trip is closed. Settlement status cannot be modified.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isAdmin) ...[
              const Text(
                'Finalizing settlement will lock all expenses, contributions, and member modifications for this trip.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCompleting ? null : _confirmCompleteSettlement,
                  icon: _isCompleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isCompleting ? 'Finalizing...' : 'Mark as Settled'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Only trip admin can mark settlement as complete',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}