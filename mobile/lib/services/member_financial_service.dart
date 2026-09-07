import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/member_financial_summary.dart';

class MemberFinancialService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  Future<List<MemberFinancialSummary>> getSummary(
    String tripId,
  ) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/member-summary',
      token: token,
    );

    final list = response as List;

    return list
        .map(
          (item) => MemberFinancialSummary.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}