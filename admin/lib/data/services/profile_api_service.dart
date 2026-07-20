import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/my_profile.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';
import 'multipart_upload.dart';

class ProfileApiService {
  ProfileApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    return {'Authorization': 'Bearer $token'};
  }

  Future<MyProfile> fetchMe() async {
    final res = await _client.get(Uri.parse('$baseUrl/me'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchMe failed: ${res.statusCode} ${res.body}');
    }
    return _fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Trimmed public-profile projection (GET /users/{id}) — used to resolve a chat message
  // sender's name/avatar, same shape as MyProfile since the fields overlap exactly.
  Future<MyProfile> fetchById(String userId) async {
    final res = await _client.get(Uri.parse('$baseUrl/users/$userId'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchById failed: ${res.statusCode} ${res.body}');
    }
    return _fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // nil-leaves-unchanged on the backend (profile.UpdateParams' COALESCE), same contract as
  // app/'s own PATCH /me. Used by both the onboarding step (name/location/bio only) and
  // AccountPage's full edit form.
  Future<MyProfile> updateProfile({
    String? displayName,
    String? location,
    String? bio,
    int? diveCount,
    String? certificationLevel,
    String? certificationAgency,
    String? certificationNumber,
    String? languages,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (location != null) 'location': location,
      if (bio != null) 'bio': bio,
      if (diveCount != null) 'diveCount': diveCount,
      if (certificationLevel != null) 'certificationLevel': certificationLevel,
      if (certificationAgency != null) 'certificationAgency': certificationAgency,
      if (certificationNumber != null) 'certificationNumber': certificationNumber,
      if (languages != null) 'languages': languages,
    };
    final res = await _client.patch(
      Uri.parse('$baseUrl/me'),
      headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('updateProfile failed: ${res.statusCode} ${res.body}');
    }
    return _fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<MyProfile> uploadAvatar(List<int> bytes, String filename) async {
    final json = await uploadImageBytes(
      Uri.parse('$baseUrl/me/avatar'),
      bytes: bytes,
      filename: filename,
      headers: await _authHeaders(),
    );
    return _fromJson(json);
  }

  MyProfile _fromJson(Map<String, dynamic> json) => MyProfile(
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        location: json['location'] as String?,
        bio: json['bio'] as String?,
        diveCount: json['diveCount'] as int? ?? 0,
        certificationLevel: json['certificationLevel'] as String?,
        certificationAgency: json['certificationAgency'] as String?,
        certificationNumber: json['certificationNumber'] as String?,
        languages: json['languages'] as String? ?? '',
        memberSince: json['memberSince'] != null ? DateTime.tryParse(json['memberSince'] as String) : null,
      );
}
