import 'chat_attachment.dart';

/// One per attachment, not per message, since a message can carry several now (ChatMessage.attachments).
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
