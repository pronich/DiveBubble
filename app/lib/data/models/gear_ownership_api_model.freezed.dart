// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_ownership_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearOwnershipApiModel {

 String get itemKey; String get status; DateTime get updatedAt;
/// Create a copy of GearOwnershipApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearOwnershipApiModelCopyWith<GearOwnershipApiModel> get copyWith => _$GearOwnershipApiModelCopyWithImpl<GearOwnershipApiModel>(this as GearOwnershipApiModel, _$identity);

  /// Serializes this GearOwnershipApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearOwnershipApiModel&&(identical(other.itemKey, itemKey) || other.itemKey == itemKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemKey,status,updatedAt);

@override
String toString() {
  return 'GearOwnershipApiModel(itemKey: $itemKey, status: $status, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GearOwnershipApiModelCopyWith<$Res>  {
  factory $GearOwnershipApiModelCopyWith(GearOwnershipApiModel value, $Res Function(GearOwnershipApiModel) _then) = _$GearOwnershipApiModelCopyWithImpl;
@useResult
$Res call({
 String itemKey, String status, DateTime updatedAt
});




}
/// @nodoc
class _$GearOwnershipApiModelCopyWithImpl<$Res>
    implements $GearOwnershipApiModelCopyWith<$Res> {
  _$GearOwnershipApiModelCopyWithImpl(this._self, this._then);

  final GearOwnershipApiModel _self;
  final $Res Function(GearOwnershipApiModel) _then;

/// Create a copy of GearOwnershipApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemKey = null,Object? status = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
itemKey: null == itemKey ? _self.itemKey : itemKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GearOwnershipApiModel].
extension GearOwnershipApiModelPatterns on GearOwnershipApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearOwnershipApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearOwnershipApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearOwnershipApiModel value)  $default,){
final _that = this;
switch (_that) {
case _GearOwnershipApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearOwnershipApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _GearOwnershipApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemKey,  String status,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearOwnershipApiModel() when $default != null:
return $default(_that.itemKey,_that.status,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemKey,  String status,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GearOwnershipApiModel():
return $default(_that.itemKey,_that.status,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemKey,  String status,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GearOwnershipApiModel() when $default != null:
return $default(_that.itemKey,_that.status,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearOwnershipApiModel implements GearOwnershipApiModel {
  const _GearOwnershipApiModel({required this.itemKey, required this.status, required this.updatedAt});
  factory _GearOwnershipApiModel.fromJson(Map<String, dynamic> json) => _$GearOwnershipApiModelFromJson(json);

@override final  String itemKey;
@override final  String status;
@override final  DateTime updatedAt;

/// Create a copy of GearOwnershipApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearOwnershipApiModelCopyWith<_GearOwnershipApiModel> get copyWith => __$GearOwnershipApiModelCopyWithImpl<_GearOwnershipApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearOwnershipApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearOwnershipApiModel&&(identical(other.itemKey, itemKey) || other.itemKey == itemKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemKey,status,updatedAt);

@override
String toString() {
  return 'GearOwnershipApiModel(itemKey: $itemKey, status: $status, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GearOwnershipApiModelCopyWith<$Res> implements $GearOwnershipApiModelCopyWith<$Res> {
  factory _$GearOwnershipApiModelCopyWith(_GearOwnershipApiModel value, $Res Function(_GearOwnershipApiModel) _then) = __$GearOwnershipApiModelCopyWithImpl;
@override @useResult
$Res call({
 String itemKey, String status, DateTime updatedAt
});




}
/// @nodoc
class __$GearOwnershipApiModelCopyWithImpl<$Res>
    implements _$GearOwnershipApiModelCopyWith<$Res> {
  __$GearOwnershipApiModelCopyWithImpl(this._self, this._then);

  final _GearOwnershipApiModel _self;
  final $Res Function(_GearOwnershipApiModel) _then;

/// Create a copy of GearOwnershipApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemKey = null,Object? status = null,Object? updatedAt = null,}) {
  return _then(_GearOwnershipApiModel(
itemKey: null == itemKey ? _self.itemKey : itemKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
