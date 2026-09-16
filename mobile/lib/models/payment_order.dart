class PaymentOrder {
  final String paymentId;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String razorpayKeyId;
  final String status;

  PaymentOrder({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.razorpayKeyId,
    required this.status,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      paymentId: json['payment_id']?.toString() ?? '',
      razorpayOrderId: json['razorpay_order_id']?.toString() ?? '',
      amountPaise: json['amount_paise'] as int? ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      razorpayKeyId: json['razorpay_key_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CREATED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'amount_paise': amountPaise,
      'currency': currency,
      'razorpay_key_id': razorpayKeyId,
      'status': status,
    };
  }
}

class PaymentVerificationResult {
  final String paymentId;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String status;

  PaymentVerificationResult({
    required this.paymentId,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.status,
  });

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResult(
      paymentId: json['payment_id']?.toString() ?? '',
      razorpayPaymentId: json['razorpay_payment_id']?.toString() ?? '',
      razorpayOrderId: json['razorpay_order_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'status': status,
    };
  }
}
