import 'package:flutter/material.dart';

import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../services/contribution_service.dart';
import '../../services/members_service.dart';

class AddContributionScreen extends StatefulWidget {
  final Trip trip;

  const AddContributionScreen({super.key, required this.trip});

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final MemberService _memberService = MemberService();
  final ContributionService _contributionService = ContributionService();

  List<TripMember> _members = [];
  TripMember? _selectedMember;

  String _paymentMethod = 'CASH';
  bool _loadingMembers = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
        _members = members;
        _loadingMembers = false;

        if (members.isNotEmpty) {
          _selectedMember = members.first;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMembers = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMember == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a member')));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      return;
    }

    // Convert rupees to paise without floating-point
    // arithmetic for the value sent to the backend.
    final amountText = _amountController.text.trim();
    final parts = amountText.split('.');

    final rupees = int.tryParse(parts[0]) ?? 0;

    int paise = 0;

    if (parts.length == 2) {
      final decimal = parts[1].padRight(2, '0');

      if (decimal.length > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount can have maximum 2 decimal places'),
          ),
        );
        return;
      }

      paise = int.tryParse(decimal) ?? 0;
    }

    final amountPaise = rupees * 100 + paise;

    setState(() {
      _submitting = true;
    });

    try {
      await _contributionService.addContribution(
        tripId: widget.trip.id,
        memberId: _selectedMember!.id,
        amountPaise: amountPaise,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution added successfully')),
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
      appBar: AppBar(title: const Text('Add Contribution')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add money to the trip wallet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              'Record how much a member contributed to the common wallet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 28),

            DropdownButtonFormField<TripMember>(
              initialValue: _selectedMember,
              decoration: const InputDecoration(
                labelText: 'Member',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: _members.map((member) {
                return DropdownMenuItem<TripMember>(
                  value: member,
                  child: Text('${member.name} (${member.email})'),
                );
              }).toList(),
              onChanged: (member) {
                setState(() {
                  _selectedMember = member;
                });
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.trip.currency} ',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an amount';
                }

                final amount = double.tryParse(value.trim());

                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }

                if (value.contains('.')) {
                  final decimals = value.split('.')[1];

                  if (decimals.length > 2) {
                    return 'Maximum 2 decimal places';
                  }
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(
                  value: 'BANK_TRANSFER',
                  child: Text('Bank Transfer'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _paymentMethod = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Example: Paid ₹500 for trip fund',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_submitting ? 'Adding...' : 'Add Contribution'),
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
