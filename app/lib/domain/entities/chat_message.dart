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
    // True only when this specific sender is an actual member of the trip's dive center —
    // not just "this trip was organized by a dive center" (see ChatView._MessageRow, which
    // used to apply the "Name | Dive Center" label to every non-own message regardless).
    @Default(false) bool isDiveCenterStaff,
    // Diver-armed "@DiveCenter" flag on this specific message — see ChatView's mention
    // chip. Only ever true on a business trip; Stage 2 push will gate staff notifications
    // on it instead of pushing every message.
    @Default(false) bool mentionsDiveCenter,
  }) = _ChatMessage;
}
