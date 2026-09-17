import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/contribution.dart';

class ContributionService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  /// Admin directly records a contribution (e.g. cash or direct manual entry).
  Future<Contribution> addContribution({
    required String tripId,
    required String memberId,
    required int amountPaise,
    required String paymentMethod,
    String? paymentReference,
    String? note,
  }) async {
    final token = await _getToken();

    final idempotencyKey =
        '${DateTime.now().microsecondsSinceEpoch}-$memberId';

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/contributions',
      {
        'member_id': memberId,
        'amount_paise': amountPaise,
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'note': note,
      },
      token: token,
      headers: {
        'Idempotency-Key': idempotencyKey,
      },
    );

    return Contribution.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Any active trip member submits a contribution made directly via UPI/bank transfer to trip admin.
  /// Status is PENDING awaiting admin confirmation.
  Future<Contribution> submitMemberContribution({
    required String tripId,
    required int amountPaise,
    required String paymentReference,
    String paymentMethod = 'UPI',
    String? note,
  }) async {
    final token = await _getToken();

    final idempotencyKey =
        'SUBMIT-${DateTime.now().microsecondsSinceEpoch}-$amountPaise';

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/contributions/submit',
      {
        'amount_paise': amountPaise,
        'payment_reference': paymentReference,
        'payment_method': paymentMethod,
        'note': note,
      },
      token: token,
      headers: {
        'Idempotency-Key': idempotencyKey,
      },
    );

    return Contribution.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Trip admin gets list of pending contributions awaiting verification.
  Future<List<Contribution>> getPendingContributions(String tripId) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/contributions/pending',
      token: token,
    );

    final list = response as List;
    return list
        .map(
          (item) => Contribution.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// Trip admin confirms a pending contribution after verifying bank/UPI receipt.
  Future<Contribution> confirmContribution({
    required String tripId,
    required String contributionId,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/contributions/$contributionId/confirm',
      {},
      token: token,
    );

    return Contribution.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Trip admin rejects an unverified pending contribution.
  Future<Contribution> rejectContribution({
    required String tripId,
    required String contributionId,
    String? reason,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/contributions/$contributionId/reject',
      {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      token: token,
    );

    return Contribution.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Gets list of contributions with optional filters for member, payment method, status, search, and sorting.
  Future<List<Contribution>> getContributions(
    String tripId, {
    String? memberId,
    String? paymentMethod,
    String? status,
    String? search,
    String? sort,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{};
    if (memberId != null && memberId.isNotEmpty) {
      queryParams['member_id'] = memberId;
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      queryParams['payment_method'] = paymentMethod;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    final uri =
        Uri.parse('${ApiConstants.trips}/$tripId/contributions').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    final contributions = response as List;

    return contributions
        .map(
          (item) => Contribution.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}