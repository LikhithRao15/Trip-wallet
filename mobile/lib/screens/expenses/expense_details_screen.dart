import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/trip.dart';
import 'edit_expense_screen.dart';
import '../../services/expense_service.dart';
import '../../models/trip_member.dart';
import '../../services/members_service.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Trip trip;
  final String expenseId;

  const ExpenseDetailsScreen({
    super.key,
    required this.trip,
    required this.expenseId,
  });

  @override
  State<ExpenseDetailsScreen> createState() =>
      _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState
    extends State<ExpenseDetailsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();

  Expense? _expense;
  List<TripMember> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final expense = await _expenseService.getExpense(
      tripId: widget.trip.id,
      expenseId: widget.expenseId,
    );

    final members = await _memberService.getMembers(
      widget.trip.id,
    );

    if (!mounted) return;

    setState(() {
      _expense = expense;
      _members = members;
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

  Future<void> _cancelExpense() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Expense?'),
      content: const Text(
        'The expense amount will be returned to the common wallet. '
        'The expense will remain in history as cancelled.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancel Expense'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await _expenseService.cancelExpense(
      widget.trip.id,
      widget.expenseId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense cancelled successfully'),
      ),
    );

    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
}
 
  Future<void> _editExpense() async {
  final expense = _expense;

  if (expense == null) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditExpenseScreen(
        trip: widget.trip,
        expense: expense,
      ),
    ),
  );

  if (!mounted) return;

  if (result == true) {
    await _loadExpense();
  }
}

  String _getPayerName(String userId) {
  final member = _members.cast<TripMember?>().firstWhere(
        (member) => member?.userId == userId,
        orElse: () => null,
      );

  return member?.name ?? 'Unknown member';
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
        title: const Text('Expense Details'),
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
                onPressed: _loadExpense,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final expense = _expense!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  _formatMoney(expense.amountPaise),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(expense.status),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              _infoTile(
                Icons.category_outlined,
                'Category',
                expense.category,
              ),
              _infoTile(
                Icons.description_outlined,
                'Description',
                expense.description ?? 'No description',
              ),
              _infoTile(
                Icons.person_outline,
                'Paid by',
                _getPayerName(expense.paidBy),
              ),
              _infoTile(
                Icons.calendar_today_outlined,
                'Created',
                _formatDate(expense.createdAt),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Split Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${expense.splits.length} participants',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                ...expense.splits.map((split) {
                  final name = _getPayerName(split.memberId);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(name),
                    trailing: Text(
                      _formatMoney(split.amountPaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This expense was paid from the common trip wallet.',
                  ),
                ),
              ],
            ),
          ),
        ),

        if (expense.status == 'CONFIRMED' && widget.trip.status != 'CLOSED') ...[
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editExpense,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelExpense,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}