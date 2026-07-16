import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAuthTokens {
  const StoredAuthTokens({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final String userId;
}

/// Persists real auth tokens in the platform keychain/keystore — unlike the anonymous stub id
/// (`UserIdentityService`, plain `shared_preferences`), these are sensitive and must be encrypted at rest.
class TokenStorageService {
  static const _storage = FlutterSecureStorage();
  static const _kAccessToken = 'auth_access_token';
  static const _kAccessTokenExpiresAt = 'auth_access_token_expires_at';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';

  Future<void> save({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kAccessTokenExpiresAt, value: accessTokenExpiresAt.toIso8601String()),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kUserId, value: userId),
    ]);
  }

  Future<StoredAuthTokens?> read() async {
    final values = await Future.wait([
      _storage.read(key: _kAccessToken),
      _storage.read(key: _kAccessTokenExpiresAt),
      _storage.read(key: _kRefreshToken),
      _storage.read(key: _kUserId),
    ]);
    final accessToken = values[0];
    final expiresAtRaw = values[1];
    final refreshToken = values[2];
    final userId = values[3];
    if (accessToken == null || expiresAtRaw == null || refreshToken == null || userId == null) {
      return null;
    }
    return StoredAuthTokens(
      accessToken: accessToken,
      accessTokenExpiresAt: DateTime.parse(expiresAtRaw),
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<void> clear() => _storage.deleteAll();
}
