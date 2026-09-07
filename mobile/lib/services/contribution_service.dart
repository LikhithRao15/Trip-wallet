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

  Future<Contribution> addContribution({
    required String tripId,
    required String memberId,
    required int amountPaise,
    required String paymentMethod,
    String? note,
  }) async {
    final token = await _getToken();

    // Unique key prevents accidental duplicate contributions.
    final idempotencyKey =
        '${DateTime.now().microsecondsSinceEpoch}-$memberId';

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/contributions',
      {
        'member_id': memberId,
        'amount_paise': amountPaise,
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

  Future<List<Contribution>> getContributions(String tripId) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/contributions',
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