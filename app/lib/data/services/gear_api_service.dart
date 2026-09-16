import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gear_ownership_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'error_codes.dart';

class GearApiService {
  GearApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
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

  Future<List<GearOwnershipApiModel>> fetchGear() async {
    final res = await _client.get(Uri.parse('$baseUrl/me/gear'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'fetchGear failed: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => GearOwnershipApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GearOwnershipApiModel> setGearStatus({required String itemKey, required String status}) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/me/gear/${Uri.encodeComponent(itemKey)}'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'setGearStatus failed: ${res.statusCode}');
    }
    return GearOwnershipApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // itemKey is percent-encoded since custom items use the user's free-typed text as the key directly, unlike the Essential catalogue's fixed slugs.
  Future<void> deleteGear(String itemKey) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/me/gear/${Uri.encodeComponent(itemKey)}'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception(_extractError(res.body) ?? 'deleteGear failed: ${res.statusCode}');
    }
  }
}
