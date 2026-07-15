// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_ownership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GearOwnership {

 String get itemKey; String get status;
/// Create a copy of GearOwnership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearOwnershipCopyWith<GearOwnership> get copyWith => _$GearOwnershipCopyWithImpl<GearOwnership>(this as GearOwnership, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearOwnership&&(identical(other.itemKey, itemKey) || other.itemKey == itemKey)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,itemKey,status);

@override
String toString() {
  return 'GearOwnership(itemKey: $itemKey, status: $status)';
}


}

/// @nodoc
abstract mixin class $GearOwnershipCopyWith<$Res>  {
  factory $GearOwnershipCopyWith(GearOwnership value, $Res Function(GearOwnership) _then) = _$GearOwnershipCopyWithImpl;
@useResult
$Res call({
 String itemKey, String status
});




}
/// @nodoc
class _$GearOwnershipCopyWithImpl<$Res>
    implements $GearOwnershipCopyWith<$Res> {
  _$GearOwnershipCopyWithImpl(this._self, this._then);

  final GearOwnership _self;
  final $Res Function(GearOwnership) _then;

/// Create a copy of GearOwnership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemKey = null,Object? status = null,}) {
  return _then(_self.copyWith(
itemKey: null == itemKey ? _self.itemKey : itemKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GearOwnership].
extension GearOwnershipPatterns on GearOwnership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearOwnership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearOwnership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearOwnership value)  $default,){
final _that = this;
switch (_that) {
case _GearOwnership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearOwnership value)?  $default,){
final _that = this;
switch (_that) {
case _GearOwnership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemKey,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearOwnership() when $default != null:
return $default(_that.itemKey,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemKey,  String status)  $default,) {final _that = this;
switch (_that) {
case _GearOwnership():
return $default(_that.itemKey,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemKey,  String status)?  $default,) {final _that = this;
switch (_that) {
case _GearOwnership() when $default != null:
return $default(_that.itemKey,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _GearOwnership implements GearOwnership {
  const _GearOwnership({required this.itemKey, required this.status});
  

@override final  String itemKey;
@override final  String status;

/// Create a copy of GearOwnership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearOwnershipCopyWith<_GearOwnership> get copyWith => __$GearOwnershipCopyWithImpl<_GearOwnership>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearOwnership&&(identical(other.itemKey, itemKey) || other.itemKey == itemKey)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,itemKey,status);

@override
String toString() {
  return 'GearOwnership(itemKey: $itemKey, status: $status)';
}


}

/// @nodoc
abstract mixin class _$GearOwnershipCopyWith<$Res> implements $GearOwnershipCopyWith<$Res> {
  factory _$GearOwnershipCopyWith(_GearOwnership value, $Res Function(_GearOwnership) _then) = __$GearOwnershipCopyWithImpl;
@override @useResult
$Res call({
 String itemKey, String status
});




}
/// @nodoc
class __$GearOwnershipCopyWithImpl<$Res>
    implements _$GearOwnershipCopyWith<$Res> {
  __$GearOwnershipCopyWithImpl(this._self, this._then);

  final _GearOwnership _self;
  final $Res Function(_GearOwnership) _then;

/// Create a copy of GearOwnership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemKey = null,Object? status = null,}) {
  return _then(_GearOwnership(
itemKey: null == itemKey ? _self.itemKey : itemKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
