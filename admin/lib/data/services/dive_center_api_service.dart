import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/dive_center_member.dart';
import '../models/dive_center_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

/// Thrown when a member search by email finds no matching DiveBubble account — a distinct
/// type (not a generic Exception) so the Invite dialog can show "they need to sign up
/// first" instead of a raw error, matching backend's 404 "no account found for that email".
class MemberNotFoundException implements Exception {
  const MemberNotFoundException();
}

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

  Future<List<DiveCenterApiModel>> fetchMine() async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/mine'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMine failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => DiveCenterApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DiveCenterApiModel> fetchById(String id) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$id'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchById failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DiveCenterApiModel> create({
    required String name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (agency != null) 'agency': agency,
      if (agencyDetail != null) 'agencyDetail': agencyDetail,
      if (languages != null) 'languages': languages,
      if (website != null) 'website': website,
      if (phone != null) 'phone': phone,
    };
    final res = await _client.post(
      Uri.parse('$baseUrl/dive-centers'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('create failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DiveCenterApiModel> update(
    String id, {
    String? name,
    String? location,
    String? description,
    String? agency,
    String? agencyDetail,
    String? languages,
    String? website,
    String? phone,
    String? email,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (agency != null) 'agency': agency,
      if (agencyDetail != null) 'agencyDetail': agencyDetail,
      if (languages != null) 'languages': languages,
      if (website != null) 'website': website,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
    final res = await _client.patch(
      Uri.parse('$baseUrl/dive-centers/$id'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('update failed: ${res.statusCode} ${res.body}');
    }
    return DiveCenterApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<DiveCenterMember>> fetchMembers(String diveCenterId) async {
    final res = await _client.get(Uri.parse('$baseUrl/dive-centers/$diveCenterId/members'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMembers failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => DiveCenterMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Prefix-email lookup, owner-only on the backend — not a user directory. Used to
  // confirm "is this the right person" before actually adding them via addMember below.
  Future<MemberPreview> searchMemberByEmail(String diveCenterId, String email) async {
    final uri = Uri.parse('$baseUrl/dive-centers/$diveCenterId/members/search').replace(queryParameters: {'email': email});
    final res = await _client.get(uri, headers: await _authHeaders());
    if (res.statusCode == 404) {
      throw const MemberNotFoundException();
    }
    if (res.statusCode != 200) {
      throw Exception('searchMemberByEmail failed: ${res.statusCode} ${res.body}');
    }
    return MemberPreview.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Also how an existing member's role changes — the backend upserts, so re-adding with a
  // different role just updates it (see divecenter.Repository.AddMember's own comment).
  Future<void> addMember(String diveCenterId, String userId, String role) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/dive-centers/$diveCenterId/members'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'role': role}),
    );
    if (res.statusCode != 201) {
      throw Exception('addMember failed: ${res.statusCode} ${res.body}');
    }
  }

  // Counterpart to addMember for an email with no DiveBubble account yet — called when
  // searchMemberByEmail throws MemberNotFoundException. No pending-list to reconcile with
  // (see CLAUDE.md) — a failure here is a real error, not swallowed.
  Future<void> inviteMember(String diveCenterId, String email, String role) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/dive-centers/$diveCenterId/invitations'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'role': role}),
    );
    if (res.statusCode != 201) {
      String message = 'inviteMember failed: ${res.statusCode}';
      try {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['error'] is String) message = decoded['error'] as String;
      } catch (_) {
        // best-effort — fall back to the generic message above
      }
      throw Exception(message);
    }
  }

  Future<void> removeMember(String diveCenterId, String userId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/dive-centers/$diveCenterId/members/$userId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 204) {
      // Surfaces backend's own message (e.g. "cannot remove the last owner", 409) directly
      // rather than a raw status dump — the caller shows this in a SnackBar as-is.
      String message = 'removeMember failed: ${res.statusCode}';
      try {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['error'] is String) message = decoded['error'] as String;
      } catch (_) {
        // best-effort — fall back to the generic message above
      }
      throw Exception(message);
    }
  }

  Future<String> uploadLogo(String id, List<int> bytes, String filename) async {
    final json = await uploadImageBytes(
      Uri.parse('$baseUrl/dive-centers/$id/logo'),
      bytes: bytes,
      filename: filename,
      headers: await _authHeaders(),
    );
    return json['logoUrl'] as String;
  }
}
