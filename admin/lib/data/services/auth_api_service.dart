import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.userId,
    required this.isNewUser,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String userId;
  final bool isNewUser;
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

  Future<AuthResult> signInWithGoogle(String idToken) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Google sign-in failed');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
      userId: decoded['userId'] as String,
      isNewUser: decoded['isNewUser'] as bool? ?? false,
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

  // Requests a magic-link email — the link (clicked in a browser, possibly a different
  // tab/device) carries the token+email back to this app's own root as query params, where
  // MagicLinkGate picks it up and calls verifyEmailLogin with them.
  Future<void> startEmailLogin(String email) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/email/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'kind': 'magic_link'}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Could not send login email');
    }
  }

  Future<AuthResult> verifyEmailLogin(String email, String code) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/email/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'That link is invalid or has expired');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
      userId: decoded['userId'] as String,
      isNewUser: decoded['isNewUser'] as bool? ?? false,
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
