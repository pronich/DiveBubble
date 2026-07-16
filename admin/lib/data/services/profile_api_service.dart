import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/my_profile.dart';
import 'access_token_provider.dart';
import 'auth_required_exception.dart';

/// GET-only — admin/ just needs enough to render the account footer (name/avatar), not
/// full profile editing yet.
class ProfileApiService {
  ProfileApiService({required this.baseUrl, required this.getAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider getAccessToken;
  final http.Client _client;

  Future<MyProfile> fetchMe() async {
    final token = await getAccessToken();
    if (token == null) throw const AuthRequiredException();
    final res = await _client.get(Uri.parse('$baseUrl/me'), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw Exception('fetchMe failed: ${res.statusCode} ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return MyProfile(displayName: json['displayName'] as String?, avatarUrl: json['avatarUrl'] as String?);
  }
}
