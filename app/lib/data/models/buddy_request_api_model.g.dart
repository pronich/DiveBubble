// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_request_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyRequestApiModel _$BuddyRequestApiModelFromJson(
  Map<String, dynamic> json,
) => _BuddyRequestApiModel(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  joinedCount: (json['joinedCount'] as num?)?.toInt() ?? 0,
  joined: json['joined'] as bool? ?? false,
  maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 3,
  creatorName: json['creatorName'] as String? ?? '',
  creatorLevel: json['creatorLevel'] as String?,
  creatorDiveCount: (json['creatorDiveCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BuddyRequestApiModelToJson(
  _BuddyRequestApiModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'userId': instance.userId,
  'createdAt': instance.createdAt.toIso8601String(),
  'joinedCount': instance.joinedCount,
  'joined': instance.joined,
  'maxMembers': instance.maxMembers,
  'creatorName': instance.creatorName,
  'creatorLevel': instance.creatorLevel,
  'creatorDiveCount': instance.creatorDiveCount,
};
