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
    // Whole-group size cap including the creator — sent by the backend rather than
    // hardcoded here, even though it's fixed today (see buddy.MaxMembers server-side).
    @Default(3) int maxMembers,
    // Enriched server-side so the list is scannable at a glance with no per-row profile
    // fetch — see routes_buddy.go's toBuddyRequestResponse.
    @Default('') String creatorName,
    String? creatorLevel,
    @Default(0) int creatorDiveCount,
  }) = _BuddyRequest;
}
