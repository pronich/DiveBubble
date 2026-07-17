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
    // A dissolved transport offer this diver had joined — see CLAUDE.md's Leave Bubble
    // section. Cleared by visiting the Transport tab (see TransportViewModel.checkAlert).
    @Default(false) bool hasTransportAlert,
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
    // Business fields — set when this trip was created from admin/, not the individual
    // organizer flow. See CLAUDE.md's Business/dive centers section.
    String? diveCenterId,
    int? priceMinor,
    @Default('DKK') String currency,
    // The trip's own external checkout page — where a diver actually pays to get a
    // bookingCode, since a business trip can't be joined directly (see TripPage's
    // organizer-card-adjacent Book-now button and CLAUDE.md's Booking Code flow section).
    String? bookingUrl,
  }) = _Trip;
}
