/// Supplies a currently-valid access token (refreshing if needed), or null if signed out.
typedef AccessTokenProvider = Future<String?> Function();
