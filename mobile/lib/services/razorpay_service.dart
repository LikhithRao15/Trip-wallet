import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String userEmail,
    required String userPhone,
    String? description,
  }) {
    final options = {
      'key': keyId,
      'amount': amountPaise,
      'order_id': orderId,
      'name': 'Trip Wallet',
      'description': description ?? 'Trip Wallet contribution',
      'prefill': {
        'email': userEmail,
        'contact': userPhone,
      },
      'theme': {
        'color': '#3399cc',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay checkout error: $e');
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}