import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_reaction.dart';
import '../models/chat_attachment_api_model.dart';
import '../models/chat_message_api_model.dart';
import '../models/chat_reaction_api_model.dart';

extension ChatAttachmentApiMapper on ChatAttachmentApiModel {
  ChatAttachment toDomain() => ChatAttachment(
        url: url,
        type: type,
        filename: filename,
        sizeBytes: sizeBytes,
        durationSeconds: durationSeconds,
      );
}

extension ChatReactionApiMapper on ChatReactionApiModel {
  ChatReaction toDomain() => ChatReaction(count: count, reactedByMe: reactedByMe);
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
        reactions: reactions.map((emoji, r) => MapEntry(emoji, r.toDomain())),
      );
}
