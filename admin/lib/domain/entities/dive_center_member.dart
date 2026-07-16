// Plain classes, not freezed — small enough (and admin-only) that a build_runner step
// isn't worth it, same call as MyProfile.
class DiveCenterMember {
  const DiveCenterMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
    this.certificationLevel,
    this.email,
  });

  final String userId;
  final String role; // "owner" | "staff"
  final DateTime joinedAt;
  final String? displayName;
  final String? avatarUrl;
  final String? certificationLevel;
  final String? email;

  factory DiveCenterMember.fromJson(Map<String, dynamic> json) => DiveCenterMember(
        userId: json['userId'] as String,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        certificationLevel: json['certificationLevel'] as String?,
        email: json['email'] as String?,
      );
}

// Preview shown before actually adding someone — see
// DiveCenterApiService.searchMemberByEmail's own comment on why this is exact-email-only.
class MemberPreview {
  const MemberPreview({required this.userId, this.displayName, this.avatarUrl});

  final String userId;
  final String? displayName;
  final String? avatarUrl;

  factory MemberPreview.fromJson(Map<String, dynamic> json) => MemberPreview(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
