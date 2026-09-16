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
    // A dissolved transport offer this diver had joined; cleared by visiting the Transport tab (TransportViewModel.checkAlert).
    @Default(false) bool hasTransportAlert,
    // Same idea as hasTransportAlert, for a dissolved buddy group; cleared by visiting the Buddy tab.
    @Default(false) bool hasBuddyAlert,
    // Distinct from the two Alert fields above (a dissolved car/group) — survives just opening the Bubble, only clears once the tab is actually visited.
    @Default(false) bool hasUnreadTransportMessages,
    @Default(false) bool hasUnreadBuddyMessages,
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
    // Fixed at creation, no edit path — excluded from Explore either way, and join goes through the same booking-code gate as a business trip.
    @Default(false) bool isPrivate,
    String? photoUrl,
    // Set when this trip was created from admin/, not the individual organizer flow.
    String? diveCenterId,
    int? priceMinor,
    @Default('DKK') String currency,
    // Where a diver actually pays to get a bookingCode, since a business trip can't be joined directly.
    String? bookingUrl,
    // Best-effort forward-geocode of location/meetingPoint at creation time, powering Explore's "Nearest" sort; null if geocoding failed.
    double? latitude,
    double? longitude,
  }) = _Trip;
}
