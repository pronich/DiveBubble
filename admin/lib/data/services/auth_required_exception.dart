/// Distinguishes "please sign in" (no valid access token) from a generic network/server failure.
class AuthRequiredException implements Exception {
  const AuthRequiredException();

  @override
  String toString() => 'Sign in required';
}
