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

/// Persists auth tokens in `window.localStorage` — deliberately not
/// `flutter_secure_storage` (2026-07-20): its web backend encrypts values via the Web
/// Crypto API before storing them, but was observed hanging indefinitely on
/// `admin.divebubble.io` specifically (a backend login would fully succeed — user created,
/// tokens issued — while the app stayed stuck on its loading screen forever, because the
/// `write()` call into that layer never resolved). Raw `crypto.subtle` calls tested fine in
/// isolation in the same browser/domain, so the hang is presumably somewhere in that
/// package's own Dart/JS-interop plumbing, not Web Crypto itself — not something worth
/// chasing further here. Note this is a smaller loss of "security at rest" than it sounds:
/// flutter_secure_storage's own web implementation stores its encryption key alongside the
/// encrypted values in the same browser storage anyway, so it was never protecting against
/// anything beyond casual inspection of localStorage to begin with.
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
