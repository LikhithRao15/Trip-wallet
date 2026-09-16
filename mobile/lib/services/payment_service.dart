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
}
