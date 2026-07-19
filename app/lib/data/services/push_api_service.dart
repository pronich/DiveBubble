import 'dart:convert';

import 'package:http/http.dart' as http;

import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class PushApiService {
  PushApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<void> registerToken({required String token, required String platform}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/me/push-token'),
      headers: await _authHeaders(),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (res.statusCode != 204) {
      throw Exception('registerToken failed: ${res.statusCode} ${res.body}');
    }
  }
}
