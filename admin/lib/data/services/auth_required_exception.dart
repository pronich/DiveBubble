/// Thrown by API services when an action requires authentication but no valid access token
/// is available (never signed in, or the session couldn't be refreshed) — callers use this to
/// distinguish "please sign in" from a generic network/server failure.
class AuthRequiredException implements Exception {
  const AuthRequiredException();

  @override
  String toString() => 'Sign in required';
}
