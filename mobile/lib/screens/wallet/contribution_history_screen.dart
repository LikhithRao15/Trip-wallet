import 'package:flutter/material.dart';

import '../../models/contribution.dart';
import '../../models/trip.dart';
import '../../services/contribution_service.dart';

class ContributionHistoryScreen extends StatefulWidget {
  final Trip trip;

  const ContributionHistoryScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ContributionHistoryScreen> createState() =>
      _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState
    extends State<ContributionHistoryScreen> {
  final ContributionService _service = ContributionService();

  List<Contribution> _contributions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await _service.getContributions(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _contributions = result;
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
    return '${widget.trip.currency} '
        '${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution History'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadContributions,
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
                onPressed: _loadContributions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contributions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadContributions,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No contributions yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contributions.length,
        itemBuilder: (context, index) {
          return _buildContributionCard(
            _contributions[index],
          );
        },
      ),
    );
  }

  Widget _buildContributionCard(
    Contribution contribution,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.arrow_downward),
        ),
        title: Text(
          _formatMoney(contribution.amountPaise),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${contribution.paymentMethod} • '
          '${contribution.status}'
          '${contribution.note?.isNotEmpty == true ? '\n${contribution.note}' : ''}',
        ),
        isThreeLine: contribution.note?.isNotEmpty == true,
      ),
    );
  }
}