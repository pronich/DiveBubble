import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_api_model.freezed.dart';
part 'trip_api_model.g.dart';

@freezed
abstract class TripApiModel with _$TripApiModel {
  const factory TripApiModel({
    required String id,
    required String title,
    required String location,
    required DateTime startTime,
    required DateTime createdAt,
    required bool joined,
    String? creatorUserId,
    @Default(0) int participantCount,
    @Default(0) int unreadCount,
    @Default(false) bool hasTransportAlert,
    DateTime? endDate,
    String? description,
    String? meetingPoint,
    int? diveCountMin,
    int? diveCountMax,
    int? depthMinM,
    int? depthMaxM,
    String? minCertification,
    String? bookingCode,
    int? maxParticipants,
    @Default('open') String bookingStatus,
    String? photoUrl,
    String? diveCenterId,
    int? priceMinor,
    @Default('DKK') String currency,
    String? bookingUrl,
    double? latitude,
    double? longitude,
  }) = _TripApiModel;

  factory TripApiModel.fromJson(Map<String, dynamic> json) =>
      _$TripApiModelFromJson(json);
}
