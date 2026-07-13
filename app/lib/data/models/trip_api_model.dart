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
  }) = _TripApiModel;

  factory TripApiModel.fromJson(Map<String, dynamic> json) =>
      _$TripApiModelFromJson(json);
}
