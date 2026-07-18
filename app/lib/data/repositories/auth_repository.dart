import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';

/// A random string sent to Apple (as its SHA-256 hex digest) and to our own backend (raw) —
/// the backend re-hashes it and checks it against the identity token's own nonce claim, which
/// is how Sign in with Apple defends against a stolen/replayed token being reused.
String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String _sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();

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

  /// Runs the native Sign in with Apple flow and exchanges the resulting identity token with
  /// the backend. email/givenName/familyName only ever come back non-null on a diver's very
  /// first authorization ever — later sign-ins omit them, which is fine: the backend only
  /// seeds the user row from these hints on account creation (see LoginOrRegister), never
  /// overwrites on later logins, so there's nothing for this method to cache/persist locally.
  Future<SignInResult> signInWithApple() async {
    final rawNonce = _generateNonce();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: _sha256Hex(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Sign-in cancelled');
      }
      throw Exception(e.message);
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Apple did not return an identity token');
    }

    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    final result = await _api.signInWithApple(
      identityToken: identityToken,
      nonce: rawNonce,
      email: credential.email,
      fullName: fullName.isEmpty ? null : fullName,
    );
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

  /// Permanently anonymizes the account server-side. Unlike [signOut], the backend call is
  /// NOT best-effort — local state is only cleared once it genuinely succeeds, so a failure
  /// propagates to the caller and the session stays intact (nothing to silently recover from
  /// if the account wasn't actually deleted).
  Future<void> deleteAccount() async {
    final accessToken = await getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Not signed in');
    }
    await _api.deleteAccount(accessToken);

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // best-effort — the account is already gone server-side either way
    }
    await _tokens.clear();
    notifyListeners();
  }
}
