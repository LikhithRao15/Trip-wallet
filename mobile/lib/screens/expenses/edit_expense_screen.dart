import 'package:flutter/material.dart';

import '../../core/constants/expense_categories.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/expense_service.dart';
import '../../services/members_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Trip trip;
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.trip,
    required this.expense,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _membersService = MemberService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  List<TripMember> _members = [];
  final Set<String> _selectedMembers = {};

  String _category = 'FOOD';

  bool _loadingMembers = true;
  bool _saving = false;
  String? _error;

  List<String> get _categories => kExpenseCategories;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: (widget.expense.amountPaise / 100).toStringAsFixed(2),
    );

    _descriptionController = TextEditingController(
      text: widget.expense.description ?? '',
    );

    final upperCategory = widget.expense.category.toUpperCase();
    _category = _categories.contains(upperCategory) ? upperCategory : 'OTHER';

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _membersService.getMembers(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _members = members;
        _selectedMembers.addAll(
          widget.expense.splits.map((split) => split.memberId),
        );
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loadingMembers = false;
      });
    }
  }

  int _parseAmountToPaise() {
    final text = _amountController.text.trim();

    if (text.isEmpty) {
      throw Exception('Enter a valid amount');
    }

    final parts = text.split('.');

    if (parts.length > 2) {
      throw Exception('Enter a valid amount');
    }

    final rupees = int.tryParse(parts[0]);

    if (rupees == null || rupees < 0) {
      throw Exception('Enter a valid amount');
    }

    int paise = 0;

    if (parts.length == 2) {
      final decimal = parts[1];

      if (decimal.length > 2) {
        throw Exception('Maximum 2 decimal places allowed');
      }

      final padded = decimal.padRight(2, '0');
      paise = int.tryParse(padded) ?? 0;
    }

    final total = rupees * 100 + paise;

    if (total <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    return total;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    int amountPaise;

    try {
      amountPaise = _parseAmountToPaise();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _expenseService.updateExpense(
        tripId: widget.trip.id,
        expenseId: widget.expense.id,
        amountPaise: amountPaise,
        category: _category,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memberIds: _selectedMembers.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: _loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${widget.trip.currency} ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');

                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Split Between',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  ..._members.map((member) {
                    final selected = _selectedMembers.contains(member.userId);

                    return CheckboxListTile(
                      value: selected,
                      title: Text(member.name),
                      subtitle: Text(member.email),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(member.userId);
                          } else {
                            _selectedMembers.remove(member.userId);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
