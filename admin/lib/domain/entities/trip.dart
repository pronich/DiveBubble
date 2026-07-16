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
    // Business fields — always present for a trip created from admin/, since admin never
    // creates an individual trip. Not yet read by app/'s own Trip entity (see CLAUDE.md's
    // Business/dive centers section) — that's a separate, still-pending piece of work.
    String? diveCenterId,
    int? priceMinor,
    @Default('DKK') String currency,
    // The trip's own external checkout page — distinct from the dive center's general
    // website (see CLAUDE.md's Booking Code flow section).
    String? bookingUrl,
  }) = _Trip;
}
