// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileApiModel {

 String get id; String? get displayName; String? get avatarUrl; String? get location; String? get bio; int get diveCount; String? get certificationLevel; String? get certificationAgency; String? get certificationNumber; String? get certificationPhotoUrl; bool get certificationVerified; String get languages; DateTime get memberSince;
/// Create a copy of ProfileApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileApiModelCopyWith<ProfileApiModel> get copyWith => _$ProfileApiModelCopyWithImpl<ProfileApiModel>(this as ProfileApiModel, _$identity);

  /// Serializes this ProfileApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.diveCount, diveCount) || other.diveCount == diveCount)&&(identical(other.certificationLevel, certificationLevel) || other.certificationLevel == certificationLevel)&&(identical(other.certificationAgency, certificationAgency) || other.certificationAgency == certificationAgency)&&(identical(other.certificationNumber, certificationNumber) || other.certificationNumber == certificationNumber)&&(identical(other.certificationPhotoUrl, certificationPhotoUrl) || other.certificationPhotoUrl == certificationPhotoUrl)&&(identical(other.certificationVerified, certificationVerified) || other.certificationVerified == certificationVerified)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,location,bio,diveCount,certificationLevel,certificationAgency,certificationNumber,certificationPhotoUrl,certificationVerified,languages,memberSince);

@override
String toString() {
  return 'ProfileApiModel(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, location: $location, bio: $bio, diveCount: $diveCount, certificationLevel: $certificationLevel, certificationAgency: $certificationAgency, certificationNumber: $certificationNumber, certificationPhotoUrl: $certificationPhotoUrl, certificationVerified: $certificationVerified, languages: $languages, memberSince: $memberSince)';
}


}

/// @nodoc
abstract mixin class $ProfileApiModelCopyWith<$Res>  {
  factory $ProfileApiModelCopyWith(ProfileApiModel value, $Res Function(ProfileApiModel) _then) = _$ProfileApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String? displayName, String? avatarUrl, String? location, String? bio, int diveCount, String? certificationLevel, String? certificationAgency, String? certificationNumber, String? certificationPhotoUrl, bool certificationVerified, String languages, DateTime memberSince
});




}
/// @nodoc
class _$ProfileApiModelCopyWithImpl<$Res>
    implements $ProfileApiModelCopyWith<$Res> {
  _$ProfileApiModelCopyWithImpl(this._self, this._then);

  final ProfileApiModel _self;
  final $Res Function(ProfileApiModel) _then;

/// Create a copy of ProfileApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? bio = freezed,Object? diveCount = null,Object? certificationLevel = freezed,Object? certificationAgency = freezed,Object? certificationNumber = freezed,Object? certificationPhotoUrl = freezed,Object? certificationVerified = null,Object? languages = null,Object? memberSince = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,diveCount: null == diveCount ? _self.diveCount : diveCount // ignore: cast_nullable_to_non_nullable
as int,certificationLevel: freezed == certificationLevel ? _self.certificationLevel : certificationLevel // ignore: cast_nullable_to_non_nullable
as String?,certificationAgency: freezed == certificationAgency ? _self.certificationAgency : certificationAgency // ignore: cast_nullable_to_non_nullable
as String?,certificationNumber: freezed == certificationNumber ? _self.certificationNumber : certificationNumber // ignore: cast_nullable_to_non_nullable
as String?,certificationPhotoUrl: freezed == certificationPhotoUrl ? _self.certificationPhotoUrl : certificationPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,certificationVerified: null == certificationVerified ? _self.certificationVerified : certificationVerified // ignore: cast_nullable_to_non_nullable
as bool,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as String,memberSince: null == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileApiModel].
extension ProfileApiModelPatterns on ProfileApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileApiModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileApiModel() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince)  $default,) {final _that = this;
switch (_that) {
case _ProfileApiModel():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince)?  $default,) {final _that = this;
switch (_that) {
case _ProfileApiModel() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileApiModel implements ProfileApiModel {
  const _ProfileApiModel({required this.id, this.displayName, this.avatarUrl, this.location, this.bio, this.diveCount = 0, this.certificationLevel, this.certificationAgency, this.certificationNumber, this.certificationPhotoUrl, this.certificationVerified = false, this.languages = '', required this.memberSince});
  factory _ProfileApiModel.fromJson(Map<String, dynamic> json) => _$ProfileApiModelFromJson(json);

@override final  String id;
@override final  String? displayName;
@override final  String? avatarUrl;
@override final  String? location;
@override final  String? bio;
@override@JsonKey() final  int diveCount;
@override final  String? certificationLevel;
@override final  String? certificationAgency;
@override final  String? certificationNumber;
@override final  String? certificationPhotoUrl;
@override@JsonKey() final  bool certificationVerified;
@override@JsonKey() final  String languages;
@override final  DateTime memberSince;

/// Create a copy of ProfileApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileApiModelCopyWith<_ProfileApiModel> get copyWith => __$ProfileApiModelCopyWithImpl<_ProfileApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.diveCount, diveCount) || other.diveCount == diveCount)&&(identical(other.certificationLevel, certificationLevel) || other.certificationLevel == certificationLevel)&&(identical(other.certificationAgency, certificationAgency) || other.certificationAgency == certificationAgency)&&(identical(other.certificationNumber, certificationNumber) || other.certificationNumber == certificationNumber)&&(identical(other.certificationPhotoUrl, certificationPhotoUrl) || other.certificationPhotoUrl == certificationPhotoUrl)&&(identical(other.certificationVerified, certificationVerified) || other.certificationVerified == certificationVerified)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,location,bio,diveCount,certificationLevel,certificationAgency,certificationNumber,certificationPhotoUrl,certificationVerified,languages,memberSince);

@override
String toString() {
  return 'ProfileApiModel(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, location: $location, bio: $bio, diveCount: $diveCount, certificationLevel: $certificationLevel, certificationAgency: $certificationAgency, certificationNumber: $certificationNumber, certificationPhotoUrl: $certificationPhotoUrl, certificationVerified: $certificationVerified, languages: $languages, memberSince: $memberSince)';
}


}

/// @nodoc
abstract mixin class _$ProfileApiModelCopyWith<$Res> implements $ProfileApiModelCopyWith<$Res> {
  factory _$ProfileApiModelCopyWith(_ProfileApiModel value, $Res Function(_ProfileApiModel) _then) = __$ProfileApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? displayName, String? avatarUrl, String? location, String? bio, int diveCount, String? certificationLevel, String? certificationAgency, String? certificationNumber, String? certificationPhotoUrl, bool certificationVerified, String languages, DateTime memberSince
});




}
/// @nodoc
class __$ProfileApiModelCopyWithImpl<$Res>
    implements _$ProfileApiModelCopyWith<$Res> {
  __$ProfileApiModelCopyWithImpl(this._self, this._then);

  final _ProfileApiModel _self;
  final $Res Function(_ProfileApiModel) _then;

/// Create a copy of ProfileApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? bio = freezed,Object? diveCount = null,Object? certificationLevel = freezed,Object? certificationAgency = freezed,Object? certificationNumber = freezed,Object? certificationPhotoUrl = freezed,Object? certificationVerified = null,Object? languages = null,Object? memberSince = null,}) {
  return _then(_ProfileApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,diveCount: null == diveCount ? _self.diveCount : diveCount // ignore: cast_nullable_to_non_nullable
as int,certificationLevel: freezed == certificationLevel ? _self.certificationLevel : certificationLevel // ignore: cast_nullable_to_non_nullable
as String?,certificationAgency: freezed == certificationAgency ? _self.certificationAgency : certificationAgency // ignore: cast_nullable_to_non_nullable
as String?,certificationNumber: freezed == certificationNumber ? _self.certificationNumber : certificationNumber // ignore: cast_nullable_to_non_nullable
as String?,certificationPhotoUrl: freezed == certificationPhotoUrl ? _self.certificationPhotoUrl : certificationPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,certificationVerified: null == certificationVerified ? _self.certificationVerified : certificationVerified // ignore: cast_nullable_to_non_nullable
as bool,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as String,memberSince: null == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
