import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/settlement.dart';
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

  SettlementResult? _settlement;
  bool _isLoading = true;
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
      final result =
          await _settlementService.getSettlement(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _settlement = result;
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
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
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
          _buildWalletCard(settlement),
          const SizedBox(height: 24),

          const Text(
            'Member Balances',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (settlement.members.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No members found'),
                ),
              ),
            )
          else
            ...settlement.members.map(_buildMemberCard),

          const SizedBox(height: 24),

          const Text(
            'Suggested Transfers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (settlement.transfers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No transfers required'),
                ),
              ),
            )
          else
            ...settlement.transfers.map(
              (transfer) => _buildTransferCard(
                transfer,
                settlement.members,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(SettlementResult settlement) {
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
              'Remaining Wallet Balance',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMoney(settlement.walletBalancePaise),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${settlement.members.length} members',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(SettlementMember member) {
    IconData icon;
    String title;
    String amount;

    if (member.position == 'RECEIVE') {
      icon = Icons.arrow_downward;
      title = 'Should Receive';
      amount = _formatMoney(member.netPaise);
    } else if (member.position == 'PAY') {
      icon = Icons.arrow_upward;
      title = 'Should Pay';
      amount = _formatMoney(member.netPaise.abs());
    } else {
      icon = Icons.check_circle_outline;
      title = 'Settled';
      amount = _formatMoney(0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          member.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(title),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransferCard(
    SettlementTransfer transfer,
    List<SettlementMember> members,
  ) {
    String getName(String id) {
      final member = members.where(
        (item) => item.memberId == id,
      );

      if (member.isEmpty) {
        return 'Unknown member';
      }

      return member.first.name;
    }

    final fromName = getName(transfer.fromMemberId);
    final toName = getName(transfer.toMemberId);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.swap_horiz),
        ),
        title: Text(
          '$fromName → $toName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Suggested settlement transfer'),
        trailing: Text(
          _formatMoney(transfer.amountPaise),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}