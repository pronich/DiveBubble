// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Profile {

 String get id; String? get displayName; String? get avatarUrl; String? get location; String? get bio; int get diveCount; String? get certificationLevel; String? get certificationAgency; String? get certificationNumber; String? get certificationPhotoUrl; bool get certificationVerified; String get languages; DateTime get memberSince; bool get isProductObserver;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.diveCount, diveCount) || other.diveCount == diveCount)&&(identical(other.certificationLevel, certificationLevel) || other.certificationLevel == certificationLevel)&&(identical(other.certificationAgency, certificationAgency) || other.certificationAgency == certificationAgency)&&(identical(other.certificationNumber, certificationNumber) || other.certificationNumber == certificationNumber)&&(identical(other.certificationPhotoUrl, certificationPhotoUrl) || other.certificationPhotoUrl == certificationPhotoUrl)&&(identical(other.certificationVerified, certificationVerified) || other.certificationVerified == certificationVerified)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.isProductObserver, isProductObserver) || other.isProductObserver == isProductObserver));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,location,bio,diveCount,certificationLevel,certificationAgency,certificationNumber,certificationPhotoUrl,certificationVerified,languages,memberSince,isProductObserver);

@override
String toString() {
  return 'Profile(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, location: $location, bio: $bio, diveCount: $diveCount, certificationLevel: $certificationLevel, certificationAgency: $certificationAgency, certificationNumber: $certificationNumber, certificationPhotoUrl: $certificationPhotoUrl, certificationVerified: $certificationVerified, languages: $languages, memberSince: $memberSince, isProductObserver: $isProductObserver)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String? displayName, String? avatarUrl, String? location, String? bio, int diveCount, String? certificationLevel, String? certificationAgency, String? certificationNumber, String? certificationPhotoUrl, bool certificationVerified, String languages, DateTime memberSince, bool isProductObserver
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? bio = freezed,Object? diveCount = null,Object? certificationLevel = freezed,Object? certificationAgency = freezed,Object? certificationNumber = freezed,Object? certificationPhotoUrl = freezed,Object? certificationVerified = null,Object? languages = null,Object? memberSince = null,Object? isProductObserver = null,}) {
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
as DateTime,isProductObserver: null == isProductObserver ? _self.isProductObserver : isProductObserver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince,  bool isProductObserver)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince,_that.isProductObserver);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince,  bool isProductObserver)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince,_that.isProductObserver);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? displayName,  String? avatarUrl,  String? location,  String? bio,  int diveCount,  String? certificationLevel,  String? certificationAgency,  String? certificationNumber,  String? certificationPhotoUrl,  bool certificationVerified,  String languages,  DateTime memberSince,  bool isProductObserver)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.location,_that.bio,_that.diveCount,_that.certificationLevel,_that.certificationAgency,_that.certificationNumber,_that.certificationPhotoUrl,_that.certificationVerified,_that.languages,_that.memberSince,_that.isProductObserver);case _:
  return null;

}
}

}

/// @nodoc


class _Profile implements Profile {
  const _Profile({required this.id, this.displayName, this.avatarUrl, this.location, this.bio, this.diveCount = 0, this.certificationLevel, this.certificationAgency, this.certificationNumber, this.certificationPhotoUrl, this.certificationVerified = false, this.languages = '', required this.memberSince, this.isProductObserver = false});
  

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
@override@JsonKey() final  bool isProductObserver;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.location, location) || other.location == location)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.diveCount, diveCount) || other.diveCount == diveCount)&&(identical(other.certificationLevel, certificationLevel) || other.certificationLevel == certificationLevel)&&(identical(other.certificationAgency, certificationAgency) || other.certificationAgency == certificationAgency)&&(identical(other.certificationNumber, certificationNumber) || other.certificationNumber == certificationNumber)&&(identical(other.certificationPhotoUrl, certificationPhotoUrl) || other.certificationPhotoUrl == certificationPhotoUrl)&&(identical(other.certificationVerified, certificationVerified) || other.certificationVerified == certificationVerified)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.isProductObserver, isProductObserver) || other.isProductObserver == isProductObserver));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,location,bio,diveCount,certificationLevel,certificationAgency,certificationNumber,certificationPhotoUrl,certificationVerified,languages,memberSince,isProductObserver);

@override
String toString() {
  return 'Profile(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, location: $location, bio: $bio, diveCount: $diveCount, certificationLevel: $certificationLevel, certificationAgency: $certificationAgency, certificationNumber: $certificationNumber, certificationPhotoUrl: $certificationPhotoUrl, certificationVerified: $certificationVerified, languages: $languages, memberSince: $memberSince, isProductObserver: $isProductObserver)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String? displayName, String? avatarUrl, String? location, String? bio, int diveCount, String? certificationLevel, String? certificationAgency, String? certificationNumber, String? certificationPhotoUrl, bool certificationVerified, String languages, DateTime memberSince, bool isProductObserver
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? location = freezed,Object? bio = freezed,Object? diveCount = null,Object? certificationLevel = freezed,Object? certificationAgency = freezed,Object? certificationNumber = freezed,Object? certificationPhotoUrl = freezed,Object? certificationVerified = null,Object? languages = null,Object? memberSince = null,Object? isProductObserver = null,}) {
  return _then(_Profile(
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
as DateTime,isProductObserver: null == isProductObserver ? _self.isProductObserver : isProductObserver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
