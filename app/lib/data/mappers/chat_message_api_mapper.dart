import '../../domain/entities/chat_message.dart';
import '../models/chat_message_api_model.dart';

extension ChatMessageApiMapper on ChatMessageApiModel {
  ChatMessage toDomain() => ChatMessage(
        id: id,
        tripId: tripId,
        userId: userId,
        body: body,
        createdAt: createdAt,
        isDiveCenterStaff: isDiveCenterStaff,
        mentionsDiveCenter: mentionsDiveCenter,
      );
}
