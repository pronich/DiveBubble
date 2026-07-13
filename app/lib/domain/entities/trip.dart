import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String title,
    required String location,
    required DateTime startTime,
  }) = _Trip;
}
