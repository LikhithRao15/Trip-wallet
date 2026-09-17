import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/network_info.dart';
import '../../models/trip.dart';
import '../../services/contribution_service.dart';
import '../../services/members_service.dart';

class MemberContributionFlowScreen extends StatefulWidget {
  final Trip trip;

  const MemberContributionFlowScreen({
    super.key,
    required this.trip,
  });

  @override
  State<MemberContributionFlowScreen> createState() =>
      _MemberContributionFlowScreenState();
}

class _MemberContributionFlowScreenState
    extends State<MemberContributionFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  final ContributionService _contributionService = ContributionService();
  final MemberService _memberService = MemberService();

  bool _isSubmitting = false;
  String _paymentMethod = 'UPI';
  String _adminName = 'Trip Admin';
  String? _adminUpiId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdminDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminDetails() async {
    try {
      final members = await _memberService.getMembers(widget.trip.id);
      for (final m in members) {
        if (m.userId == widget.trip.adminId || m.role == 'ADMIN') {
          if (mounted) {
            setState(() {
              _adminName = m.name;
              _adminUpiId = widget.trip.adminUpiId;
            });
          }
          break;
        }
      }
    } catch (_) {
      // Non-critical fallback
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitContribution() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!mounted) return;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection required to submit contribution.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    final amountParsed = double.tryParse(amountText);
    if (amountParsed == null || amountParsed <= 0) {
      setState(() => _error = 'Please enter a valid contribution amount');
      return;
    }

    final amountPaise = (amountParsed * 100).round();
    final ref = _referenceController.text.trim();
    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _contributionService.submitMemberContribution(
        tripId: widget.trip.id,
        amountPaise: amountPaise,
        paymentReference: ref,
        paymentMethod: _paymentMethod,
        note: note,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.hourglass_top, color: Colors.amber, size: 48),
          title: const Text('Contribution Submitted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your contribution of ${widget.trip.currency} ${amountParsed.toStringAsFixed(2)} has been recorded as PENDING.',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                'Once the trip admin verifies your payment in their bank/UPI app, it will be marked CONFIRMED and credited to the trip accounting balance.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final upiId = _adminUpiId ?? widget.trip.adminUpiId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contribution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Direct Peer-to-Peer Transfer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trip Wallet does not hold or custody your funds. Please transfer money directly to the trip admin via UPI or bank transfer and submit the transaction reference number below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: Amount
              const Text(
                '1. Enter Contribution Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (${widget.trip.currency})',
                  prefixText: '${widget.trip.currency} ',
                  hintText: 'e.g. 2500',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final p = double.tryParse(val.trim());
                  if (p == null || p <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Step 2: Payee Information Card
              const Text(
                '2. Pay Directly to Trip Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Payee: $_adminName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (upiId != null && upiId.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'UPI ID: $upiId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'Copy UPI ID',
                              onPressed: () => _copyToClipboard(upiId, 'UPI ID'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Ask $_adminName for their UPI ID / QR code or bank account details to complete the transfer.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 3: Payment Details
              const Text(
                '3. Confirm Your Transfer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method Used',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay, PhonePe, Paytm, etc.)')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer (NEFT / IMPS)')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash Given to Admin')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'UTR / Transaction Reference ID *',
                  hintText: 'e.g. 12-digit UPI UTR or bank reference',
                  border: OutlineInputBorder(),
                  helperText: 'Enables the trip admin to match the deposit with their bank statement.',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the transaction reference / UTR ID';
                  }
                  if (val.trim().length < 3) {
                    return 'Reference ID is too short';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Optional Note',
                  hintText: 'e.g. Paid for villa advance',
                  border: OutlineInputBorder(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitContribution,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'I Have Paid — Submit for Verification',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
