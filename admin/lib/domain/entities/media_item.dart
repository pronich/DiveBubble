// Plain class, same pragmatic call as ChatMessage/MyProfile — mirrors backend's
// mediaItemResponse (routes_message.go). One row per attachment, not per message.
class MediaItem {
  const MediaItem({
    required this.messageId,
    required this.userId,
    required this.createdAt,
    required this.url,
    required this.type,
    this.filename,
    this.sizeBytes,
    this.durationSeconds,
  });

  final String messageId;
  final String userId;
  final DateTime createdAt;
  final String url;
  final String type; // 'image' | 'video' | 'pdf'
  final String? filename;
  final int? sizeBytes;
  final int? durationSeconds;

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final attachment = json['attachment'] as Map<String, dynamic>;
    return MediaItem(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      url: attachment['url'] as String,
      type: attachment['type'] as String,
      filename: attachment['filename'] as String?,
      sizeBytes: attachment['sizeBytes'] as int?,
      durationSeconds: attachment['durationSeconds'] as int?,
    );
  }
}
