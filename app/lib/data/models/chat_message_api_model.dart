import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_api_model.freezed.dart';
part 'chat_message_api_model.g.dart';

@freezed
abstract class ChatMessageApiModel with _$ChatMessageApiModel {
  const factory ChatMessageApiModel({
    required String id,
    required String tripId,
    required String userId,
    required String body,
    required DateTime createdAt,
    @Default(false) bool isDiveCenterStaff,
    @Default(false) bool mentionsDiveCenter,
  }) = _ChatMessageApiModel;

  factory ChatMessageApiModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageApiModelFromJson(json);
}
