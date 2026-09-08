import 'package:flutter/material.dart';

import '../../models/contribution.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/contribution_service.dart';
import '../../services/members_service.dart';

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
  final MemberService _memberService = MemberService();

  List<Contribution> _contributions = [];
  Map<String, String> _memberNames = {};
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
      List<TripMember> members = [];
      try {
        members = await _memberService.getMembers(widget.trip.id);
      } catch (_) {}

      final names = <String, String>{};
      for (final m in members) {
        names[m.userId] = m.name;
      }

      if (!mounted) return;

      setState(() {
        _contributions = result;
        _memberNames = names;
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
    return '${widget.trip.currency} '
        '${(paise / 100).toStringAsFixed(2)}';
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoString;
    }
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
    final memberName = _memberNames[contribution.memberId] ?? 'Member';
    final dateStr = _formatDate(contribution.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          memberName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${contribution.paymentMethod} • '
          '${contribution.status}'
          '${dateStr.isNotEmpty ? ' • $dateStr' : ''}'
          '${contribution.note?.isNotEmpty == true ? '\n${contribution.note}' : ''}',
        ),
        trailing: Text(
          _formatMoney(contribution.amountPaise),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
        isThreeLine: contribution.note?.isNotEmpty == true || dateStr.isNotEmpty,
      ),
    );
  }
}