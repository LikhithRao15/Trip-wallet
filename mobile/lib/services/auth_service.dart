import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _apiClient.post(
      ApiConstants.register,
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      {
        'email': email,
        'password': password,
      },
    );

    final token = response['access_token'];

    if (token != null) {
      await _tokenStorage.saveToken(token);
    }

    return response;
  }

  Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<Map<String, dynamic>?> getMe() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return null;

    try {
      final response = await _apiClient.get(
        ApiConstants.me,
        token: token,
      );
      return Map<String, dynamic>.from(response);
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<bool> hasValidSession() async {
    final user = await getMe();
    return user != null;
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }
}