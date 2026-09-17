import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';

/// Sent to Apple as its SHA-256 digest and to the backend raw, so the backend can re-hash and match it against the identity token's nonce claim to defend against token replay.
String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String _sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();

/// isNewUser lets the caller drop a brand-new account straight into Edit Profile instead of an empty screen.
class SignInResult {
  const SignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

/// A [ChangeNotifier] so screens mounted before a login-gate fires (e.g. the Trips tab while still anonymous) can react once sign-in completes elsewhere.
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

  /// email/givenName/familyName come back non-null only on a diver's very first Apple authorization; later sign-ins omit them, which is fine since the backend only seeds those fields on account creation.
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
      authorizationCode: credential.authorizationCode,
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

  /// Unlike admin/'s clicked-link flow, the code is typed back in by the diver, so there's no separate "consume a link" entry point needed.
  Future<void> startEmailLogin(String email) => _api.startEmailLogin(email);

  Future<SignInResult> verifyEmailLogin(String email, String code) async {
    final result = await _api.verifyEmailLogin(email, code);
    await _tokens.save(
      accessToken: result.accessToken,
      accessTokenExpiresAt: result.accessTokenExpiresAt,
      refreshToken: result.refreshToken,
      userId: result.userId,
    );
    notifyListeners();
    return SignInResult(userId: result.userId, isNewUser: result.isNewUser);
  }

  // Every API service shares this same getAccessToken callback, so a burst of concurrent calls around the token's expiry must not each fire their own refresh — the backend's refresh token is single-use, and a second concurrent use would look like theft and reject the request.
  Future<String?>? _refreshFuture;

  /// Returns null both when the refresh token is genuinely rejected (tokens cleared, caller should prompt login) and when the refresh request merely fails to go through (tokens left alone so the next call retries).
  Future<String?> getValidAccessToken() async {
    final stored = await _tokens.read();
    if (stored == null) return null;

    const refreshBuffer = Duration(seconds: 60);
    if (stored.accessTokenExpiresAt.isAfter(DateTime.now().add(refreshBuffer))) {
      return stored.accessToken;
    }

    return _refreshFuture ??= _refresh(stored).whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _refresh(StoredAuthTokens stored) async {
    try {
      final result = await _api.refresh(stored.refreshToken);
      await _tokens.save(
        accessToken: result.accessToken,
        accessTokenExpiresAt: result.accessTokenExpiresAt,
        refreshToken: result.refreshToken,
        userId: stored.userId,
      );
      return result.accessToken;
    } on RefreshRejectedException {
      await _tokens.clear();
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Does not attempt a refresh, just reads what's stored.
  Future<String?> currentUserId() async => (await _tokens.read())?.userId;

  /// Local tokens are always cleared regardless of whether the best-effort backend/Google sign-out calls succeed.
  Future<void> signOut() async {
    final stored = await _tokens.read();
    if (stored != null) {
      try {
        await _api.logout(stored.accessToken).timeout(const Duration(seconds: 5));
      } catch (_) {
        // best-effort — still clear locally below
      }
    }
    try {
      // Timeout needed: on an instance never initialize()'d (Apple/email sign-in never touches GoogleSignIn), signOut() hangs indefinitely instead of throwing.
      await GoogleSignIn.instance.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    notifyListeners();
  }

  /// Unlike [signOut], the backend call is NOT best-effort — local state is only cleared once it genuinely succeeds, so a failure leaves the session intact.
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
