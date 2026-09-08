import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/statistics.dart';

class StatisticsService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  Future<StatisticsResult> getStatistics(
    String tripId, {
    String? category,
    String? memberId,
    String? startDate,
    String? endDate,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (memberId != null && memberId.isNotEmpty) {
      queryParams['member_id'] = memberId;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/statistics').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    return StatisticsResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<String> exportExpensesCsv(String tripId) async {
    final token = await _getToken();
    return await _apiClient.getRaw(
      '${ApiConstants.trips}/$tripId/reports/expenses.csv',
      token: token,
    );
  }

  Future<String> exportSummaryCsv(String tripId) async {
    final token = await _getToken();
    return await _apiClient.getRaw(
      '${ApiConstants.trips}/$tripId/reports/summary.csv',
      token: token,
    );
  }
}