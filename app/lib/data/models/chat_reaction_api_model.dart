import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_reaction_api_model.freezed.dart';
part 'chat_reaction_api_model.g.dart';

@freezed
abstract class ChatReactionApiModel with _$ChatReactionApiModel {
  const factory ChatReactionApiModel({required int count, required bool reactedByMe}) = _ChatReactionApiModel;

  factory ChatReactionApiModel.fromJson(Map<String, dynamic> json) => _$ChatReactionApiModelFromJson(json);
}
