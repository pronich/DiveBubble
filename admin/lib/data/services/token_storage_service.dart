import 'package:web/web.dart' as web;

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

/// Uses `window.localStorage`, not `flutter_secure_storage` — the latter's web `write()` was observed hanging indefinitely on `admin.divebubble.io` (2026-07-20), and it offered little real security anyway since it stores its own encryption key alongside the encrypted values in the same browser storage.
class TokenStorageService {
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
    final storage = web.window.localStorage;
    storage.setItem(_kAccessToken, accessToken);
    storage.setItem(_kAccessTokenExpiresAt, accessTokenExpiresAt.toIso8601String());
    storage.setItem(_kRefreshToken, refreshToken);
    storage.setItem(_kUserId, userId);
  }

  Future<StoredAuthTokens?> read() async {
    final storage = web.window.localStorage;
    final accessToken = storage.getItem(_kAccessToken);
    final expiresAtRaw = storage.getItem(_kAccessTokenExpiresAt);
    final refreshToken = storage.getItem(_kRefreshToken);
    final userId = storage.getItem(_kUserId);
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

  Future<void> clear() async {
    final storage = web.window.localStorage;
    storage.removeItem(_kAccessToken);
    storage.removeItem(_kAccessTokenExpiresAt);
    storage.removeItem(_kRefreshToken);
    storage.removeItem(_kUserId);
  }
}
