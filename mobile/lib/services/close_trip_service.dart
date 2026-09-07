import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class CloseTripService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    return token;
  }

  Future<Map<String, dynamic>> closeTrip(String tripId) async {
    final token = await _getToken();

    return await _apiClient.post(
      '${ApiConstants.trips}/$tripId/close',
      {},
      token: token,
    );
  }
}