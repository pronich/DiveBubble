import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_attachment.dart';
import 'chat_reaction.dart';

part 'chat_message.freezed.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String tripId,
    required String userId,
    required String body,
    required DateTime createdAt,
    // True only when this sender is an actual dive-center member, not just "this trip was organized by a dive center".
    @Default(false) bool isDiveCenterStaff,
    // Diver-armed "@DiveCenter" flag on this message, business trips only; Stage 2 push will gate staff notifications on it instead of pushing every message.
    @Default(false) bool mentionsDiveCenter,
    // 'user' for a normal message; a system kind like 'feedback_prompt' renders as a centered row instead of a bubble.
    @Default('user') String kind,
    // Per-viewer; only meaningful when kind is 'feedback_prompt'.
    @Default(false) bool feedbackProvided,
    // `body` doubles as a shared caption when attachments are also present.
    @Default([]) List<ChatAttachment> attachments,
    // Optimistic local echo shown the instant "send" is tapped, replaced once the server confirms it; never true for a message from the REST list or realtime.
    @Default(false) bool isPending,
    // The client resolves this against the already-loaded message list rather than the server denormalizing sender/body onto every reply.
    String? replyToId,
    // Non-null means deleted — body/attachment are already blanked server-side by the time this is set, so the bubble just renders a placeholder.
    DateTime? deletedAt,
    // Keyed by emoji; a realtime "reaction_update" event patches only each entry's count in place, while reactedByMe only ever changes via this viewer's own PUT/DELETE call.
    @Default({}) Map<String, ChatReaction> reactions,
  }) = _ChatMessage;
}
