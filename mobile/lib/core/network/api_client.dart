import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: requestHeaders,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail']?.toString() ?? 'Request failed',
    );
  }

  Future<dynamic> get(
    String endpoint, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse(endpoint),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['detail']?.toString() ?? 'Request failed',
    );
  }

  Future<Map<String, dynamic>> put(
  String endpoint,
  Map<String, dynamic> body, {
  String? token,
}) async {
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }

  final response = await http.put(
    Uri.parse(endpoint),
    headers: headers,
    body: jsonEncode(body),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(
    data['detail']?.toString() ?? 'Request failed',
  );
}
}