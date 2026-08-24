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
 bool get feedbackProvided;// Set together or not at all — a message carries at most one attachment (photo or PDF),
// with `body` doubling as its caption when both are present.
 String? get attachmentUrl; String? get attachmentType;// 'image' | 'pdf'
 String? get attachmentFilename; int? get attachmentSizeBytes;// Optimistic local echo, shown the instant "send" is tapped and replaced once the server
// confirms it (see ChatViewModel.send/uploadAndSend) — never true for a message that came
// from the REST list or realtime.
 bool get isPending;// Set only on a pending attachment message, before attachmentUrl exists — lets the bubble
// render the picked file immediately (thumbnail/filename) while the upload is in flight.
 String? get localAttachmentPath;// Id of the message this one replies to, if any — the client resolves it against the
// already-loaded message list rather than the server denormalizing sender/body onto every
// reply (see ChatViewModel).
 String? get replyToId;// Non-null means this message was deleted — body/attachment are already blanked by the
// server by the time this is set (see backend's toMessageResponse), so the bubble just
// renders a placeholder instead of trying to hide real content client-side.
 DateTime? get deletedAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType)&&(identical(other.attachmentFilename, attachmentFilename) || other.attachmentFilename == attachmentFilename)&&(identical(other.attachmentSizeBytes, attachmentSizeBytes) || other.attachmentSizeBytes == attachmentSizeBytes)&&(identical(other.isPending, isPending) || other.isPending == isPending)&&(identical(other.localAttachmentPath, localAttachmentPath) || other.localAttachmentPath == localAttachmentPath)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided,attachmentUrl,attachmentType,attachmentFilename,attachmentSizeBytes,isPending,localAttachmentPath,replyToId,deletedAt);

@override
String toString() {
  return 'ChatMessage(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, attachmentFilename: $attachmentFilename, attachmentSizeBytes: $attachmentSizeBytes, isPending: $isPending, localAttachmentPath: $localAttachmentPath, replyToId: $replyToId, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided, String? attachmentUrl, String? attachmentType, String? attachmentFilename, int? attachmentSizeBytes, bool isPending, String? localAttachmentPath, String? replyToId, DateTime? deletedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,Object? attachmentUrl = freezed,Object? attachmentType = freezed,Object? attachmentFilename = freezed,Object? attachmentSizeBytes = freezed,Object? isPending = null,Object? localAttachmentPath = freezed,Object? replyToId = freezed,Object? deletedAt = freezed,}) {
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
as bool,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,attachmentFilename: freezed == attachmentFilename ? _self.attachmentFilename : attachmentFilename // ignore: cast_nullable_to_non_nullable
as String?,attachmentSizeBytes: freezed == attachmentSizeBytes ? _self.attachmentSizeBytes : attachmentSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,localAttachmentPath: freezed == localAttachmentPath ? _self.localAttachmentPath : localAttachmentPath // ignore: cast_nullable_to_non_nullable
as String?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  bool isPending,  String? localAttachmentPath,  String? replyToId,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.isPending,_that.localAttachmentPath,_that.replyToId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  bool isPending,  String? localAttachmentPath,  String? replyToId,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.isPending,_that.localAttachmentPath,_that.replyToId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  bool isPending,  String? localAttachmentPath,  String? replyToId,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.isPending,_that.localAttachmentPath,_that.replyToId,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.tripId, required this.userId, required this.body, required this.createdAt, this.isDiveCenterStaff = false, this.mentionsDiveCenter = false, this.kind = 'user', this.feedbackProvided = false, this.attachmentUrl, this.attachmentType, this.attachmentFilename, this.attachmentSizeBytes, this.isPending = false, this.localAttachmentPath, this.replyToId, this.deletedAt});
  

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
// Set together or not at all — a message carries at most one attachment (photo or PDF),
// with `body` doubling as its caption when both are present.
@override final  String? attachmentUrl;
@override final  String? attachmentType;
// 'image' | 'pdf'
@override final  String? attachmentFilename;
@override final  int? attachmentSizeBytes;
// Optimistic local echo, shown the instant "send" is tapped and replaced once the server
// confirms it (see ChatViewModel.send/uploadAndSend) — never true for a message that came
// from the REST list or realtime.
@override@JsonKey() final  bool isPending;
// Set only on a pending attachment message, before attachmentUrl exists — lets the bubble
// render the picked file immediately (thumbnail/filename) while the upload is in flight.
@override final  String? localAttachmentPath;
// Id of the message this one replies to, if any — the client resolves it against the
// already-loaded message list rather than the server denormalizing sender/body onto every
// reply (see ChatViewModel).
@override final  String? replyToId;
// Non-null means this message was deleted — body/attachment are already blanked by the
// server by the time this is set (see backend's toMessageResponse), so the bubble just
// renders a placeholder instead of trying to hide real content client-side.
@override final  DateTime? deletedAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType)&&(identical(other.attachmentFilename, attachmentFilename) || other.attachmentFilename == attachmentFilename)&&(identical(other.attachmentSizeBytes, attachmentSizeBytes) || other.attachmentSizeBytes == attachmentSizeBytes)&&(identical(other.isPending, isPending) || other.isPending == isPending)&&(identical(other.localAttachmentPath, localAttachmentPath) || other.localAttachmentPath == localAttachmentPath)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided,attachmentUrl,attachmentType,attachmentFilename,attachmentSizeBytes,isPending,localAttachmentPath,replyToId,deletedAt);

@override
String toString() {
  return 'ChatMessage(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, attachmentFilename: $attachmentFilename, attachmentSizeBytes: $attachmentSizeBytes, isPending: $isPending, localAttachmentPath: $localAttachmentPath, replyToId: $replyToId, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided, String? attachmentUrl, String? attachmentType, String? attachmentFilename, int? attachmentSizeBytes, bool isPending, String? localAttachmentPath, String? replyToId, DateTime? deletedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,Object? attachmentUrl = freezed,Object? attachmentType = freezed,Object? attachmentFilename = freezed,Object? attachmentSizeBytes = freezed,Object? isPending = null,Object? localAttachmentPath = freezed,Object? replyToId = freezed,Object? deletedAt = freezed,}) {
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
as bool,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,attachmentFilename: freezed == attachmentFilename ? _self.attachmentFilename : attachmentFilename // ignore: cast_nullable_to_non_nullable
as String?,attachmentSizeBytes: freezed == attachmentSizeBytes ? _self.attachmentSizeBytes : attachmentSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,isPending: null == isPending ? _self.isPending : isPending // ignore: cast_nullable_to_non_nullable
as bool,localAttachmentPath: freezed == localAttachmentPath ? _self.localAttachmentPath : localAttachmentPath // ignore: cast_nullable_to_non_nullable
as String?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
