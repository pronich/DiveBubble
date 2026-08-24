import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_attachment_api_model.dart';
import '../models/chat_message_api_model.dart';

extension ChatAttachmentApiMapper on ChatAttachmentApiModel {
  ChatAttachment toDomain() => ChatAttachment(
        url: url,
        type: type,
        filename: filename,
        sizeBytes: sizeBytes,
        durationSeconds: durationSeconds,
      );
}

extension ChatMessageApiMapper on ChatMessageApiModel {
  ChatMessage toDomain() => ChatMessage(
        id: id,
        tripId: tripId,
        userId: userId,
        body: body,
        createdAt: createdAt,
        isDiveCenterStaff: isDiveCenterStaff,
        mentionsDiveCenter: mentionsDiveCenter,
        kind: kind,
        feedbackProvided: feedbackProvided,
        attachments: attachments.map((a) => a.toDomain()).toList(),
        replyToId: replyToId,
        deletedAt: deletedAt,
      );
}
