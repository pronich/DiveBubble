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
    // Set together or not at all — a message carries at most one attachment (photo or PDF),
    // with `body` doubling as its caption when both are present.
    String? attachmentUrl,
    String? attachmentType, // 'image' | 'pdf'
    String? attachmentFilename,
    int? attachmentSizeBytes,
    // Optimistic local echo, shown the instant "send" is tapped and replaced once the server
    // confirms it (see ChatViewModel.send/uploadAndSend) — never true for a message that came
    // from the REST list or realtime.
    @Default(false) bool isPending,
    // Set only on a pending attachment message, before attachmentUrl exists — lets the bubble
    // render the picked file immediately (thumbnail/filename) while the upload is in flight.
    String? localAttachmentPath,
    // Id of the message this one replies to, if any — the client resolves it against the
    // already-loaded message list rather than the server denormalizing sender/body onto every
    // reply (see ChatViewModel).
    String? replyToId,
    // Non-null means this message was deleted — body/attachment are already blanked by the
    // server by the time this is set (see backend's toMessageResponse), so the bubble just
    // renders a placeholder instead of trying to hide real content client-side.
    DateTime? deletedAt,
  }) = _ChatMessage;
}
