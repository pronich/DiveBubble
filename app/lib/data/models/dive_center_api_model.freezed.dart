// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dive_center_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiveCenterApiModel {

 String get id; String get name; String? get location; String? get description; String? get logoUrl; String? get agency; String? get agencyDetail; String get languages; String? get website; String? get phone; String? get email; DateTime get createdAt; String? get role;
/// Create a copy of DiveCenterApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiveCenterApiModelCopyWith<DiveCenterApiModel> get copyWith => _$DiveCenterApiModelCopyWithImpl<DiveCenterApiModel>(this as DiveCenterApiModel, _$identity);

  /// Serializes this DiveCenterApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiveCenterApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.agencyDetail, agencyDetail) || other.agencyDetail == agencyDetail)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.website, website) || other.website == website)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,description,logoUrl,agency,agencyDetail,languages,website,phone,email,createdAt,role);

@override
String toString() {
  return 'DiveCenterApiModel(id: $id, name: $name, location: $location, description: $description, logoUrl: $logoUrl, agency: $agency, agencyDetail: $agencyDetail, languages: $languages, website: $website, phone: $phone, email: $email, createdAt: $createdAt, role: $role)';
}


}

/// @nodoc
abstract mixin class $DiveCenterApiModelCopyWith<$Res>  {
  factory $DiveCenterApiModelCopyWith(DiveCenterApiModel value, $Res Function(DiveCenterApiModel) _then) = _$DiveCenterApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? location, String? description, String? logoUrl, String? agency, String? agencyDetail, String languages, String? website, String? phone, String? email, DateTime createdAt, String? role
});




}
/// @nodoc
class _$DiveCenterApiModelCopyWithImpl<$Res>
    implements $DiveCenterApiModelCopyWith<$Res> {
  _$DiveCenterApiModelCopyWithImpl(this._self, this._then);

  final DiveCenterApiModel _self;
  final $Res Function(DiveCenterApiModel) _then;

/// Create a copy of DiveCenterApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? location = freezed,Object? description = freezed,Object? logoUrl = freezed,Object? agency = freezed,Object? agencyDetail = freezed,Object? languages = null,Object? website = freezed,Object? phone = freezed,Object? email = freezed,Object? createdAt = null,Object? role = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,agency: freezed == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String?,agencyDetail: freezed == agencyDetail ? _self.agencyDetail : agencyDetail // ignore: cast_nullable_to_non_nullable
as String?,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as String,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiveCenterApiModel].
extension DiveCenterApiModelPatterns on DiveCenterApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiveCenterApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiveCenterApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiveCenterApiModel value)  $default,){
final _that = this;
switch (_that) {
case _DiveCenterApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiveCenterApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _DiveCenterApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? location,  String? description,  String? logoUrl,  String? agency,  String? agencyDetail,  String languages,  String? website,  String? phone,  String? email,  DateTime createdAt,  String? role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiveCenterApiModel() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.description,_that.logoUrl,_that.agency,_that.agencyDetail,_that.languages,_that.website,_that.phone,_that.email,_that.createdAt,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? location,  String? description,  String? logoUrl,  String? agency,  String? agencyDetail,  String languages,  String? website,  String? phone,  String? email,  DateTime createdAt,  String? role)  $default,) {final _that = this;
switch (_that) {
case _DiveCenterApiModel():
return $default(_that.id,_that.name,_that.location,_that.description,_that.logoUrl,_that.agency,_that.agencyDetail,_that.languages,_that.website,_that.phone,_that.email,_that.createdAt,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? location,  String? description,  String? logoUrl,  String? agency,  String? agencyDetail,  String languages,  String? website,  String? phone,  String? email,  DateTime createdAt,  String? role)?  $default,) {final _that = this;
switch (_that) {
case _DiveCenterApiModel() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.description,_that.logoUrl,_that.agency,_that.agencyDetail,_that.languages,_that.website,_that.phone,_that.email,_that.createdAt,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiveCenterApiModel implements DiveCenterApiModel {
  const _DiveCenterApiModel({required this.id, required this.name, this.location, this.description, this.logoUrl, this.agency, this.agencyDetail, this.languages = '', this.website, this.phone, this.email, required this.createdAt, this.role});
  factory _DiveCenterApiModel.fromJson(Map<String, dynamic> json) => _$DiveCenterApiModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? location;
@override final  String? description;
@override final  String? logoUrl;
@override final  String? agency;
@override final  String? agencyDetail;
@override@JsonKey() final  String languages;
@override final  String? website;
@override final  String? phone;
@override final  String? email;
@override final  DateTime createdAt;
@override final  String? role;

/// Create a copy of DiveCenterApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiveCenterApiModelCopyWith<_DiveCenterApiModel> get copyWith => __$DiveCenterApiModelCopyWithImpl<_DiveCenterApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiveCenterApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiveCenterApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.agencyDetail, agencyDetail) || other.agencyDetail == agencyDetail)&&(identical(other.languages, languages) || other.languages == languages)&&(identical(other.website, website) || other.website == website)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,description,logoUrl,agency,agencyDetail,languages,website,phone,email,createdAt,role);

@override
String toString() {
  return 'DiveCenterApiModel(id: $id, name: $name, location: $location, description: $description, logoUrl: $logoUrl, agency: $agency, agencyDetail: $agencyDetail, languages: $languages, website: $website, phone: $phone, email: $email, createdAt: $createdAt, role: $role)';
}


}

/// @nodoc
abstract mixin class _$DiveCenterApiModelCopyWith<$Res> implements $DiveCenterApiModelCopyWith<$Res> {
  factory _$DiveCenterApiModelCopyWith(_DiveCenterApiModel value, $Res Function(_DiveCenterApiModel) _then) = __$DiveCenterApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? location, String? description, String? logoUrl, String? agency, String? agencyDetail, String languages, String? website, String? phone, String? email, DateTime createdAt, String? role
});




}
/// @nodoc
class __$DiveCenterApiModelCopyWithImpl<$Res>
    implements _$DiveCenterApiModelCopyWith<$Res> {
  __$DiveCenterApiModelCopyWithImpl(this._self, this._then);

  final _DiveCenterApiModel _self;
  final $Res Function(_DiveCenterApiModel) _then;

/// Create a copy of DiveCenterApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? location = freezed,Object? description = freezed,Object? logoUrl = freezed,Object? agency = freezed,Object? agencyDetail = freezed,Object? languages = null,Object? website = freezed,Object? phone = freezed,Object? email = freezed,Object? createdAt = null,Object? role = freezed,}) {
  return _then(_DiveCenterApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,agency: freezed == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String?,agencyDetail: freezed == agencyDetail ? _self.agencyDetail : agencyDetail // ignore: cast_nullable_to_non_nullable
as String?,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as String,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
