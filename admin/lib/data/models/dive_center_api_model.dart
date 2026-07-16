import 'package:freezed_annotation/freezed_annotation.dart';

part 'dive_center_api_model.freezed.dart';
part 'dive_center_api_model.g.dart';

@freezed
abstract class DiveCenterApiModel with _$DiveCenterApiModel {
  const factory DiveCenterApiModel({
    required String id,
    required String name,
    String? location,
    String? description,
    String? logoUrl,
    String? agency,
    String? agencyDetail,
    @Default('') String languages,
    String? website,
    String? phone,
    String? email,
    required DateTime createdAt,
    String? role,
  }) = _DiveCenterApiModel;

  factory DiveCenterApiModel.fromJson(Map<String, dynamic> json) => _$DiveCenterApiModelFromJson(json);
}
