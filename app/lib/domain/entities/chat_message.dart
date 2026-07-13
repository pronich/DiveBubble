import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String tripId,
    required String userId,
    required String body,
    required DateTime createdAt,
  }) = _ChatMessage;
}
