// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transport_offer_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransportOfferApiModel {

 String get id; String get tripId; String get userId; String get type; int? get seats; String? get details; DateTime get createdAt; int get joinedCount; bool get joined;
/// Create a copy of TransportOfferApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportOfferApiModelCopyWith<TransportOfferApiModel> get copyWith => _$TransportOfferApiModelCopyWithImpl<TransportOfferApiModel>(this as TransportOfferApiModel, _$identity);

  /// Serializes this TransportOfferApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportOfferApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joinedCount, joinedCount) || other.joinedCount == joinedCount)&&(identical(other.joined, joined) || other.joined == joined));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,type,seats,details,createdAt,joinedCount,joined);

@override
String toString() {
  return 'TransportOfferApiModel(id: $id, tripId: $tripId, userId: $userId, type: $type, seats: $seats, details: $details, createdAt: $createdAt, joinedCount: $joinedCount, joined: $joined)';
}


}

/// @nodoc
abstract mixin class $TransportOfferApiModelCopyWith<$Res>  {
  factory $TransportOfferApiModelCopyWith(TransportOfferApiModel value, $Res Function(TransportOfferApiModel) _then) = _$TransportOfferApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, String type, int? seats, String? details, DateTime createdAt, int joinedCount, bool joined
});




}
/// @nodoc
class _$TransportOfferApiModelCopyWithImpl<$Res>
    implements $TransportOfferApiModelCopyWith<$Res> {
  _$TransportOfferApiModelCopyWithImpl(this._self, this._then);

  final TransportOfferApiModel _self;
  final $Res Function(TransportOfferApiModel) _then;

/// Create a copy of TransportOfferApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? type = null,Object? seats = freezed,Object? details = freezed,Object? createdAt = null,Object? joinedCount = null,Object? joined = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,seats: freezed == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedCount: null == joinedCount ? _self.joinedCount : joinedCount // ignore: cast_nullable_to_non_nullable
as int,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TransportOfferApiModel].
extension TransportOfferApiModelPatterns on TransportOfferApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransportOfferApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransportOfferApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransportOfferApiModel value)  $default,){
final _that = this;
switch (_that) {
case _TransportOfferApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransportOfferApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _TransportOfferApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt,  int joinedCount,  bool joined)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransportOfferApiModel() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt,_that.joinedCount,_that.joined);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt,  int joinedCount,  bool joined)  $default,) {final _that = this;
switch (_that) {
case _TransportOfferApiModel():
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt,_that.joinedCount,_that.joined);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  String type,  int? seats,  String? details,  DateTime createdAt,  int joinedCount,  bool joined)?  $default,) {final _that = this;
switch (_that) {
case _TransportOfferApiModel() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.type,_that.seats,_that.details,_that.createdAt,_that.joinedCount,_that.joined);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransportOfferApiModel implements TransportOfferApiModel {
  const _TransportOfferApiModel({required this.id, required this.tripId, required this.userId, required this.type, this.seats, this.details, required this.createdAt, this.joinedCount = 0, this.joined = false});
  factory _TransportOfferApiModel.fromJson(Map<String, dynamic> json) => _$TransportOfferApiModelFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  String type;
@override final  int? seats;
@override final  String? details;
@override final  DateTime createdAt;
@override@JsonKey() final  int joinedCount;
@override@JsonKey() final  bool joined;

/// Create a copy of TransportOfferApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransportOfferApiModelCopyWith<_TransportOfferApiModel> get copyWith => __$TransportOfferApiModelCopyWithImpl<_TransportOfferApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransportOfferApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransportOfferApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.seats, seats) || other.seats == seats)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joinedCount, joinedCount) || other.joinedCount == joinedCount)&&(identical(other.joined, joined) || other.joined == joined));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,type,seats,details,createdAt,joinedCount,joined);

@override
String toString() {
  return 'TransportOfferApiModel(id: $id, tripId: $tripId, userId: $userId, type: $type, seats: $seats, details: $details, createdAt: $createdAt, joinedCount: $joinedCount, joined: $joined)';
}


}

/// @nodoc
abstract mixin class _$TransportOfferApiModelCopyWith<$Res> implements $TransportOfferApiModelCopyWith<$Res> {
  factory _$TransportOfferApiModelCopyWith(_TransportOfferApiModel value, $Res Function(_TransportOfferApiModel) _then) = __$TransportOfferApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, String type, int? seats, String? details, DateTime createdAt, int joinedCount, bool joined
});




}
/// @nodoc
class __$TransportOfferApiModelCopyWithImpl<$Res>
    implements _$TransportOfferApiModelCopyWith<$Res> {
  __$TransportOfferApiModelCopyWithImpl(this._self, this._then);

  final _TransportOfferApiModel _self;
  final $Res Function(_TransportOfferApiModel) _then;

/// Create a copy of TransportOfferApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? type = null,Object? seats = freezed,Object? details = freezed,Object? createdAt = null,Object? joinedCount = null,Object? joined = null,}) {
  return _then(_TransportOfferApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,seats: freezed == seats ? _self.seats : seats // ignore: cast_nullable_to_non_nullable
as int?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedCount: null == joinedCount ? _self.joinedCount : joinedCount // ignore: cast_nullable_to_non_nullable
as int,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
