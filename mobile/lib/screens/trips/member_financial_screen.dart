import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/member_financial_summary.dart';
import '../../services/member_financial_service.dart';

class MemberFinancialScreen extends StatefulWidget {
  final Trip trip;

  const MemberFinancialScreen({
    super.key,
    required this.trip,
  });

  @override
  State<MemberFinancialScreen> createState() =>
      _MemberFinancialScreenState();
}

class _MemberFinancialScreenState
    extends State<MemberFinancialScreen> {
  final MemberFinancialService _service =
      MemberFinancialService();

  List<MemberFinancialSummary> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await _service.getSummary(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _members = result;
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

  String _money(int paise) {
    return '${widget.trip.currency} '
        '${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Finances'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSummary,
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
                onPressed: _loadSummary,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text('No member financial data'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _members
            .map(_buildMemberCard)
            .toList(),
      ),
    );
  }

  Widget _buildMemberCard(
    MemberFinancialSummary member,
  ) {
    final net = member.netPaise;

    final bool receive = net > 0;
    final bool pay = net < 0;

    final String status;

    if (receive) {
      status = 'Should Receive';
    } else if (pay) {
      status = 'Should Pay';
    } else {
      status = 'Settled';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    member.name.isEmpty
                        ? '?'
                        : member.name[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        member.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _value(
                  'Contributed',
                  _money(member.contributedPaise),
                ),
                _value(
                  'Spent',
                  _money(member.spentPaise),
                ),
                _value(
                  'Net',
                  _money(net.abs()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _value(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}