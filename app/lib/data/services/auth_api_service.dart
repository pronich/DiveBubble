import 'dart:convert';

import 'package:http/http.dart' as http;

class GoogleSignInResult {
  const GoogleSignInResult({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String userId;
}

class RefreshResult {
  const RefreshResult({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
}

class AuthApiService {
  AuthApiService({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<GoogleSignInResult> signInWithGoogle(String idToken) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Google sign-in failed');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return GoogleSignInResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
      userId: decoded['userId'] as String,
    );
  }

  Future<RefreshResult> refresh(String refreshToken) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Could not refresh session');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return RefreshResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
    );
  }

  Future<void> logout(String accessToken) async {
    await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
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
}
