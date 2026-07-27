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
    // 'user' for a normal message; a system kind (e.g. 'feedback_prompt') renders as a
    // centered row instead of a bubble — see ChatView's _SystemMessageRow.
    @Default('user') String kind,
    // Per-viewer: has the current user already submitted feedback for this trip? Only
    // meaningful when kind is 'feedback_prompt'.
    @Default(false) bool feedbackProvided,
  }) = _ChatMessage;
}
