import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dive_center_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

/// app/'s trimmed counterpart to admin/'s DiveCenterApiService — divers only ever need to
/// *view* a dive center's public profile (organizer attribution on a business trip), never
/// create/manage one from here.
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

  Future<DiveCenterApiModel> fetchById(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchById failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Caller-scoped: whether *I* am staff of this dive center — GET /dive-centers/{id} itself
  // is public now, so a successful fetch no longer implies membership (see backend's own
  // comment on handleGetDiveCenterMembership).
  Future<bool> fetchIsMember(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id/membership'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchIsMember failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['isMember'] as bool;
  }
}
