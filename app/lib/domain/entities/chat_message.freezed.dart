// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessage {

 String get id; String get tripId; String get userId; String get body; DateTime get createdAt;// True only when this specific sender is an actual member of the trip's dive center —
// not just "this trip was organized by a dive center" (see ChatView._MessageRow, which
// used to apply the "Name | Dive Center" label to every non-own message regardless).
 bool get isDiveCenterStaff;// Diver-armed "@DiveCenter" flag on this specific message — see ChatView's mention
// chip. Only ever true on a business trip; Stage 2 push will gate staff notifications
// on it instead of pushing every message.
 bool get mentionsDiveCenter;// 'user' for a normal message; a system kind (e.g. 'feedback_prompt') renders as a
// centered row instead of a bubble — see ChatView's _SystemMessageRow.
 String get kind;// Per-viewer: has the current user already submitted feedback for this trip? Only
// meaningful when kind is 'feedback_prompt'.
 bool get feedbackProvided;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided);

@override
String toString() {
  return 'ChatMessage(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDiveCenterStaff: null == isDiveCenterStaff ? _self.isDiveCenterStaff : isDiveCenterStaff // ignore: cast_nullable_to_non_nullable
as bool,mentionsDiveCenter: null == mentionsDiveCenter ? _self.mentionsDiveCenter : mentionsDiveCenter // ignore: cast_nullable_to_non_nullable
as bool,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,feedbackProvided: null == feedbackProvided ? _self.feedbackProvided : feedbackProvided // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.tripId, required this.userId, required this.body, required this.createdAt, this.isDiveCenterStaff = false, this.mentionsDiveCenter = false, this.kind = 'user', this.feedbackProvided = false});
  

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  String body;
@override final  DateTime createdAt;
// True only when this specific sender is an actual member of the trip's dive center —
// not just "this trip was organized by a dive center" (see ChatView._MessageRow, which
// used to apply the "Name | Dive Center" label to every non-own message regardless).
@override@JsonKey() final  bool isDiveCenterStaff;
// Diver-armed "@DiveCenter" flag on this specific message — see ChatView's mention
// chip. Only ever true on a business trip; Stage 2 push will gate staff notifications
// on it instead of pushing every message.
@override@JsonKey() final  bool mentionsDiveCenter;
// 'user' for a normal message; a system kind (e.g. 'feedback_prompt') renders as a
// centered row instead of a bubble — see ChatView's _SystemMessageRow.
@override@JsonKey() final  String kind;
// Per-viewer: has the current user already submitted feedback for this trip? Only
// meaningful when kind is 'feedback_prompt'.
@override@JsonKey() final  bool feedbackProvided;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided);

@override
String toString() {
  return 'ChatMessage(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDiveCenterStaff: null == isDiveCenterStaff ? _self.isDiveCenterStaff : isDiveCenterStaff // ignore: cast_nullable_to_non_nullable
as bool,mentionsDiveCenter: null == mentionsDiveCenter ? _self.mentionsDiveCenter : mentionsDiveCenter // ignore: cast_nullable_to_non_nullable
as bool,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,feedbackProvided: null == feedbackProvided ? _self.feedbackProvided : feedbackProvided // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
