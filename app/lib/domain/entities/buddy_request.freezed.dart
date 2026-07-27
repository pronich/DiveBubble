// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BuddyRequest {

 String get id; String get tripId; String get userId; DateTime get createdAt; int get joinedCount; bool get joined;// Whole-group size cap including the creator — sent by the backend rather than
// hardcoded here, even though it's fixed today (see buddy.MaxMembers server-side).
 int get maxMembers;// Enriched server-side so the list is scannable at a glance with no per-row profile
// fetch — see routes_buddy.go's toBuddyRequestResponse.
 String get creatorName; String? get creatorLevel; int get creatorDiveCount;
/// Create a copy of BuddyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyRequestCopyWith<BuddyRequest> get copyWith => _$BuddyRequestCopyWithImpl<BuddyRequest>(this as BuddyRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joinedCount, joinedCount) || other.joinedCount == joinedCount)&&(identical(other.joined, joined) || other.joined == joined)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorLevel, creatorLevel) || other.creatorLevel == creatorLevel)&&(identical(other.creatorDiveCount, creatorDiveCount) || other.creatorDiveCount == creatorDiveCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,createdAt,joinedCount,joined,maxMembers,creatorName,creatorLevel,creatorDiveCount);

@override
String toString() {
  return 'BuddyRequest(id: $id, tripId: $tripId, userId: $userId, createdAt: $createdAt, joinedCount: $joinedCount, joined: $joined, maxMembers: $maxMembers, creatorName: $creatorName, creatorLevel: $creatorLevel, creatorDiveCount: $creatorDiveCount)';
}


}

/// @nodoc
abstract mixin class $BuddyRequestCopyWith<$Res>  {
  factory $BuddyRequestCopyWith(BuddyRequest value, $Res Function(BuddyRequest) _then) = _$BuddyRequestCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, DateTime createdAt, int joinedCount, bool joined, int maxMembers, String creatorName, String? creatorLevel, int creatorDiveCount
});




}
/// @nodoc
class _$BuddyRequestCopyWithImpl<$Res>
    implements $BuddyRequestCopyWith<$Res> {
  _$BuddyRequestCopyWithImpl(this._self, this._then);

  final BuddyRequest _self;
  final $Res Function(BuddyRequest) _then;

/// Create a copy of BuddyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? createdAt = null,Object? joinedCount = null,Object? joined = null,Object? maxMembers = null,Object? creatorName = null,Object? creatorLevel = freezed,Object? creatorDiveCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedCount: null == joinedCount ? _self.joinedCount : joinedCount // ignore: cast_nullable_to_non_nullable
as int,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorLevel: freezed == creatorLevel ? _self.creatorLevel : creatorLevel // ignore: cast_nullable_to_non_nullable
as String?,creatorDiveCount: null == creatorDiveCount ? _self.creatorDiveCount : creatorDiveCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyRequest].
extension BuddyRequestPatterns on BuddyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyRequest value)  $default,){
final _that = this;
switch (_that) {
case _BuddyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  DateTime createdAt,  int joinedCount,  bool joined,  int maxMembers,  String creatorName,  String? creatorLevel,  int creatorDiveCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyRequest() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.createdAt,_that.joinedCount,_that.joined,_that.maxMembers,_that.creatorName,_that.creatorLevel,_that.creatorDiveCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  DateTime createdAt,  int joinedCount,  bool joined,  int maxMembers,  String creatorName,  String? creatorLevel,  int creatorDiveCount)  $default,) {final _that = this;
switch (_that) {
case _BuddyRequest():
return $default(_that.id,_that.tripId,_that.userId,_that.createdAt,_that.joinedCount,_that.joined,_that.maxMembers,_that.creatorName,_that.creatorLevel,_that.creatorDiveCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  DateTime createdAt,  int joinedCount,  bool joined,  int maxMembers,  String creatorName,  String? creatorLevel,  int creatorDiveCount)?  $default,) {final _that = this;
switch (_that) {
case _BuddyRequest() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.createdAt,_that.joinedCount,_that.joined,_that.maxMembers,_that.creatorName,_that.creatorLevel,_that.creatorDiveCount);case _:
  return null;

}
}

}

/// @nodoc


class _BuddyRequest implements BuddyRequest {
  const _BuddyRequest({required this.id, required this.tripId, required this.userId, required this.createdAt, this.joinedCount = 0, this.joined = false, this.maxMembers = 3, this.creatorName = '', this.creatorLevel, this.creatorDiveCount = 0});
  

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  DateTime createdAt;
@override@JsonKey() final  int joinedCount;
@override@JsonKey() final  bool joined;
// Whole-group size cap including the creator — sent by the backend rather than
// hardcoded here, even though it's fixed today (see buddy.MaxMembers server-side).
@override@JsonKey() final  int maxMembers;
// Enriched server-side so the list is scannable at a glance with no per-row profile
// fetch — see routes_buddy.go's toBuddyRequestResponse.
@override@JsonKey() final  String creatorName;
@override final  String? creatorLevel;
@override@JsonKey() final  int creatorDiveCount;

/// Create a copy of BuddyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyRequestCopyWith<_BuddyRequest> get copyWith => __$BuddyRequestCopyWithImpl<_BuddyRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joinedCount, joinedCount) || other.joinedCount == joinedCount)&&(identical(other.joined, joined) || other.joined == joined)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&(identical(other.creatorName, creatorName) || other.creatorName == creatorName)&&(identical(other.creatorLevel, creatorLevel) || other.creatorLevel == creatorLevel)&&(identical(other.creatorDiveCount, creatorDiveCount) || other.creatorDiveCount == creatorDiveCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,createdAt,joinedCount,joined,maxMembers,creatorName,creatorLevel,creatorDiveCount);

@override
String toString() {
  return 'BuddyRequest(id: $id, tripId: $tripId, userId: $userId, createdAt: $createdAt, joinedCount: $joinedCount, joined: $joined, maxMembers: $maxMembers, creatorName: $creatorName, creatorLevel: $creatorLevel, creatorDiveCount: $creatorDiveCount)';
}


}

/// @nodoc
abstract mixin class _$BuddyRequestCopyWith<$Res> implements $BuddyRequestCopyWith<$Res> {
  factory _$BuddyRequestCopyWith(_BuddyRequest value, $Res Function(_BuddyRequest) _then) = __$BuddyRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, DateTime createdAt, int joinedCount, bool joined, int maxMembers, String creatorName, String? creatorLevel, int creatorDiveCount
});




}
/// @nodoc
class __$BuddyRequestCopyWithImpl<$Res>
    implements _$BuddyRequestCopyWith<$Res> {
  __$BuddyRequestCopyWithImpl(this._self, this._then);

  final _BuddyRequest _self;
  final $Res Function(_BuddyRequest) _then;

/// Create a copy of BuddyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? createdAt = null,Object? joinedCount = null,Object? joined = null,Object? maxMembers = null,Object? creatorName = null,Object? creatorLevel = freezed,Object? creatorDiveCount = null,}) {
  return _then(_BuddyRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedCount: null == joinedCount ? _self.joinedCount : joinedCount // ignore: cast_nullable_to_non_nullable
as int,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,creatorName: null == creatorName ? _self.creatorName : creatorName // ignore: cast_nullable_to_non_nullable
as String,creatorLevel: freezed == creatorLevel ? _self.creatorLevel : creatorLevel // ignore: cast_nullable_to_non_nullable
as String?,creatorDiveCount: null == creatorDiveCount ? _self.creatorDiveCount : creatorDiveCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
