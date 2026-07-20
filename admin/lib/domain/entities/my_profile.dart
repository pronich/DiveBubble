// Plain class, not freezed: a handful of fields don't justify a build_runner step.
// location/bio are only ever read/written by the personal-info onboarding step and a
// future full profile-editing screen — the account footer/chat-sender lookups only ever
// use displayName/avatarUrl.
class MyProfile {
  const MyProfile({this.displayName, this.avatarUrl, this.location, this.bio});

  final String? displayName;
  final String? avatarUrl;
  final String? location;
  final String? bio;
}
