import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/activity.dart';

class ActivityService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Please login again');
    }
    return token;
  }

  Future<TripActivityListResult> getTripActivity(
    String tripId, {
    int limit = 20,
    int offset = 0,
    String? eventType,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (eventType != null && eventType.isNotEmpty) {
      queryParams['event_type'] = eventType;
    }

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/activity').replace(
      queryParameters: queryParams,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    return TripActivityListResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }
}
