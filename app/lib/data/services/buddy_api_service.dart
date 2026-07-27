import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/buddy_request_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

class BuddyApiService {
  BuddyApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<BuddyRequestApiModel>> fetchRequests(String tripId) async {
    final res = await _client.get(Uri.parse('$baseUrl/trips/$tripId/buddy'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchRequests failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded
        .map((e) => BuddyRequestApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // No fields at all — a buddy request is just "I want a buddy for this trip".
  Future<BuddyRequestApiModel> createRequest(String tripId) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/buddy'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 201) {
      throw Exception('createRequest failed: ${res.statusCode} ${res.body}');
    }
    return BuddyRequestApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> joinRequest(String tripId, String requestId) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/buddy/$requestId/join'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Could not join buddy request');
    }
  }

  // Server errors come back as {"error": "..."} — surface that message directly instead of the raw body.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  Future<List<String>> fetchJoinedUserIds(String tripId, String requestId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/trips/$tripId/buddy/$requestId/joins'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchJoinedUserIds failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    return decoded.map((e) => (e as Map<String, dynamic>)['userId'] as String).toList();
  }

  Future<void> leaveRequest(String tripId, String requestId) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/buddy/$requestId/leave'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception(_extractError(res.body) ?? 'Could not leave buddy group');
    }
  }

  Future<void> dissolveRequest(String tripId, String requestId) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/trips/$tripId/buddy/$requestId/dissolve'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      throw Exception(_extractError(res.body) ?? 'Could not dissolve buddy group');
    }
  }

  // Also clears the alert server-side — checking is the acknowledgment, same as opening a chat.
  Future<bool> fetchHasAlert(String tripId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/trips/$tripId/buddy/alert'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('fetchHasAlert failed: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded['hasAlert'] as bool;
  }
}
