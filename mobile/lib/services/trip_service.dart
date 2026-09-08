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

  Future<Trip> getTrip(String tripId) async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    final response = await _apiClient.get(
      '${ApiConstants.trips}/$tripId',
      token: token,
    );

    return Trip.fromJson(Map<String, dynamic>.from(response));
  }

  Future<Trip> updateTrip(
    String tripId, {
    String? name,
    String? destination,
    String? description,
    String? startDate,
    String? endDate,
  }) async {
    final token = await _tokenStorage.getToken();

    if (token == null) {
      throw Exception('Please login again');
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (destination != null) body['destination'] = destination;
    if (description != null) body['description'] = description;
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;

    final response = await _apiClient.put(
      '${ApiConstants.trips}/$tripId',
      body,
      token: token,
    );

    return Trip.fromJson(Map<String, dynamic>.from(response));
  }
}