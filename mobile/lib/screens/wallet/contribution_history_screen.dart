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

  final TextEditingController _searchController = TextEditingController();

  List<Contribution> _contributions = [];
  List<TripMember> _members = [];
  Map<String, String> _memberNames = {};

  String? _selectedMemberId;
  String? _selectedPaymentMethod;
  String _sortOrder = 'newest';

  bool _isLoading = true;
  String? _error;

  final List<String> _paymentMethods = [
    'UPI',
    'CASH',
    'CARD',
    'NET_BANKING',
    'OTHER',
  ];

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedMemberId != null ||
      _selectedPaymentMethod != null ||
      _sortOrder != 'newest';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final members = await _memberService.getMembers(widget.trip.id);
      final names = <String, String>{};
      for (final m in members) {
        names[m.userId] = m.name;
        names[m.id] = m.name;
      }
      if (mounted) {
        setState(() {
          _members = members;
          _memberNames = names;
        });
      }
    } catch (_) {}

    await _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getContributions(
        widget.trip.id,
        memberId: _selectedMemberId,
        paymentMethod: _selectedPaymentMethod,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        sort: _sortOrder,
      );

      if (!mounted) return;

      setState(() {
        _contributions = result;
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedMemberId = null;
      _selectedPaymentMethod = null;
      _sortOrder = 'newest';
    });
    _loadContributions();
  }

  String _formatMoney(int paise) {
    return '${widget.trip.currency} ${(paise / 100).toStringAsFixed(2)}';
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
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by note or description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadContributions();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (_) => _loadContributions(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Member Filter Dropdown
          DropdownButton<String?>(
            value: _selectedMemberId,
            hint: const Text('Contributor: All'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Contributors'),
              ),
              ..._members.map(
                (m) => DropdownMenuItem<String?>(
                  value: m.userId,
                  child: Text(m.name),
                ),
              ),
            ],
            onChanged: (memberId) {
              setState(() {
                _selectedMemberId = memberId;
              });
              _loadContributions();
            },
          ),
          const SizedBox(width: 12),

          // Payment Method Filter Dropdown
          DropdownButton<String?>(
            value: _selectedPaymentMethod,
            hint: const Text('Method: All'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Methods'),
              ),
              ..._paymentMethods.map(
                (method) => DropdownMenuItem<String?>(
                  value: method,
                  child: Text(method),
                ),
              ),
            ],
            onChanged: (method) {
              setState(() {
                _selectedPaymentMethod = method;
              });
              _loadContributions();
            },
          ),
          const SizedBox(width: 12),

          // Sort Toggle Button
          OutlinedButton.icon(
            icon: Icon(
              _sortOrder == 'newest'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 16,
            ),
            label: Text(_sortOrder == 'newest' ? 'Newest' : 'Oldest'),
            onPressed: () {
              setState(() {
                _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
              });
              _loadContributions();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear Filters'),
              onPressed: _clearFilters,
            ),
          ],
        ],
      ),
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
              Text(_error!, textAlign: TextAlign.center),
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
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _hasActiveFilters
                    ? 'No contributions match your filters'
                    : 'No contributions yet',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
            ],
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
          return _buildContributionCard(_contributions[index]);
        },
      ),
    );
  }

  Widget _buildContributionCard(Contribution contribution) {
    final memberName = _memberNames[contribution.memberId] ?? 'Member';
    final dateStr = _formatDate(contribution.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(
                memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatMoney(contribution.amountPaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          contribution.paymentMethod,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          contribution.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (contribution.note != null &&
                      contribution.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      contribution.note!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}