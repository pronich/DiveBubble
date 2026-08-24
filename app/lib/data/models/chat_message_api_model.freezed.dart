// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessageApiModel {

 String get id; String get tripId; String get userId; String get body; DateTime get createdAt; bool get isDiveCenterStaff; bool get mentionsDiveCenter; String get kind; bool get feedbackProvided; String? get attachmentUrl; String? get attachmentType; String? get attachmentFilename; int? get attachmentSizeBytes; String? get replyToId; DateTime? get deletedAt;
/// Create a copy of ChatMessageApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageApiModelCopyWith<ChatMessageApiModel> get copyWith => _$ChatMessageApiModelCopyWithImpl<ChatMessageApiModel>(this as ChatMessageApiModel, _$identity);

  /// Serializes this ChatMessageApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType)&&(identical(other.attachmentFilename, attachmentFilename) || other.attachmentFilename == attachmentFilename)&&(identical(other.attachmentSizeBytes, attachmentSizeBytes) || other.attachmentSizeBytes == attachmentSizeBytes)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided,attachmentUrl,attachmentType,attachmentFilename,attachmentSizeBytes,replyToId,deletedAt);

@override
String toString() {
  return 'ChatMessageApiModel(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, attachmentFilename: $attachmentFilename, attachmentSizeBytes: $attachmentSizeBytes, replyToId: $replyToId, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageApiModelCopyWith<$Res>  {
  factory $ChatMessageApiModelCopyWith(ChatMessageApiModel value, $Res Function(ChatMessageApiModel) _then) = _$ChatMessageApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided, String? attachmentUrl, String? attachmentType, String? attachmentFilename, int? attachmentSizeBytes, String? replyToId, DateTime? deletedAt
});




}
/// @nodoc
class _$ChatMessageApiModelCopyWithImpl<$Res>
    implements $ChatMessageApiModelCopyWith<$Res> {
  _$ChatMessageApiModelCopyWithImpl(this._self, this._then);

  final ChatMessageApiModel _self;
  final $Res Function(ChatMessageApiModel) _then;

/// Create a copy of ChatMessageApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,Object? attachmentUrl = freezed,Object? attachmentType = freezed,Object? attachmentFilename = freezed,Object? attachmentSizeBytes = freezed,Object? replyToId = freezed,Object? deletedAt = freezed,}) {
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
as int?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageApiModel].
extension ChatMessageApiModelPatterns on ChatMessageApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageApiModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  String? replyToId,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageApiModel() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.replyToId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  String? replyToId,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageApiModel():
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.replyToId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  String body,  DateTime createdAt,  bool isDiveCenterStaff,  bool mentionsDiveCenter,  String kind,  bool feedbackProvided,  String? attachmentUrl,  String? attachmentType,  String? attachmentFilename,  int? attachmentSizeBytes,  String? replyToId,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageApiModel() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.body,_that.createdAt,_that.isDiveCenterStaff,_that.mentionsDiveCenter,_that.kind,_that.feedbackProvided,_that.attachmentUrl,_that.attachmentType,_that.attachmentFilename,_that.attachmentSizeBytes,_that.replyToId,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageApiModel implements ChatMessageApiModel {
  const _ChatMessageApiModel({required this.id, required this.tripId, required this.userId, required this.body, required this.createdAt, this.isDiveCenterStaff = false, this.mentionsDiveCenter = false, this.kind = 'user', this.feedbackProvided = false, this.attachmentUrl, this.attachmentType, this.attachmentFilename, this.attachmentSizeBytes, this.replyToId, this.deletedAt});
  factory _ChatMessageApiModel.fromJson(Map<String, dynamic> json) => _$ChatMessageApiModelFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  String body;
@override final  DateTime createdAt;
@override@JsonKey() final  bool isDiveCenterStaff;
@override@JsonKey() final  bool mentionsDiveCenter;
@override@JsonKey() final  String kind;
@override@JsonKey() final  bool feedbackProvided;
@override final  String? attachmentUrl;
@override final  String? attachmentType;
@override final  String? attachmentFilename;
@override final  int? attachmentSizeBytes;
@override final  String? replyToId;
@override final  DateTime? deletedAt;

/// Create a copy of ChatMessageApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageApiModelCopyWith<_ChatMessageApiModel> get copyWith => __$ChatMessageApiModelCopyWithImpl<_ChatMessageApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isDiveCenterStaff, isDiveCenterStaff) || other.isDiveCenterStaff == isDiveCenterStaff)&&(identical(other.mentionsDiveCenter, mentionsDiveCenter) || other.mentionsDiveCenter == mentionsDiveCenter)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.feedbackProvided, feedbackProvided) || other.feedbackProvided == feedbackProvided)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType)&&(identical(other.attachmentFilename, attachmentFilename) || other.attachmentFilename == attachmentFilename)&&(identical(other.attachmentSizeBytes, attachmentSizeBytes) || other.attachmentSizeBytes == attachmentSizeBytes)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,body,createdAt,isDiveCenterStaff,mentionsDiveCenter,kind,feedbackProvided,attachmentUrl,attachmentType,attachmentFilename,attachmentSizeBytes,replyToId,deletedAt);

@override
String toString() {
  return 'ChatMessageApiModel(id: $id, tripId: $tripId, userId: $userId, body: $body, createdAt: $createdAt, isDiveCenterStaff: $isDiveCenterStaff, mentionsDiveCenter: $mentionsDiveCenter, kind: $kind, feedbackProvided: $feedbackProvided, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, attachmentFilename: $attachmentFilename, attachmentSizeBytes: $attachmentSizeBytes, replyToId: $replyToId, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageApiModelCopyWith<$Res> implements $ChatMessageApiModelCopyWith<$Res> {
  factory _$ChatMessageApiModelCopyWith(_ChatMessageApiModel value, $Res Function(_ChatMessageApiModel) _then) = __$ChatMessageApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, String body, DateTime createdAt, bool isDiveCenterStaff, bool mentionsDiveCenter, String kind, bool feedbackProvided, String? attachmentUrl, String? attachmentType, String? attachmentFilename, int? attachmentSizeBytes, String? replyToId, DateTime? deletedAt
});




}
/// @nodoc
class __$ChatMessageApiModelCopyWithImpl<$Res>
    implements _$ChatMessageApiModelCopyWith<$Res> {
  __$ChatMessageApiModelCopyWithImpl(this._self, this._then);

  final _ChatMessageApiModel _self;
  final $Res Function(_ChatMessageApiModel) _then;

/// Create a copy of ChatMessageApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? body = null,Object? createdAt = null,Object? isDiveCenterStaff = null,Object? mentionsDiveCenter = null,Object? kind = null,Object? feedbackProvided = null,Object? attachmentUrl = freezed,Object? attachmentType = freezed,Object? attachmentFilename = freezed,Object? attachmentSizeBytes = freezed,Object? replyToId = freezed,Object? deletedAt = freezed,}) {
  return _then(_ChatMessageApiModel(
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
as int?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
