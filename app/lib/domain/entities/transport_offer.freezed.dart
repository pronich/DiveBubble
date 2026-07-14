// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransportOffer {

 String get id; String get tripId; String get userId; String get type; int? get seats; String? get details; DateTime get createdAt;
/// Create a copy of TransportOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportOfferCopyWith<TransportOffer> get copyWith => _$TransportOfferCopyWithImpl<TransportOffer>(this as TransportOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,type,seats,details,createdAt);

@override
String toString() {
  return 'TransportOffer(id: $id, tripId: $tripId, userId: $userId, type: $type, seats: $seats, details: $details, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TransportOfferCopyWith<$Res>  {
  factory $TransportOfferCopyWith(TransportOffer value, $Res Function(TransportOffer) _then) = _$TransportOfferCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, String type, int? seats, String? details, DateTime createdAt
});




}
/// @nodoc
class _$TransportOfferCopyWithImpl<$Res>
    implements $TransportOfferCopyWith<$Res> {
  _$TransportOfferCopyWithImpl(this._self, this._then);

  final TransportOffer _self;
  final $Res Function(TransportOffer) _then;

/// Create a copy of TransportOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? type = null,Object? seats = freezed,Object? details = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,seats: freezed == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TransportOffer].
extension TransportOfferPatterns on TransportOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransportOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransportOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransportOffer value)  $default,){
final _that = this;
switch (_that) {
case _TransportOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransportOffer value)?  $default,){
final _that = this;
switch (_that) {
case _TransportOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransportOffer() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TransportOffer():
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TransportOffer() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TransportOffer implements TransportOffer {
  const _TransportOffer({required this.id, required this.tripId, required this.userId, required this.type, this.seats, this.details, required this.createdAt});
  

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  String type;
@override final  int? seats;
@override final  String? details;
@override final  DateTime createdAt;

/// Create a copy of TransportOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransportOfferCopyWith<_TransportOffer> get copyWith => __$TransportOfferCopyWithImpl<_TransportOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransportOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,type,seats,details,createdAt);

@override
String toString() {
  return 'TransportOffer(id: $id, tripId: $tripId, userId: $userId, type: $type, seats: $seats, details: $details, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TransportOfferCopyWith<$Res> implements $TransportOfferCopyWith<$Res> {
  factory _$TransportOfferCopyWith(_TransportOffer value, $Res Function(_TransportOffer) _then) = __$TransportOfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, String type, int? seats, String? details, DateTime createdAt
});




}
/// @nodoc
class __$TransportOfferCopyWithImpl<$Res>
    implements _$TransportOfferCopyWith<$Res> {
  __$TransportOfferCopyWithImpl(this._self, this._then);

  final _TransportOffer _self;
  final $Res Function(_TransportOffer) _then;

/// Create a copy of TransportOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? type = null,Object? seats = freezed,Object? details = freezed,Object? createdAt = null,}) {
  return _then(_TransportOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,seats: freezed == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
