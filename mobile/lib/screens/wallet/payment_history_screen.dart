import 'package:flutter/material.dart';

import '../../core/network/network_info.dart';
import '../../models/payment_order.dart';
import '../../models/trip.dart';
import '../../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Trip trip;

  const PaymentHistoryScreen({super.key, required this.trip});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  List<PaymentHistoryItem> _payments = [];
  bool _isLoading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payments = await _paymentService.getPayments(
        widget.trip.id,
        status: _statusFilter,
      );

      if (!mounted) return;

      setState(() {
        _payments = payments;
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green;
      case 'PENDING':
      case 'CREATED':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.purple;
      case 'CANCELLED':
      default:
        return Colors.grey;
    }
  }

  Future<void> _reconcilePayment(PaymentHistoryItem payment) async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!mounted) return;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internet connection required')),
      );
      return;
    }

    try {
      final res = await _paymentService.reconcilePayment(
        tripId: widget.trip.id,
        paymentId: payment.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.detail),
          backgroundColor: res.reconciled ? Colors.green : Colors.blueGrey,
        ),
      );

      await _loadPayments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconciliation error: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestRefund(PaymentHistoryItem payment) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to refund ₹${(payment.amountPaise / 100).toStringAsFixed(2)}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will refund the amount via Razorpay and deduct it from the trip wallet balance.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final res = await _paymentService.refundPayment(
        tripId: widget.trip.id,
        paymentId: payment.id,
        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refund of ₹${(res.amountPaise / 100).toStringAsFixed(2)} processed successfully!'),
          backgroundColor: Colors.purple,
        ),
      );

      await _loadPayments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refund failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Payments'),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': null},
      {'label': 'Success', 'value': 'SUCCESS'},
      {'label': 'Pending', 'value': 'PENDING'},
      {'label': 'Refunded', 'value': 'REFUNDED'},
      {'label': 'Failed', 'value': 'FAILED'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _statusFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _statusFilter = selected ? f['value'] : null;
                });
                _loadPayments();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
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
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPayments,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No online payments found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payment = _payments[index];
          final statusColor = _getStatusColor(payment.status);

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${(payment.amountPaise / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          payment.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (payment.userName != null)
                    Text(
                      'Payer: ${payment.userName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Order ID: ${payment.providerOrderId}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (payment.providerPaymentId != null)
                    Text(
                      'Payment ID: ${payment.providerPaymentId}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    payment.createdAt.toLocal().toString().split('.')[0],
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (payment.status == 'CREATED' || payment.status == 'PENDING')
                        OutlinedButton.icon(
                          onPressed: () => _reconcilePayment(payment),
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Reconcile Status'),
                        ),
                      if (payment.status == 'SUCCESS')
                        TextButton.icon(
                          onPressed: () => _requestRefund(payment),
                          icon: const Icon(Icons.undo, size: 16, color: Colors.purple),
                          label: const Text('Refund', style: TextStyle(color: Colors.purple)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
