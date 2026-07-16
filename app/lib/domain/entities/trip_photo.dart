import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_photo.freezed.dart';

@freezed
abstract class TripPhoto with _$TripPhoto {
  const factory TripPhoto({
    required String id,
    required String url,
    required int position,
  }) = _TripPhoto;
}
