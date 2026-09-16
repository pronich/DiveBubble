/// Lets callers distinguish "please sign in" from a generic network/server failure.
class AuthRequiredException implements Exception {
  const AuthRequiredException();

  @override
  String toString() => 'Sign in required';
}
