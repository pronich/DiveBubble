import 'dart:convert';

import 'package:http/http.dart' as http;

class ProviderSignInResult {
  const ProviderSignInResult({
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

  Future<ProviderSignInResult> signInWithGoogle(String idToken) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Google sign-in failed');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return ProviderSignInResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
      userId: decoded['userId'] as String,
      isNewUser: decoded['isNewUser'] as bool? ?? false,
    );
  }

  // nonce is the *raw* nonce (the client sends Apple the SHA-256 hex digest of it instead —
  // see AuthRepository.signInWithApple). email/fullName are out-of-band hints from
  // AuthorizationCredentialAppleID, present only on the very first authorization ever.
  Future<ProviderSignInResult> signInWithApple({
    required String identityToken,
    required String nonce,
    String? email,
    String? fullName,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identityToken': identityToken,
        'nonce': nonce,
        if (email != null) 'email': email,
        if (fullName != null) 'fullName': fullName,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Apple sign-in failed');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return ProviderSignInResult(
      accessToken: decoded['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(decoded['accessTokenExpiresAt'] as String),
      refreshToken: decoded['refreshToken'] as String,
      userId: decoded['userId'] as String,
      isNewUser: decoded['isNewUser'] as bool? ?? false,
    );
  }

  // kind is always "otp" here — app/'s passwordless flow is code-entry, unlike admin/'s
  // clicked-link flow (same backend endpoint, same email_login_codes table either way, see
  // backend's internal/auth/email.go).
  Future<void> startEmailLogin(String email) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/email/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'kind': 'otp'}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Could not send login code');
    }
  }

  Future<ProviderSignInResult> verifyEmailLogin(String email, String code) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/email/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'That code is invalid or has expired');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return ProviderSignInResult(
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

  Future<void> logout(String accessToken) async {
    await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  // Unlike logout (best-effort, status ignored), a failure here must propagate — the caller
  // only clears the local session once this genuinely succeeds (see AuthRepository.deleteAccount).
  Future<void> deleteAccount(String accessToken) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Could not delete account');
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
}
