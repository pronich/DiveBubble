// Trimmed to just what the account footer/avatar needs to display — admin/ has no profile
// editing screen yet (see CLAUDE.md's Business/dive centers section, "personal profile"
// deferred). Plain class, not freezed: two fields don't justify a build_runner step.
class MyProfile {
  const MyProfile({this.displayName, this.avatarUrl});

  final String? displayName;
  final String? avatarUrl;
}
