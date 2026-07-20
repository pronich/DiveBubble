import 'package:flutter/foundation.dart';
import 'package:google_identity_services_web/id.dart' as gis;

import '../services/auth_api_service.dart';
import '../services/google_identity_service.dart';
import '../services/token_storage_service.dart';

/// Result of a successful sign-in — isNewUser isn't acted on here the way app/'s
/// LoginSheet uses it (there's no personal-profile onboarding in admin/), but it's kept
/// on the result for parity with the mobile client's AuthApiService/backend contract.
class SignInResult {
  const SignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

/// Web-only variant of app/'s AuthRepository. Google Sign-In goes through
/// [GoogleIdentityService] (a thin wrapper directly over the plain
/// `google_identity_services_web` JS-interop library) rather than the
/// `google_sign_in`/`google_sign_in_web` packages — see that class's own doc comment for
/// the production incident (2026-07-20) that motivated this. Email/passwordless
/// (startEmailLogin/completeEmailLogin) is unaffected and works either way.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required this.googleWebClientId,
    required AuthApiService apiService,
    required TokenStorageService tokenStorage,
    GoogleIdentityService? googleIdentityService,
  }) : _api = apiService,
       _tokens = tokenStorage,
       googleIdentity = googleIdentityService ?? GoogleIdentityService();

  final String googleWebClientId;
  final AuthApiService _api;
  final TokenStorageService _tokens;

  /// Exposed (not private) so LoginPage/CustomGoogleButton can call ensureLoaded() and
  /// renderButton() directly — this repository only owns the backend token-exchange half.
  final GoogleIdentityService googleIdentity;

  /// Loads the GIS script (if not already) and registers the one-time credential callback.
  /// Safe to call every time LoginPage mounts — both steps are idempotent internally.
  Future<void> ensureGoogleReady() async {
    await googleIdentity.ensureLoaded();
    googleIdentity.initialize(clientId: googleWebClientId, onCredential: _handleGoogleCredential);
  }

  SignInResult? _pendingResult;
  Object? _pendingError;
  void Function(SignInResult)? _onGoogleSignIn;
  void Function(Object)? _onGoogleError;

  /// LoginPage listens for the *next* credential via this — GIS's own callback fires
  /// independently of any particular widget's lifetime, so there's no Future to just
  /// await from a button tap the way a normal imperative sign-in call would give you.
  void listenForGoogleSignIn({required void Function(SignInResult) onSignedIn, required void Function(Object error) onError}) {
    _onGoogleSignIn = onSignedIn;
    _onGoogleError = onError;
    // A credential may have arrived (e.g. an auto-select) before this listener was
    // attached — deliver it now rather than dropping it.
    if (_pendingResult != null) {
      onSignedIn(_pendingResult!);
      _pendingResult = null;
    } else if (_pendingError != null) {
      onError(_pendingError!);
      _pendingError = null;
    }
  }

  void stopListeningForGoogleSignIn() {
    _onGoogleSignIn = null;
    _onGoogleError = null;
  }

  Future<void> _handleGoogleCredential(String idToken) async {
    try {
      final result = await _api.signInWithGoogle(idToken);
      final signInResult = await _persistAuthResult(result);
      if (_onGoogleSignIn != null) {
        _onGoogleSignIn!(signInResult);
      } else {
        _pendingResult = signInResult;
      }
    } catch (e) {
      if (_onGoogleError != null) {
        _onGoogleError!(e);
      } else {
        _pendingError = e;
      }
    }
  }

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
    // Best-effort — prevents GIS auto-selecting the same Google account again silently on
    // the next visit to the login page. A no-op if GIS was never initialized this session
    // (e.g. the diver only ever used email), which is fine — nothing to disable.
    try {
      gis.id.disableAutoSelect();
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    notifyListeners();
  }
}
