import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_reaction.freezed.dart';

/// count is the same for every viewer; reactedByMe is per-viewer.
@freezed
abstract class ChatReaction with _$ChatReaction {
  const factory ChatReaction({required int count, required bool reactedByMe}) = _ChatReaction;
}
