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

  Future<StatisticsResult> getStatistics(String tripId) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/statistics',
      token: token,
    );

    return StatisticsResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }
}