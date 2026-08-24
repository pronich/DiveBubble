// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_reaction_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatReactionApiModel _$ChatReactionApiModelFromJson(
  Map<String, dynamic> json,
) => _ChatReactionApiModel(
  count: (json['count'] as num).toInt(),
  reactedByMe: json['reactedByMe'] as bool,
);

Map<String, dynamic> _$ChatReactionApiModelToJson(
  _ChatReactionApiModel instance,
) => <String, dynamic>{
  'count': instance.count,
  'reactedByMe': instance.reactedByMe,
};
