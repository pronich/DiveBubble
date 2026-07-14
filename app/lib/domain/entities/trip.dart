import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String title,
    required String location,
    required DateTime startTime,
    required bool joined,
    String? creatorUserId,
    @Default(0) int participantCount,
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
    String? photoUrl, // unused until real photo upload/storage exists
  }) = _Trip;
}
