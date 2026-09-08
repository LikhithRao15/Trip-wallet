import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<String> _getToken() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Please login again');
    }
    return token;
  }

  Future<NotificationListResult> getNotifications({
    int limit = 20,
    int offset = 0,
    bool? unreadOnly,
  }) async {
    final token = await _getToken();

    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (unreadOnly == true) {
      queryParams['unread_only'] = 'true';
    }

    final uri = Uri.parse(ApiConstants.notifications).replace(
      queryParameters: queryParams,
    );

    final response = await _apiClient.get(
      uri.toString(),
      token: token,
    );

    return NotificationListResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await getNotifications(limit: 1);
      return res.unreadCount;
    } catch (_) {
      return 0;
    }
  }

  Future<AppNotification> markAsRead(String notificationId) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.notifications}/$notificationId/read',
      {},
      token: token,
    );

    return AppNotification.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<int> markAllAsRead() async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '${ApiConstants.notifications}/read-all',
      {},
      token: token,
    );

    return response['marked_count'] ?? 0;
  }
}
