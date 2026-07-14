import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';

/// Wraps the Google Sign-In SDK + backend token exchange + secure token storage.
class AuthRepository {
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
  /// Returns the signed-in user id; throws with a message suitable to show the user on failure.
  Future<String> signInWithGoogle() async {
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
    return result.userId;
  }
}
