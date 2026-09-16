import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/network/network_info.dart';
import '../../models/trip.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/razorpay_service.dart';

class OnlinePaymentScreen extends StatefulWidget {
  final Trip trip;

  const OnlinePaymentScreen({super.key, required this.trip});

  @override
  State<OnlinePaymentScreen> createState() => _OnlinePaymentScreenState();
}

class _OnlinePaymentScreenState extends State<OnlinePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  final PaymentService _paymentService = PaymentService();
  final RazorpayService _razorpayService = RazorpayService();
  final AuthService _authService = AuthService();

  bool _isProcessing = false;
  bool _isVerifying = false;
  bool _hasVerified = false;
  String? _statusMessage;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userEmail = user['email'] as String?;
        });
      }
    } catch (_) {
      // Non-critical: prefill is optional
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Prevent duplicate processing if callback fires multiple times
    if (_hasVerified || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _statusMessage = 'Verifying payment with server...';
    });

    try {
      final result = await _paymentService.verifyPayment(
        tripId: widget.trip.id,
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      _hasVerified = true;

      if (!mounted) return;

      if (result.status == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified and wallet credited successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isProcessing = false;
          _isVerifying = false;
          _statusMessage = 'Payment verification pending or incomplete.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isVerifying = false;
        _statusMessage = 'Verification failed: ${e.toString().replaceFirst("Exception: ", "")}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isVerifying = false;
      _statusMessage = 'Payment failed: ${response.message ?? "Cancelled"}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed (${response.code}): ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  Future<void> _startCheckout() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!mounted) return;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection required for online payments.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Convert rupees to paise integer safely
    final amountText = _amountController.text.trim();
    final parts = amountText.split('.');
    final rupees = int.tryParse(parts[0]) ?? 0;
    int paise = 0;
    if (parts.length == 2) {
      final decimal = parts[1].padRight(2, '0');
      if (decimal.length > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 2 decimal places allowed')),
        );
        return;
      }
      paise = int.tryParse(decimal) ?? 0;
    }
    final amountPaise = rupees * 100 + paise;

    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating payment order...';
    });

    try {
      // 1. Create server-side order. Flutter NEVER creates Razorpay orders directly.
      final order = await _paymentService.createOrder(
        tripId: widget.trip.id,
        amountPaise: amountPaise,
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Opening Razorpay checkout...';
      });

      // 2. Open checkout using only the public Razorpay Key ID returned by the backend
      _razorpayService.openCheckout(
        keyId: order.razorpayKeyId,
        orderId: order.razorpayOrderId,
        amountPaise: order.amountPaise,
        userEmail: _userEmail ?? 'user@tripwallet.app',
        userPhone: '9999999999',
        description: 'Wallet top-up for ${widget.trip.name}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate payment: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Funds via Razorpay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Online Payment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payments are securely processed via Razorpay Test Mode and verified server-side before wallet credit.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isProcessing && !_isVerifying,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${widget.trip.currency} ',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: const OutlineInputBorder(),
                  helperText: 'Enter amount to contribute to trip wallet',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              if (_statusMessage != null) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: (_isProcessing || _isVerifying) ? null : _startCheckout,
                  icon: (_isProcessing || _isVerifying)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isVerifying
                        ? 'Verifying Payment...'
                        : _isProcessing
                            ? 'Processing...'
                            : 'Pay with Razorpay',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
