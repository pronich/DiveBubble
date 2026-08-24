import 'chat_attachment.dart';

/// One grid entry for Bubble Info's Media/Files tabs — one per attachment, not per message (a
/// message can carry several now, see ChatMessage.attachments). Mirrors backend's
/// mediaItemResponse (routes_message.go).
class MediaItem {
  const MediaItem({
    required this.messageId,
    required this.userId,
    required this.createdAt,
    required this.attachment,
  });

  final String messageId;
  final String userId;
  final DateTime createdAt;
  final ChatAttachment attachment;
}
