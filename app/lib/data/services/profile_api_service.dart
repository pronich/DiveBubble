import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile_api_model.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

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

  Future<ProfileApiModel> fetchProfile() async {
    final res = await _client.get(Uri.parse('$baseUrl/me'), headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw Exception('fetchProfile failed: ${res.statusCode} ${res.body}');
    }
    return ProfileApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ProfileApiModel> updateProfile({
    String? displayName,
    String? avatarUrl,
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
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
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
    return ProfileApiModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
