// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'specialty_certification_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpecialtyCertificationApiModel {

 String get id; String get specialty; String? get customLabel; String? get agency; String? get certNumber; String? get photoUrl; bool get verified; DateTime get createdAt;
/// Create a copy of SpecialtyCertificationApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpecialtyCertificationApiModelCopyWith<SpecialtyCertificationApiModel> get copyWith => _$SpecialtyCertificationApiModelCopyWithImpl<SpecialtyCertificationApiModel>(this as SpecialtyCertificationApiModel, _$identity);

  /// Serializes this SpecialtyCertificationApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpecialtyCertificationApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.customLabel, customLabel) || other.customLabel == customLabel)&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.certNumber, certNumber) || other.certNumber == certNumber)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,specialty,customLabel,agency,certNumber,photoUrl,verified,createdAt);

@override
String toString() {
  return 'SpecialtyCertificationApiModel(id: $id, specialty: $specialty, customLabel: $customLabel, agency: $agency, certNumber: $certNumber, photoUrl: $photoUrl, verified: $verified, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SpecialtyCertificationApiModelCopyWith<$Res>  {
  factory $SpecialtyCertificationApiModelCopyWith(SpecialtyCertificationApiModel value, $Res Function(SpecialtyCertificationApiModel) _then) = _$SpecialtyCertificationApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String specialty, String? customLabel, String? agency, String? certNumber, String? photoUrl, bool verified, DateTime createdAt
});




}
/// @nodoc
class _$SpecialtyCertificationApiModelCopyWithImpl<$Res>
    implements $SpecialtyCertificationApiModelCopyWith<$Res> {
  _$SpecialtyCertificationApiModelCopyWithImpl(this._self, this._then);

  final SpecialtyCertificationApiModel _self;
  final $Res Function(SpecialtyCertificationApiModel) _then;

/// Create a copy of SpecialtyCertificationApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? specialty = null,Object? customLabel = freezed,Object? agency = freezed,Object? certNumber = freezed,Object? photoUrl = freezed,Object? verified = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,specialty: null == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String,customLabel: freezed == customLabel ? _self.customLabel : customLabel // ignore: cast_nullable_to_non_nullable
as String?,agency: freezed == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String?,certNumber: freezed == certNumber ? _self.certNumber : certNumber // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SpecialtyCertificationApiModel].
extension SpecialtyCertificationApiModelPatterns on SpecialtyCertificationApiModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpecialtyCertificationApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpecialtyCertificationApiModel value)  $default,){
final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpecialtyCertificationApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String specialty,  String? customLabel,  String? agency,  String? certNumber,  String? photoUrl,  bool verified,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel() when $default != null:
return $default(_that.id,_that.specialty,_that.customLabel,_that.agency,_that.certNumber,_that.photoUrl,_that.verified,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String specialty,  String? customLabel,  String? agency,  String? certNumber,  String? photoUrl,  bool verified,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel():
return $default(_that.id,_that.specialty,_that.customLabel,_that.agency,_that.certNumber,_that.photoUrl,_that.verified,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String specialty,  String? customLabel,  String? agency,  String? certNumber,  String? photoUrl,  bool verified,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SpecialtyCertificationApiModel() when $default != null:
return $default(_that.id,_that.specialty,_that.customLabel,_that.agency,_that.certNumber,_that.photoUrl,_that.verified,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpecialtyCertificationApiModel implements SpecialtyCertificationApiModel {
  const _SpecialtyCertificationApiModel({required this.id, required this.specialty, this.customLabel, this.agency, this.certNumber, this.photoUrl, this.verified = false, required this.createdAt});
  factory _SpecialtyCertificationApiModel.fromJson(Map<String, dynamic> json) => _$SpecialtyCertificationApiModelFromJson(json);

@override final  String id;
@override final  String specialty;
@override final  String? customLabel;
@override final  String? agency;
@override final  String? certNumber;
@override final  String? photoUrl;
@override@JsonKey() final  bool verified;
@override final  DateTime createdAt;

/// Create a copy of SpecialtyCertificationApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpecialtyCertificationApiModelCopyWith<_SpecialtyCertificationApiModel> get copyWith => __$SpecialtyCertificationApiModelCopyWithImpl<_SpecialtyCertificationApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpecialtyCertificationApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpecialtyCertificationApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.customLabel, customLabel) || other.customLabel == customLabel)&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.certNumber, certNumber) || other.certNumber == certNumber)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,specialty,customLabel,agency,certNumber,photoUrl,verified,createdAt);

@override
String toString() {
  return 'SpecialtyCertificationApiModel(id: $id, specialty: $specialty, customLabel: $customLabel, agency: $agency, certNumber: $certNumber, photoUrl: $photoUrl, verified: $verified, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SpecialtyCertificationApiModelCopyWith<$Res> implements $SpecialtyCertificationApiModelCopyWith<$Res> {
  factory _$SpecialtyCertificationApiModelCopyWith(_SpecialtyCertificationApiModel value, $Res Function(_SpecialtyCertificationApiModel) _then) = __$SpecialtyCertificationApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String specialty, String? customLabel, String? agency, String? certNumber, String? photoUrl, bool verified, DateTime createdAt
});




}
/// @nodoc
class __$SpecialtyCertificationApiModelCopyWithImpl<$Res>
    implements _$SpecialtyCertificationApiModelCopyWith<$Res> {
  __$SpecialtyCertificationApiModelCopyWithImpl(this._self, this._then);

  final _SpecialtyCertificationApiModel _self;
  final $Res Function(_SpecialtyCertificationApiModel) _then;

/// Create a copy of SpecialtyCertificationApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? specialty = null,Object? customLabel = freezed,Object? agency = freezed,Object? certNumber = freezed,Object? photoUrl = freezed,Object? verified = null,Object? createdAt = null,}) {
  return _then(_SpecialtyCertificationApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,specialty: null == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String,customLabel: freezed == customLabel ? _self.customLabel : customLabel // ignore: cast_nullable_to_non_nullable
as String?,agency: freezed == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String?,certNumber: freezed == certNumber ? _self.certNumber : certNumber // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
