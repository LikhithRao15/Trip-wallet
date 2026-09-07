import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/trip.dart';

class TripService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<List<Trip>> getTrips() async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    final response = await _apiClient.get(
      ApiConstants.trips,
      token: token,
    );

    final trips = response as List;

    return trips
        .map((trip) => Trip.fromJson(
              Map<String, dynamic>.from(trip),
            ))
        .toList();
  }
}