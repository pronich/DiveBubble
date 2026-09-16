import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String title,
    required String location,
    required DateTime startTime,
    required bool joined,
    String? creatorUserId,
    @Default(0) int participantCount,
    @Default(0) int unreadCount,
    // Only ever true for a business trip — backs the Bubbles-sidebar mention dot (see BubblesViewModel.hasUnreadMention).
    @Default(false) bool hasUnreadMention,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    String? bookingCode,
    int? maxParticipants,
    @Default('open') String bookingStatus,
    String? photoUrl,
    // Business fields — always present since admin/ never creates an individual trip; not yet read by app/'s own Trip entity.
    String? diveCenterId,
    int? priceMinor,
    @Default('DKK') String currency,
    // The trip's own external checkout page — distinct from the dive center's general website.
    String? bookingUrl,
  }) = _Trip;
}
