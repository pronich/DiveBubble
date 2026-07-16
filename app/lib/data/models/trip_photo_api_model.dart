import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_photo_api_model.freezed.dart';
part 'trip_photo_api_model.g.dart';

@freezed
abstract class TripPhotoApiModel with _$TripPhotoApiModel {
  const factory TripPhotoApiModel({
    required String id,
    required String url,
    required int position,
  }) = _TripPhotoApiModel;

  factory TripPhotoApiModel.fromJson(Map<String, dynamic> json) =>
      _$TripPhotoApiModelFromJson(json);
}
