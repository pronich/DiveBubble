import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';

/// Result of a successful sign-in — isNewUser lets the caller drop a brand-new account
/// straight into Edit Profile instead of an empty screen.
class SignInResult {
  const SignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

/// Wraps the Google Sign-In SDK + backend token exchange + secure token storage.
/// A [ChangeNotifier] so screens built before a login-gate fires (e.g. the Trips tab, mounted
/// while still anonymous) can react once sign-in completes elsewhere in the app.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required this.googleIosClientId,
    required this.googleServerClientId,
    required AuthApiService apiService,
    required TokenStorageService tokenStorage,
  }) : _api = apiService,
       _tokens = tokenStorage;

  final String googleIosClientId;
  final String googleServerClientId;
  final AuthApiService _api;
  final TokenStorageService _tokens;

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: googleIosClientId,
      // Web client id — the ID token's audience the backend verifies against, not the iOS app identifier.
      serverClientId: googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Runs the Google sign-in flow and exchanges the resulting ID token with the backend.
  /// Throws with a message suitable to show the user on failure.
  Future<SignInResult> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Sign-in cancelled');
      }
      throw Exception(e.description ?? 'Google sign-in failed');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token');
    }

    final result = await _api.signInWithGoogle(idToken);
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
  /// close to it). Returns null if there's no session at all, or refreshing failed (revoked/expired
  /// refresh token) — either way, any stored tokens are cleared so the caller can prompt login.
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

  /// "Dive out" — revokes the session on the backend (best-effort) and signs out of the native
  /// Google session too, so a later login shows the account picker again instead of silently
  /// resuming. Local tokens are always cleared regardless of whether the network calls succeed.
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
