import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

/// Web-only variant of app/'s AuthRepository — a single Google Web OAuth client plays both
/// roles here (the client Google issues the token to, and the token's audience), since
/// there's no separate native app identity to keep distinct the way iOS needs one. Same
/// backend contract (`POST /auth/google` etc.) and token-refresh behavior otherwise.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required this.googleWebClientId,
    required AuthApiService apiService,
    required TokenStorageService tokenStorage,
  }) : _api = apiService,
       _tokens = tokenStorage;

  final String googleWebClientId;
  final AuthApiService _api;
  final TokenStorageService _tokens;

  bool _googleInitialized = false;

  /// Must resolve before LoginPage renders Google's own sign-in button (the web platform
  /// doesn't support the imperative `authenticate()` call app/ uses on mobile — see
  /// GoogleSignIn.supportsAuthenticate()'s doc comment — so the button widget itself, via
  /// google_sign_in_web's renderButton(), is the only entry point into the flow here).
  Future<void> ensureInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(clientId: googleWebClientId);
    _googleInitialized = true;
  }

  /// The stream LoginPage listens to for the result of a click on the rendered button —
  /// there's no other way to observe a web sign-in completing.
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents => GoogleSignIn.instance.authenticationEvents;

  /// Exchanges an already-authenticated Google account's ID token with the backend and
  /// persists the resulting session. Throws with a message suitable to show the user on failure.
  Future<SignInResult> completeSignIn(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token');
    }

    final result = await _api.signInWithGoogle(idToken);
    return _persistAuthResult(result);
  }

  /// Requests a magic-link email for passwordless login — alongside Google, not replacing
  /// it. See AuthApiService.startEmailLogin's own doc comment for where the link points.
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
        await _api.logout(stored.accessToken);
      } catch (_) {
        // best-effort — still clear locally below
      }
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    notifyListeners();
  }
}
