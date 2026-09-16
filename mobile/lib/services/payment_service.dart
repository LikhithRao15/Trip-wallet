import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/payment_order.dart';

class PaymentService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  PaymentService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Please login again');
    }
    return token;
  }

  /// Creates a server-side Razorpay order before checkout.
  /// Flutter never generates orders directly with Razorpay or contains secret keys.
  /// The backend returns the public Razorpay Key ID, the Razorpay order ID, and the internal payment ID.
  Future<PaymentOrder> createOrder({
    required String tripId,
    required int amountPaise,
    String? idempotencyKey,
  }) async {
    final token = await _getToken();
    final key = idempotencyKey ??
        'PAY-${DateTime.now().microsecondsSinceEpoch}-$amountPaise';

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/payments/order',
      {
        'amount_paise': amountPaise,
      },
      token: token,
      headers: {
        'Idempotency-Key': key,
      },
    );

    return PaymentOrder.fromJson(Map<String, dynamic>.from(response));
  }

  /// Verifies a completed checkout with the backend.
  /// Razorpay signature verification and wallet credit are strictly performed server-side.
  /// Returns the verified payment result.
  Future<PaymentVerificationResult> verifyPayment({
    required String tripId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/payments/verify',
      {
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
      token: token,
    );

    return PaymentVerificationResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Fetches payment history for the trip.
  Future<List<PaymentHistoryItem>> getPayments(
    String tripId, {
    String? status,
  }) async {
    final token = await _getToken();
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/payments').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    final data = Map<String, dynamic>.from(response);
    final items = data['items'] as List? ?? [];
    return items
        .map((item) => PaymentHistoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Requests a server-side refund for a completed payment.
  Future<PaymentRefundResult> refundPayment({
    required String tripId,
    required String paymentId,
    String? reason,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/payments/$paymentId/refund',
      {
        'reason': reason,
      },
      token: token,
    );

    return PaymentRefundResult.fromJson(Map<String, dynamic>.from(response));
  }

  /// Reconciles an unresolved payment with Razorpay.
  Future<PaymentReconcileResult> reconcilePayment({
    required String tripId,
    required String paymentId,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/payments/$paymentId/reconcile',
      {},
      token: token,
    );

    return PaymentReconcileResult.fromJson(Map<String, dynamic>.from(response));
  }
}
