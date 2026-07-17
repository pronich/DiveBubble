// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripApiModel _$TripApiModelFromJson(Map<String, dynamic> json) =>
    _TripApiModel(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      joined: json['joined'] as bool,
      creatorUserId: json['creatorUserId'] as String?,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      hasUnreadMention: json['hasUnreadMention'] as bool? ?? false,
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?,
      meetingPoint: json['meetingPoint'] as String?,
      diveCountMin: (json['diveCountMin'] as num?)?.toInt(),
      diveCountMax: (json['diveCountMax'] as num?)?.toInt(),
      depthMinM: (json['depthMinM'] as num?)?.toInt(),
      depthMaxM: (json['depthMaxM'] as num?)?.toInt(),
      minCertification: json['minCertification'] as String?,
      bookingCode: json['bookingCode'] as String?,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      bookingStatus: json['bookingStatus'] as String? ?? 'open',
      photoUrl: json['photoUrl'] as String?,
      diveCenterId: json['diveCenterId'] as String?,
      priceMinor: (json['priceMinor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'DKK',
      bookingUrl: json['bookingUrl'] as String?,
    );

Map<String, dynamic> _$TripApiModelToJson(_TripApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'location': instance.location,
      'startTime': instance.startTime.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'joined': instance.joined,
      'creatorUserId': instance.creatorUserId,
      'participantCount': instance.participantCount,
      'unreadCount': instance.unreadCount,
      'hasUnreadMention': instance.hasUnreadMention,
      'endDate': instance.endDate?.toIso8601String(),
      'description': instance.description,
      'meetingPoint': instance.meetingPoint,
      'diveCountMin': instance.diveCountMin,
      'diveCountMax': instance.diveCountMax,
      'depthMinM': instance.depthMinM,
      'depthMaxM': instance.depthMaxM,
      'minCertification': instance.minCertification,
      'bookingCode': instance.bookingCode,
      'maxParticipants': instance.maxParticipants,
      'bookingStatus': instance.bookingStatus,
      'photoUrl': instance.photoUrl,
      'diveCenterId': instance.diveCenterId,
      'priceMinor': instance.priceMinor,
      'currency': instance.currency,
      'bookingUrl': instance.bookingUrl,
    };
