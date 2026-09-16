import 'package:flutter/foundation.dart';
import 'package:google_identity_services_web/id.dart' as gis;

import '../services/auth_api_service.dart';
import '../services/google_identity_service.dart';
import '../services/token_storage_service.dart';

/// isNewUser is unused here (no onboarding in admin/) — kept only for parity with the mobile AuthApiService/backend contract.
class SignInResult {
  const SignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

/// Web-only variant of app/'s AuthRepository — Google Sign-In goes through [GoogleIdentityService] instead of google_sign_in/google_sign_in_web after a production incident (see that class's doc comment).
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

  /// Exposed (not private) so LoginPage/CustomGoogleButton can call ensureLoaded()/renderButton() directly — this repository only owns the backend token-exchange half.
  final GoogleIdentityService googleIdentity;

  /// Safe to call on every LoginPage mount — loading the script and registering the callback are both idempotent.
  Future<void> ensureGoogleReady() async {
    await googleIdentity.ensureLoaded();
    googleIdentity.initialize(clientId: googleWebClientId, onCredential: _handleGoogleCredential);
  }

  SignInResult? _pendingResult;
  Object? _pendingError;
  void Function(SignInResult)? _onGoogleSignIn;
  void Function(Object)? _onGoogleError;

  /// GIS's callback fires independently of any widget's lifetime, so there's no Future to await from a button tap — LoginPage listens for the next credential via this instead.
  void listenForGoogleSignIn({required void Function(SignInResult) onSignedIn, required void Function(Object error) onError}) {
    _onGoogleSignIn = onSignedIn;
    _onGoogleError = onError;
    // A credential may have arrived (e.g. an auto-select) before this listener attached — deliver it now instead of dropping it.
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

  /// Requests a magic-link email for passwordless login — see AuthApiService.startEmailLogin for where the link points.
  Future<void> startEmailLogin(String email) => _api.startEmailLogin(email);

  /// Completes a magic-link login — called by MagicLinkGate with the token+email it read off this app's own URL query params on load.
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

  /// Returns a valid access token, refreshing if needed; returns null (clearing stored tokens) if there's no session or the refresh fails, so the caller can prompt login.
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
    // Best-effort: prevents GIS from silently auto-selecting the same account next visit; a no-op if GIS was never initialized this session.
    try {
      gis.id.disableAutoSelect();
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    notifyListeners();
  }
}
