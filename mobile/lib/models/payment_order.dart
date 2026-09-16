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

class PaymentHistoryItem {
  final String id;
  final String tripId;
  final String userId;
  final String? userName;
  final int amountPaise;
  final String provider;
  final String providerOrderId;
  final String? providerPaymentId;
  final String status;
  final DateTime createdAt;

  PaymentHistoryItem({
    required this.id,
    required this.tripId,
    required this.userId,
    this.userName,
    required this.amountPaise,
    required this.provider,
    required this.providerOrderId,
    this.providerPaymentId,
    required this.status,
    required this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String?,
      amountPaise: json['amount_paise'] as int? ?? 0,
      provider: json['provider']?.toString() ?? 'razorpay',
      providerOrderId: json['provider_order_id']?.toString() ?? '',
      providerPaymentId: json['provider_payment_id']?.toString(),
      status: json['status']?.toString() ?? 'CREATED',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'user_name': userName,
      'amount_paise': amountPaise,
      'provider': provider,
      'provider_order_id': providerOrderId,
      'provider_payment_id': providerPaymentId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentRefundResult {
  final String refundId;
  final String paymentId;
  final String razorpayRefundId;
  final int amountPaise;
  final String status;
  final DateTime createdAt;

  PaymentRefundResult({
    required this.refundId,
    required this.paymentId,
    required this.razorpayRefundId,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
  });

  factory PaymentRefundResult.fromJson(Map<String, dynamic> json) {
    return PaymentRefundResult(
      refundId: json['refund_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      razorpayRefundId: json['razorpay_refund_id']?.toString() ?? '',
      amountPaise: json['amount_paise'] as int? ?? 0,
      status: json['status']?.toString() ?? 'PROCESSED',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refund_id': refundId,
      'payment_id': paymentId,
      'razorpay_refund_id': razorpayRefundId,
      'amount_paise': amountPaise,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentReconcileResult {
  final String paymentId;
  final String providerOrderId;
  final String previousStatus;
  final String currentStatus;
  final bool reconciled;
  final String detail;

  PaymentReconcileResult({
    required this.paymentId,
    required this.providerOrderId,
    required this.previousStatus,
    required this.currentStatus,
    required this.reconciled,
    required this.detail,
  });

  factory PaymentReconcileResult.fromJson(Map<String, dynamic> json) {
    return PaymentReconcileResult(
      paymentId: json['payment_id']?.toString() ?? '',
      providerOrderId: json['provider_order_id']?.toString() ?? '',
      previousStatus: json['previous_status']?.toString() ?? '',
      currentStatus: json['current_status']?.toString() ?? '',
      reconciled: json['reconciled'] as bool? ?? false,
      detail: json['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'provider_order_id': providerOrderId,
      'previous_status': previousStatus,
      'current_status': currentStatus,
      'reconciled': reconciled,
      'detail': detail,
    };
  }
}
