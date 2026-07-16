// Plain class, not freezed — same pragmatic call as MyProfile/DiveCenterMember.
class ChatMessage {
  const ChatMessage({required this.id, required this.tripId, required this.userId, required this.body, required this.createdAt});

  final String id;
  final String tripId;
  final String userId;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
