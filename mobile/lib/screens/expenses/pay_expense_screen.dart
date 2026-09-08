import 'package:flutter/material.dart';

import '../../core/constants/expense_categories.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/expense_service.dart';
import '../../services/members_service.dart';

class PayExpenseScreen extends StatefulWidget {
  final Trip trip;

  const PayExpenseScreen({super.key, required this.trip});

  @override
  State<PayExpenseScreen> createState() => _PayExpenseScreenState();
}

class _PayExpenseScreenState extends State<PayExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final MemberService _memberService = MemberService();
  final ExpenseService _expenseService = ExpenseService();

  List<TripMember> _members = [];
  final Set<String> _selectedMemberIds = {};

  // Custom and Percentage controllers per user ID
  final Map<String, TextEditingController> _customAmountControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};

  bool _loadingMembers = true;
  bool _submitting = false;
  String? _error;

  String _category = 'FOOD';
  String _splitMode = 'EQUAL'; // 'EQUAL', 'CUSTOM', 'PERCENTAGE'

  List<String> get _categories => kExpenseCategories;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCustomController(String userId) {
    return _customAmountControllers.putIfAbsent(
      userId,
      () => TextEditingController(),
    );
  }

  TextEditingController _getPercentageController(String userId) {
    return _percentageControllers.putIfAbsent(
      userId,
      () => TextEditingController(),
    );
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _error = null;
    });

    try {
      final members = await _memberService.getMembers(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _members = members.where((m) => m.status == 'ACTIVE').toList();
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
    if (rupees == null || rupees < 0) return null;

    int paise = 0;
    if (parts.length == 2) {
      final decimal = parts[1];
      if (decimal.length > 2) return null;
      final padded = decimal.padRight(2, '0');
      paise = int.tryParse(padded) ?? 0;
    }

    final amountPaise = rupees * 100 + paise;
    if (amountPaise <= 0) return null;

    return amountPaise;
  }

  int? _parseCustomInputToPaise(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final parts = text.split('.');
    if (parts.length > 2) return null;

    final rupees = int.tryParse(parts[0]);
    if (rupees == null || rupees < 0) return null;

    int paise = 0;
    if (parts.length == 2) {
      final decimal = parts[1];
      if (decimal.length > 2) return null;
      final padded = decimal.padRight(2, '0');
      paise = int.tryParse(padded) ?? 0;
    }

    final amountPaise = rupees * 100 + paise;
    if (amountPaise < 0) return null;

    return amountPaise;
  }

  double? _parsePercentage(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final val = double.tryParse(text);
    if (val == null || val < 0 || val > 100) return null;
    return val;
  }

  int _calculateAllocatedCustomPaise() {
    int total = 0;
    for (final uid in _selectedMemberIds) {
      final ctrl = _customAmountControllers[uid];
      if (ctrl != null) {
        final parsed = _parseCustomInputToPaise(ctrl.text);
        if (parsed != null) {
          total += parsed;
        }
      }
    }
    return total;
  }

  double _calculateAllocatedPercentage() {
    double total = 0.0;
    for (final uid in _selectedMemberIds) {
      final ctrl = _percentageControllers[uid];
      if (ctrl != null) {
        final parsed = _parsePercentage(ctrl.text);
        if (parsed != null) {
          total += parsed;
        }
      }
    }
    return total;
  }

  bool _isSplitValid(int? totalExpensePaise) {
    if (totalExpensePaise == null || totalExpensePaise <= 0) return false;
    if (_selectedMemberIds.isEmpty) return false;

    if (_splitMode == 'EQUAL') {
      return true;
    } else if (_splitMode == 'CUSTOM') {
      // Check each selected member has an entered amount > 0
      for (final uid in _selectedMemberIds) {
        final ctrl = _customAmountControllers[uid];
        if (ctrl == null) return false;
        final p = _parseCustomInputToPaise(ctrl.text);
        if (p == null || p <= 0) return false;
      }
      return _calculateAllocatedCustomPaise() == totalExpensePaise;
    } else if (_splitMode == 'PERCENTAGE') {
      // Check each selected member has an entered percentage > 0
      for (final uid in _selectedMemberIds) {
        final ctrl = _percentageControllers[uid];
        if (ctrl == null) return false;
        final p = _parsePercentage(ctrl.text);
        if (p == null || p <= 0) return false;
      }
      final totalPct = _calculateAllocatedPercentage();
      return (totalPct - 100.0).abs() < 0.005;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    final amountPaise = _parseAmountToPaise(_amountController.text);
    if (amountPaise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid expense amount')),
      );
      return;
    }

    List<Map<String, dynamic>>? splitsPayload;

    if (_splitMode == 'CUSTOM') {
      final allocated = _calculateAllocatedCustomPaise();
      if (allocated != amountPaise) {
        final diff = (amountPaise - allocated).abs();
        final diffStr = (diff / 100).toStringAsFixed(2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allocated < amountPaise
                  ? 'Custom split is short by ${widget.trip.currency} $diffStr'
                  : 'Custom split exceeds total by ${widget.trip.currency} $diffStr',
            ),
          ),
        );
        return;
      }

      splitsPayload = _selectedMemberIds.map((uid) {
        final paise = _parseCustomInputToPaise(
              _customAmountControllers[uid]?.text ?? '',
            ) ??
            0;
        return {
          'member_id': uid,
          'amount_paise': paise,
        };
      }).toList();
    } else if (_splitMode == 'PERCENTAGE') {
      final totalPct = _calculateAllocatedPercentage();
      if ((totalPct - 100.0).abs() >= 0.005) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Percentages must sum to exactly 100% (currently ${totalPct.toStringAsFixed(2)}%)',
            ),
          ),
        );
        return;
      }

      splitsPayload = _selectedMemberIds.map((uid) {
        final pct = _parsePercentage(
              _percentageControllers[uid]?.text ?? '',
            ) ??
            0.0;
        return {
          'member_id': uid,
          'percentage': pct,
        };
      }).toList();
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _expenseService.addExpense(
        tripId: widget.trip.id,
        amountPaise: amountPaise,
        category: _category,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        memberIds: _selectedMemberIds.toList(),
        splitMode: _splitMode,
        splits: splitsPayload,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense paid successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Expense')),
      body: _loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _members.isEmpty
          ? _buildEmpty()
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final amountPaise = _parseAmountToPaise(_amountController.text);
    final selectedCount = _selectedMemberIds.length;
    final canSubmit = !_submitting && _isSplitValid(amountPaise);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay from Trip Wallet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select participants and configure how this expense is shared.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Expense Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Expense Amount',
                prefixText: '${widget.trip.currency} ',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an amount';
                }
                if (_parseAmountToPaise(value) == null) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.replaceAll('_', ' ')),
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

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Example: Lunch at restaurant',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            // Split Mode Selector
            const Text(
              'Split Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'EQUAL',
                    label: Text('Equal'),
                    icon: Icon(Icons.pie_chart_outline),
                  ),
                  ButtonSegment<String>(
                    value: 'CUSTOM',
                    label: Text('Custom'),
                    icon: Icon(Icons.tune),
                  ),
                  ButtonSegment<String>(
                    value: 'PERCENTAGE',
                    label: Text('Percentage'),
                    icon: Icon(Icons.percent),
                  ),
                ],
                selected: {_splitMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _splitMode = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 28),

            // Participants Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Member list with inputs for Custom and Percentage
            Card(
              child: Column(
                children: _members.map((member) {
                  final selected = _selectedMemberIds.contains(member.userId);

                  return Column(
                    children: [
                      CheckboxListTile(
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
                              _selectedMemberIds.add(member.userId);
                            } else {
                              _selectedMemberIds.remove(member.userId);
                            }
                          });
                        },
                      ),
                      if (selected && _splitMode == 'CUSTOM')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 48),
                              Expanded(
                                child: TextField(
                                  controller: _getCustomController(member.userId),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Share Amount',
                                    prefixText: '${widget.trip.currency} ',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (selected && _splitMode == 'PERCENTAGE')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 48),
                              Expanded(
                                child: TextField(
                                  controller:
                                      _getPercentageController(member.userId),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Percentage Share',
                                    suffixText: '%',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (amountPaise != null) ...[
                                const SizedBox(width: 12),
                                Builder(builder: (context) {
                                  final pct = _parsePercentage(
                                        _percentageControllers[member.userId]
                                                ?.text ??
                                            '',
                                      ) ??
                                      0.0;
                                  final approxPaise =
                                      (amountPaise * (pct / 100)).round();
                                  return Text(
                                    '≈ ${widget.trip.currency} ${(approxPaise / 100).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Live Split Summary Card
            if (amountPaise != null && selectedCount > 0) ...[
              const SizedBox(height: 20),
              _buildSplitSummaryCard(amountPaise, selectedCount),
            ],

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet),
                label: Text(_submitting ? 'Processing...' : 'Pay Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSummaryCard(int amountPaise, int selectedCount) {
    if (_splitMode == 'EQUAL') {
      final eachShare = amountPaise ~/ selectedCount;
      final remainder = amountPaise % selectedCount;

      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Equal Split Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ${widget.trip.currency} ${(amountPaise / 100).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 4),
              Text('Participants: $selectedCount'),
              const SizedBox(height: 4),
              Text(
                'Each pays: ${widget.trip.currency} ${(eachShare / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (remainder > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Note: $remainder paise remainder distributed deterministically to first $remainder participant(s).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (_splitMode == 'CUSTOM') {
      final allocated = _calculateAllocatedCustomPaise();
      final diff = amountPaise - allocated;
      final isMatch = diff == 0 && _selectedMemberIds.every((uid) {
        final p = _parseCustomInputToPaise(_customAmountControllers[uid]?.text ?? '');
        return p != null && p > 0;
      });

      return Card(
        color: isMatch ? Colors.green.shade50 : (diff > 0 ? Colors.amber.shade50 : Colors.red.shade50),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isMatch ? Icons.check_circle_outline : Icons.info_outline,
                    size: 20,
                    color: isMatch ? Colors.green : (diff > 0 ? Colors.amber.shade900 : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Custom Allocation Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Expense Total: ${widget.trip.currency} ${(amountPaise / 100).toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Text('Total Allocated: ${widget.trip.currency} ${(allocated / 100).toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              if (diff == 0)
                const Text(
                  '✓ Exact match: Total matches expense amount',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                )
              else if (diff > 0)
                Text(
                  'Remaining to allocate: ${widget.trip.currency} ${(diff / 100).toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'Over-allocated by: ${widget.trip.currency} ${((-diff) / 100).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      );
    } else {
      final allocatedPct = _calculateAllocatedPercentage();
      final diffPct = 100.0 - allocatedPct;
      final isMatch = diffPct.abs() < 0.005 && _selectedMemberIds.every((uid) {
        final p = _parsePercentage(_percentageControllers[uid]?.text ?? '');
        return p != null && p > 0;
      });

      return Card(
        color: isMatch ? Colors.green.shade50 : (diffPct > 0 ? Colors.amber.shade50 : Colors.red.shade50),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isMatch ? Icons.check_circle_outline : Icons.info_outline,
                    size: 20,
                    color: isMatch ? Colors.green : (diffPct > 0 ? Colors.amber.shade900 : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Percentage Allocation Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Allocated: ${allocatedPct.toStringAsFixed(2)}% of 100.00%'),
              const SizedBox(height: 4),
              if (isMatch)
                const Text(
                  '✓ Exact match: 100.00% allocated',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                )
              else if (diffPct > 0)
                Text(
                  'Remaining: ${diffPct.toStringAsFixed(2)}%',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'Over-allocated by: ${(-diffPct).toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
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
