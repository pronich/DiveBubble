// Plain class, not freezed — same pragmatic call as MyProfile/DiveCenterMember.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.isDiveCenterStaff = false,
  });

  final String id;
  final String tripId;
  final String userId;
  final String body;
  final DateTime createdAt;

  // True when this sender is a member of the trip's dive center — used to tell a
  // teammate's reply apart from a diver's in BubblesPage (see _MessageRow).
  final bool isDiveCenterStaff;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
      );
}
