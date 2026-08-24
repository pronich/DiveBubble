// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_item_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaItemApiModel {

 String get messageId; String get userId; DateTime get createdAt; ChatAttachmentApiModel get attachment;
/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaItemApiModelCopyWith<MediaItemApiModel> get copyWith => _$MediaItemApiModelCopyWithImpl<MediaItemApiModel>(this as MediaItemApiModel, _$identity);

  /// Serializes this MediaItemApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaItemApiModel&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attachment, attachment) || other.attachment == attachment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,createdAt,attachment);

@override
String toString() {
  return 'MediaItemApiModel(messageId: $messageId, userId: $userId, createdAt: $createdAt, attachment: $attachment)';
}


}

/// @nodoc
abstract mixin class $MediaItemApiModelCopyWith<$Res>  {
  factory $MediaItemApiModelCopyWith(MediaItemApiModel value, $Res Function(MediaItemApiModel) _then) = _$MediaItemApiModelCopyWithImpl;
@useResult
$Res call({
 String messageId, String userId, DateTime createdAt, ChatAttachmentApiModel attachment
});


$ChatAttachmentApiModelCopyWith<$Res> get attachment;

}
/// @nodoc
class _$MediaItemApiModelCopyWithImpl<$Res>
    implements $MediaItemApiModelCopyWith<$Res> {
  _$MediaItemApiModelCopyWithImpl(this._self, this._then);

  final MediaItemApiModel _self;
  final $Res Function(MediaItemApiModel) _then;

/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? userId = null,Object? createdAt = null,Object? attachment = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attachment: null == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as ChatAttachmentApiModel,
  ));
}
/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatAttachmentApiModelCopyWith<$Res> get attachment {
  
  return $ChatAttachmentApiModelCopyWith<$Res>(_self.attachment, (value) {
    return _then(_self.copyWith(attachment: value));
  });
}
}


/// Adds pattern-matching-related methods to [MediaItemApiModel].
extension MediaItemApiModelPatterns on MediaItemApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaItemApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaItemApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaItemApiModel value)  $default,){
final _that = this;
switch (_that) {
case _MediaItemApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaItemApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _MediaItemApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String userId,  DateTime createdAt,  ChatAttachmentApiModel attachment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaItemApiModel() when $default != null:
return $default(_that.messageId,_that.userId,_that.createdAt,_that.attachment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String userId,  DateTime createdAt,  ChatAttachmentApiModel attachment)  $default,) {final _that = this;
switch (_that) {
case _MediaItemApiModel():
return $default(_that.messageId,_that.userId,_that.createdAt,_that.attachment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String userId,  DateTime createdAt,  ChatAttachmentApiModel attachment)?  $default,) {final _that = this;
switch (_that) {
case _MediaItemApiModel() when $default != null:
return $default(_that.messageId,_that.userId,_that.createdAt,_that.attachment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaItemApiModel implements MediaItemApiModel {
  const _MediaItemApiModel({required this.messageId, required this.userId, required this.createdAt, required this.attachment});
  factory _MediaItemApiModel.fromJson(Map<String, dynamic> json) => _$MediaItemApiModelFromJson(json);

@override final  String messageId;
@override final  String userId;
@override final  DateTime createdAt;
@override final  ChatAttachmentApiModel attachment;

/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaItemApiModelCopyWith<_MediaItemApiModel> get copyWith => __$MediaItemApiModelCopyWithImpl<_MediaItemApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaItemApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaItemApiModel&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attachment, attachment) || other.attachment == attachment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,createdAt,attachment);

@override
String toString() {
  return 'MediaItemApiModel(messageId: $messageId, userId: $userId, createdAt: $createdAt, attachment: $attachment)';
}


}

/// @nodoc
abstract mixin class _$MediaItemApiModelCopyWith<$Res> implements $MediaItemApiModelCopyWith<$Res> {
  factory _$MediaItemApiModelCopyWith(_MediaItemApiModel value, $Res Function(_MediaItemApiModel) _then) = __$MediaItemApiModelCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String userId, DateTime createdAt, ChatAttachmentApiModel attachment
});


@override $ChatAttachmentApiModelCopyWith<$Res> get attachment;

}
/// @nodoc
class __$MediaItemApiModelCopyWithImpl<$Res>
    implements _$MediaItemApiModelCopyWith<$Res> {
  __$MediaItemApiModelCopyWithImpl(this._self, this._then);

  final _MediaItemApiModel _self;
  final $Res Function(_MediaItemApiModel) _then;

/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? userId = null,Object? createdAt = null,Object? attachment = null,}) {
  return _then(_MediaItemApiModel(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attachment: null == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as ChatAttachmentApiModel,
  ));
}

/// Create a copy of MediaItemApiModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatAttachmentApiModelCopyWith<$Res> get attachment {
  
  return $ChatAttachmentApiModelCopyWith<$Res>(_self.attachment, (value) {
    return _then(_self.copyWith(attachment: value));
  });
}
}

// dart format on
