import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class NetworkInfo {
  final Connectivity _connectivity = Connectivity();
  final http.Client _client = http.Client();

  static NetworkInfo? _instance;
  static NetworkInfo get instance => _instance ??= NetworkInfo();

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  NetworkInfo() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final connected = await isConnected;
      _connectivityController.add(connected);
    });
  }

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return false;
      }
      return await checkServerReachable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkServerReachable() async {
    try {
      final res = await _client
          .get(Uri.parse('${ApiConstants.baseUrl}/'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200 || res.statusCode == 404;
    } catch (_) {
      return false;
    }
  }
}
