import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/constants/api_constants.dart';
import '../models/trip_member.dart';

class MemberService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<List<TripMember>> getMembers(String tripId) async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId/members',
      token: token,
    );

    final members = response as List;

    return members
        .map(
          (member) => TripMember.fromJson(
            Map<String, dynamic>.from(member),
          ),
        )
        .toList();
  }

  Future<TripMember> addMember({
    required String tripId,
    required String email,
  }) async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    final response = await _apiClient.post(
      '${ApiConstants.trips}/$tripId/members',
      {
        'email': email.trim(),
      },
      token: token,
    );

    return TripMember.fromJson(response);
  }

  Future<void> removeMember({
    required String tripId,
    required String memberId,
  }) async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    await _apiClient.delete(
      '${ApiConstants.trips}/$tripId/members/$memberId',
      token: token,
    );
  }
}