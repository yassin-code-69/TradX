import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String baseUrl = 'http://localhost:4000/api/v1';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
