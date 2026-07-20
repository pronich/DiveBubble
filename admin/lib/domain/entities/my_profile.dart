// Plain class, not freezed: a handful of fields don't justify a build_runner step.
// Full parity with GET /me now (see AccountPage) — the account footer/chat-sender lookups
// still only ever read displayName/avatarUrl, the rest is unused there.
class MyProfile {
  const MyProfile({
    this.displayName,
    this.avatarUrl,
    this.location,
    this.bio,
    this.diveCount = 0,
    this.certificationLevel,
    this.certificationAgency,
    this.certificationNumber,
    this.languages = '',
    this.memberSince,
  });

  final String? displayName;
  final String? avatarUrl;
  final String? location;
  final String? bio;
  final int diveCount;
  final String? certificationLevel;
  final String? certificationAgency;
  final String? certificationNumber;
  final String languages;
  final DateTime? memberSince;
}
