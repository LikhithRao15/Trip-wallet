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
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;

  bool _isLoading = true;
  String? _error;

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedMemberId != null ||
      _sortOrder != 'newest' ||
      _selectedDateRange != null ||
      _minAmount != null ||
      _maxAmount != null;

  List<Expense> get _filteredExpenses {
    return _expenses.where((expense) {
      if (_selectedDateRange != null) {
        try {
          final dt = DateTime.parse(expense.createdAt).toLocal();
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
          );
          if (dt.isBefore(start) || dt.isAfter(end)) return false;
        } catch (_) {}
      }
      if (_minAmount != null) {
        if ((expense.amountPaise / 100) < _minAmount!) return false;
      }
      if (_maxAmount != null) {
        if ((expense.amountPaise / 100) > _maxAmount!) return false;
      }
      return true;
    }).toList();
  }

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
      _selectedDateRange = null;
      _minAmount = null;
      _maxAmount = null;
    });
    _loadExpenses();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _showAmountRangeDialog() async {
    final minCtrl = TextEditingController(
      text: _minAmount != null ? _minAmount!.toStringAsFixed(0) : '',
    );
    final maxCtrl = TextEditingController(
      text: _maxAmount != null ? _maxAmount!.toStringAsFixed(0) : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Min Amount (${widget.trip.currency})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Max Amount (${widget.trip.currency})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              minCtrl.clear();
              maxCtrl.clear();
              setState(() {
                _minAmount = null;
                _maxAmount = null;
              });
              Navigator.pop(ctx, true);
            },
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () {
              final min = double.tryParse(minCtrl.text.trim());
              final max = double.tryParse(maxCtrl.text.trim());
              setState(() {
                _minAmount = min;
                _maxAmount = max;
              });
              Navigator.pop(ctx, true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
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

          // Date Range Filter Button
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(
              _selectedDateRange == null
                  ? 'Date'
                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
            ),
            onPressed: _pickDateRange,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: _selectedDateRange != null
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // Amount Range Filter Button
          OutlinedButton.icon(
            icon: const Icon(Icons.currency_rupee, size: 16),
            label: Text(
              _minAmount == null && _maxAmount == null
                  ? 'Amount'
                  : '₹${_minAmount?.toStringAsFixed(0) ?? '0'} - ₹${_maxAmount?.toStringAsFixed(0) ?? '∞'}',
            ),
            onPressed: _showAmountRangeDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: (_minAmount != null || _maxAmount != null)
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
            ),
          ),
          const SizedBox(width: 8),

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

    final filtered = _filteredExpenses;

    if (filtered.isEmpty) {
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
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final payerName = _memberNames[expense.paidBy] ?? 'Member';
    final dateStr = _formatDate(expense.createdAt);
    final catColor = getExpenseCategoryColor(expense.category);
    final isCancelled = expense.status == 'CANCELLED';
    final participantCount = expense.splits.length;

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
                  Expanded(
                    child: Text(
                      'Paid by $payerName • $dateStr • $participantCount ${participantCount == 1 ? 'member' : 'members'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expense.splitMode == 'CUSTOM'
                          ? 'Custom'
                          : (expense.splitMode == 'PERCENTAGE'
                              ? 'Pct'
                              : 'Equal'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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