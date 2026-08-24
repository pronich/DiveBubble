import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_reaction.freezed.dart';

/// One emoji's aggregate on a message (see ChatMessage.reactions, keyed by emoji) — Count is
/// the same for every viewer, reactedByMe is per-viewer (whether the current user is the one
/// who set it). Mirrors backend's reactionSummaryResponse.
@freezed
abstract class ChatReaction with _$ChatReaction {
  const factory ChatReaction({required int count, required bool reactedByMe}) = _ChatReaction;
}
