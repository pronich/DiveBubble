// Plain class, not freezed — same pragmatic call as ChatMessage/MyProfile.
class TransportOffer {
  const TransportOffer({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.type,
    this.seats,
    this.details,
    required this.createdAt,
    this.joinedCount = 0,
    this.isDiveCenterStaff = false,
  });

  final String id;
  final String tripId;
  final String userId;
  final String type;
  final int? seats;
  final String? details;
  final DateTime createdAt;
  final int joinedCount;

  // True when the creator is a member of this trip's dive center — mirrors
  // ChatMessage.isDiveCenterStaff.
  final bool isDiveCenterStaff;

  factory TransportOffer.fromJson(Map<String, dynamic> json) => TransportOffer(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        type: json['type'] as String,
        seats: json['seats'] as int?,
        details: json['details'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        joinedCount: json['joinedCount'] as int? ?? 0,
        isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
      );
}
