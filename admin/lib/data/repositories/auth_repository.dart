import 'package:flutter/foundation.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';

/// Result of a successful sign-in — isNewUser isn't acted on here the way app/'s
/// LoginSheet uses it (there's no personal-profile onboarding in admin/), but it's kept
/// on the result for parity with the mobile client's AuthApiService/backend contract.
class SignInResult {
  const SignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

/// Web-only variant of app/'s AuthRepository. Google Sign-In is temporarily disabled here
/// (2026-07-20) — `google_sign_in_web`'s plugin registration eagerly constructs a
/// `GoogleSignInPlugin` at app bootstrap regardless of whether this code ever calls it,
/// and that constructor's own background GIS script load was observed hanging the entire
/// app on the pre-Flutter loading splash in production (reproducible on admin.divebubble.io,
/// not on localhost, for at least some Google accounts) — even with `initialize()` never
/// called at all. Removing the `google_sign_in`/`google_sign_in_web` dependencies stops the
/// plugin from being registered/constructed in the first place. Email/passwordless (see
/// startEmailLogin/completeEmailLogin) is unaffected and is the only sign-in path for now.
class AuthRepository extends ChangeNotifier {
  AuthRepository({required AuthApiService apiService, required TokenStorageService tokenStorage})
    : _api = apiService,
      _tokens = tokenStorage;

  final AuthApiService _api;
  final TokenStorageService _tokens;

  /// Requests a magic-link email for passwordless login. See
  /// AuthApiService.startEmailLogin's own doc comment for where the link points.
  Future<void> startEmailLogin(String email) => _api.startEmailLogin(email);

  /// Completes a magic-link login — called by MagicLinkGate with the token+email it read
  /// off this app's own URL query params on load.
  Future<SignInResult> completeEmailLogin(String email, String token) async {
    final result = await _api.verifyEmailLogin(email, token);
    return _persistAuthResult(result);
  }

  Future<SignInResult> _persistAuthResult(AuthResult result) async {
    await _tokens.save(
      accessToken: result.accessToken,
      accessTokenExpiresAt: result.accessTokenExpiresAt,
      refreshToken: result.refreshToken,
      userId: result.userId,
    );
    notifyListeners();
    return SignInResult(userId: result.userId, isNewUser: result.isNewUser);
  }

  /// Returns a currently-valid access token, transparently refreshing it if it's expired (or
  /// close to it). Returns null if there's no session at all, or refreshing failed — either
  /// way, any stored tokens are cleared so the caller can prompt login.
  Future<String?> getValidAccessToken() async {
    final stored = await _tokens.read();
    if (stored == null) return null;

    const refreshBuffer = Duration(seconds: 60);
    if (stored.accessTokenExpiresAt.isAfter(DateTime.now().add(refreshBuffer))) {
      return stored.accessToken;
    }

    try {
      final result = await _api.refresh(stored.refreshToken);
      await _tokens.save(
        accessToken: result.accessToken,
        accessTokenExpiresAt: result.accessTokenExpiresAt,
        refreshToken: result.refreshToken,
        userId: stored.userId,
      );
      return result.accessToken;
    } catch (_) {
      await _tokens.clear();
      notifyListeners();
      return null;
    }
  }

  /// The signed-in user's id, if any — does not attempt a refresh, just reads what's stored.
  Future<String?> currentUserId() async => (await _tokens.read())?.userId;

  Future<void> signOut() async {
    final stored = await _tokens.read();
    if (stored != null) {
      try {
        await _api.logout(stored.accessToken).timeout(const Duration(seconds: 5));
      } catch (_) {
        // best-effort — still clear locally below
      }
    }
    await _tokens.clear();
    notifyListeners();
  }
}
