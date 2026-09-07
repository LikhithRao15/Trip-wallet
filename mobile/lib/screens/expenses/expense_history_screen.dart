import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../services/expense_service.dart';
import 'expense_details_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  final Trip trip;

  const ExpenseHistoryScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState
    extends State<ExpenseHistoryScreen> {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final expenses =
          await _expenseService.getExpenses(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
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
        title: const Text('Expense History'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadExpenses,
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
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No expenses yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_categoryIcon(expense.category)),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          expense.description?.isNotEmpty == true
              ? expense.description!
              : 'No description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatMoney(expense.amountPaise),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
      case 'transport':
        return Icons.directions_car;
      case 'stay':
      case 'hotel':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      case 'tickets':
      case 'entertainment':
        return Icons.confirmation_num;
      default:
        return Icons.receipt_long;
    }
  }
}