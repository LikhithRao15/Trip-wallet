import 'package:flutter/material.dart';

import '../../core/constants/expense_categories.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/expense_service.dart';
import '../../services/members_service.dart';
import 'expense_details_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  final Trip trip;

  const ExpenseHistoryScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();

  final TextEditingController _searchController = TextEditingController();

  List<Expense> _expenses = [];
  List<TripMember> _members = [];
  Map<String, String> _memberNames = {};

  String? _selectedCategory;
  String? _selectedMemberId;
  String _sortOrder = 'newest';

  bool _isLoading = true;
  String? _error;

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedMemberId != null ||
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

    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final expenses = await _expenseService.getExpenses(
        widget.trip.id,
        category: _selectedCategory,
        memberId: _selectedMemberId,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        sort: _sortOrder,
      );

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
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
      _selectedCategory = null;
      _selectedMemberId = null;
      _sortOrder = 'newest';
    });
    _loadExpenses();
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
        title: const Text('Expense History'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadExpenses,
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
          hintText: 'Search by description or category...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadExpenses();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (_) => _loadExpenses(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Category Filter Dropdown
          DropdownButton<String?>(
            value: _selectedCategory,
            hint: const Text('Category: All'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...kExpenseCategories.map(
                (cat) => DropdownMenuItem<String?>(
                  value: cat,
                  child: Text(cat),
                ),
              ),
            ],
            onChanged: (cat) {
              setState(() {
                _selectedCategory = cat;
              });
              _loadExpenses();
            },
          ),
          const SizedBox(width: 12),

          // Member Filter Dropdown
          DropdownButton<String?>(
            value: _selectedMemberId,
            hint: const Text('Member: All'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Members'),
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
              _loadExpenses();
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
              _loadExpenses();
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
                onPressed: _loadExpenses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _hasActiveFilters
                    ? 'No expenses match your filters'
                    : 'No expenses yet',
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
      onRefresh: _loadExpenses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(_expenses[index]);
        },
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final payerName = _memberNames[expense.paidBy] ?? 'Member';
    final dateStr = _formatDate(expense.createdAt);
    final catColor = getExpenseCategoryColor(expense.category);
    final isCancelled = expense.status == 'CANCELLED';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: catColor.withValues(alpha: 0.15),
          child: Icon(
            getExpenseCategoryIcon(expense.category),
            color: catColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              _formatMoney(expense.amountPaise),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCancelled ? Colors.grey : null,
                decoration:
                    isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expense.description != null &&
                  expense.description!.isNotEmpty)
                Text(
                  expense.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Paid by $payerName • $dateStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expense.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseDetailsScreen(
                trip: widget.trip,
                expenseId: expense.id,
              ),
            ),
          );

          if (mounted) {
            _loadExpenses();
          }
        },
      ),
    );
  }
}