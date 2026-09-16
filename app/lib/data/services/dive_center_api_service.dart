import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dive_center_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'error_codes.dart';

/// Trimmed counterpart to admin/'s DiveCenterApiService — divers only ever *view* a dive center's public profile here, never create/manage one.
class DiveCenterApiService {
  DiveCenterApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  // Server errors come back as {"error": "<code>"}; describeErrorCode maps it to a message or passes it through unchanged if unrecognized.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return describeErrorCode(decoded['error'] as String);
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  Future<DiveCenterApiModel> fetchById(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchById failed: ${res.statusCode}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // GET /dive-centers/{id} itself is public now, so a successful fetchById no longer implies membership; this checks it explicitly.
  Future<bool> fetchIsMember(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id/membership'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchIsMember failed: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['isMember'] as bool;
  }
}
