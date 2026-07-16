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
}
