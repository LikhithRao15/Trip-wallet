import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/expense_service.dart';
import '../../services/members_service.dart';

class PayExpenseScreen extends StatefulWidget {
  final Trip trip;

  const PayExpenseScreen({
    super.key,
    required this.trip,
  });

  @override
  State<PayExpenseScreen> createState() =>
      _PayExpenseScreenState();
}

class _PayExpenseScreenState extends State<PayExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final MemberService _memberService = MemberService();
  final ExpenseService _expenseService = ExpenseService();

  List<TripMember> _members = [];
  final Set<String> _selectedMemberIds = {};

  bool _loadingMembers = true;
  bool _submitting = false;
  String? _error;

  String _category = 'FOOD';

  final List<String> _categories = [
    'FOOD',
    'TRAVEL',
    'HOTEL',
    'SHOPPING',
    'TICKETS',
    'ENTERTAINMENT',
    'MEDICAL',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _error = null;
    });

    try {
      final members =
          await _memberService.getMembers(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMembers = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? _parseAmountToPaise(String value) {
    final text = value.trim();

    if (text.isEmpty) return null;

    final parts = text.split('.');

    if (parts.length > 2) return null;

    final rupees = int.tryParse(parts[0]);

    if (rupees == null || rupees < 0) {
      return null;
    }

    int paise = 0;

    if (parts.length == 2) {
      final decimal = parts[1];

      if (decimal.length > 2) {
        return null;
      }

      final padded = decimal.padRight(2, '0');
      paise = int.tryParse(padded) ?? 0;
    }

    final amountPaise = rupees * 100 + paise;

    if (amountPaise <= 0) {
      return null;
    }

    return amountPaise;
  }


  int _selectedTotal() {
    return _selectedMemberIds.length;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one participant',
          ),
        ),
      );
      return;
    }

    final amountPaise =
        _parseAmountToPaise(_amountController.text);

    if (amountPaise == null) {
      return;
    }

   

    setState(() {
      _submitting = true;
    });

    try {
      await _expenseService.addExpense(
        tripId: widget.trip.id,
        amountPaise: amountPaise,
        category: _category,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        memberIds: _selectedMemberIds.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense paid successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Expense'),
      ),
      body: _loadingMembers
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? _buildError()
              : _members.isEmpty
                  ? _buildEmpty()
                  : _buildForm(),
    );
  }

  Widget _buildForm() {
    final amountPaise =
        _parseAmountToPaise(_amountController.text);

    final selectedCount = _selectedTotal();

    int? eachShare;

    if (amountPaise != null && selectedCount > 0) {
      eachShare = amountPaise ~/ selectedCount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay from Trip Wallet',
              style:
                  Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'Select everyone who should share this expense.',
              style:
                  Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Expense Amount',
                prefixText:
                    '${widget.trip.currency} ',
                prefixIcon:
                    const Icon(Icons.currency_rupee),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter an amount';
                }

                if (_parseAmountToPaise(value) == null) {
                  return 'Enter a valid amount';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon:
                    Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.replaceAll('_', ' '),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Example: Lunch at restaurant',
                prefixIcon:
                    Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Card(
              child: Column(
                children: _members.map((member) {
                  final selected =
                      _selectedMemberIds.contains(
                    member.id,
                  );

                  return CheckboxListTile(
                    value: selected,
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    secondary: CircleAvatar(
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedMemberIds
                              .add(member.id);
                        } else {
                          _selectedMemberIds
                              .remove(member.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            if (amountPaise != null &&
                selectedCount > 0) ...[
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Split Summary',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total: ${widget.trip.currency} '
                        '${(amountPaise / 100).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Participants: $selectedCount',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Approx. each: ${widget.trip.currency} '
                        '${((eachShare ?? 0) / 100).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.account_balance_wallet,
                      ),
                label: Text(
                  _submitting
                      ? 'Processing...'
                      : 'Pay Expense',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
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
            OutlinedButton.icon(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No members found.\nAdd members to the trip first.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}