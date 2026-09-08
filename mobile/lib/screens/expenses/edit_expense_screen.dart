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

  final Map<String, TextEditingController> _customAmountControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};

  String _category = 'FOOD';
  String _splitMode = 'EQUAL';

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
    _splitMode = widget.expense.splitMode;

    // Prefill split controllers from existing splits
    for (final split in widget.expense.splits) {
      _customAmountControllers[split.memberId] = TextEditingController(
        text: (split.amountPaise / 100).toStringAsFixed(2),
      );
      if (widget.expense.amountPaise > 0) {
        final pct = (split.amountPaise / widget.expense.amountPaise) * 100;
        _percentageControllers[split.memberId] = TextEditingController(
          text: pct.toStringAsFixed(2),
        );
      }
    }

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

    final total = rupees * 100 + paise;
    if (total <= 0) return null;

    return total;
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

    final total = rupees * 100 + paise;
    if (total < 0) return null;

    return total;
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
    for (final uid in _selectedMembers) {
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
    for (final uid in _selectedMembers) {
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
    if (_selectedMembers.isEmpty) return false;

    if (_splitMode == 'EQUAL') {
      return true;
    } else if (_splitMode == 'CUSTOM') {
      for (final uid in _selectedMembers) {
        final ctrl = _customAmountControllers[uid];
        if (ctrl == null) return false;
        final p = _parseCustomInputToPaise(ctrl.text);
        if (p == null || p <= 0) return false;
      }
      return _calculateAllocatedCustomPaise() == totalExpensePaise;
    } else if (_splitMode == 'PERCENTAGE') {
      for (final uid in _selectedMembers) {
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

    final amountPaise = _parseAmountToPaise(_amountController.text);
    if (amountPaise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
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

      splitsPayload = _selectedMembers.map((uid) {
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

      splitsPayload = _selectedMembers.map((uid) {
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
        splitMode: _splitMode,
        splits: splitsPayload,
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
  Widget build(BuildContext context) {
    final amountPaise = _parseAmountToPaise(_amountController.text);
    final canSave = !_saving && _isSplitValid(amountPaise);

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
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${widget.trip.currency} ',
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
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedMembers.length} selected',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Card(
                    child: Column(
                      children: _members.map((member) {
                        final selected = _selectedMembers.contains(member.userId);

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
                                    _selectedMembers.add(member.userId);
                                  } else {
                                    _selectedMembers.remove(member.userId);
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

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: canSave ? _save : null,
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
