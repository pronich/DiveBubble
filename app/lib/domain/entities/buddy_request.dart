import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_request.freezed.dart';

@freezed
abstract class BuddyRequest with _$BuddyRequest {
  const factory BuddyRequest({
    required String id,
    required String tripId,
    required String userId,
    required DateTime createdAt,
    @Default(0) int joinedCount,
    @Default(false) bool joined,
    // Sent by the backend rather than hardcoded here, even though it's fixed today (buddy.MaxMembers server-side).
    @Default(3) int maxMembers,
    // Enriched server-side (routes_buddy.go's toBuddyRequestResponse) so the list needs no per-row profile fetch.
    @Default('') String creatorName,
    String? creatorLevel,
    @Default(0) int creatorDiveCount,
    // Distinct from BuddyViewModel.hasAlert (a dissolved group you'd joined) — this is ordinary new activity in a chat you're still part of.
    @Default(false) bool hasUnreadMessages,
  }) = _BuddyRequest;
}
