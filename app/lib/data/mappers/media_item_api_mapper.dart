import '../../domain/entities/media_item.dart';
import '../models/media_item_api_model.dart';
import 'chat_message_api_mapper.dart';

extension MediaItemApiMapper on MediaItemApiModel {
  MediaItem toDomain() => MediaItem(
        messageId: messageId,
        userId: userId,
        createdAt: createdAt,
        attachment: attachment.toDomain(),
      );
}
