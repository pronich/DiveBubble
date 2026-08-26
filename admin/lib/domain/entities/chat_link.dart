// One URL extracted from a chat message's text (the Links tab) — read-only, server-derived.
class ChatLink {
  const ChatLink({
    required this.messageId,
    required this.userId,
    required this.url,
    required this.createdAt,
  });

  final String messageId;
  final String userId;
  final String url;
  final DateTime createdAt;

  factory ChatLink.fromJson(Map<String, dynamic> json) => ChatLink(
        messageId: json['messageId'] as String,
        userId: json['userId'] as String,
        url: json['url'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
