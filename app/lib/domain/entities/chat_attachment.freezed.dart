// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatAttachment {

// Null only for a pending item still uploading (see localPath/isUploaded below) — every
// attachment that came from the REST list or realtime always has this set.
 String? get url; String get type;// 'image' | 'video' | 'pdf'
 String? get filename; int? get sizeBytes;// Video only.
 int? get durationSeconds;// Set only on a pending item, before url exists — lets the bubble render the picked file
// immediately (thumbnail/filename) while the upload is in flight. Mirrors what
// ChatMessage.localAttachmentPath used to do for the single-attachment case.
 String? get localPath;// False only for a pending item whose upload hasn't completed yet.
 bool get isUploaded;
/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAttachmentCopyWith<ChatAttachment> get copyWith => _$ChatAttachmentCopyWithImpl<ChatAttachment>(this as ChatAttachment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAttachment&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.isUploaded, isUploaded) || other.isUploaded == isUploaded));
}


@override
int get hashCode => Object.hash(runtimeType,url,type,filename,sizeBytes,durationSeconds,localPath,isUploaded);

@override
String toString() {
  return 'ChatAttachment(url: $url, type: $type, filename: $filename, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds, localPath: $localPath, isUploaded: $isUploaded)';
}


}

/// @nodoc
abstract mixin class $ChatAttachmentCopyWith<$Res>  {
  factory $ChatAttachmentCopyWith(ChatAttachment value, $Res Function(ChatAttachment) _then) = _$ChatAttachmentCopyWithImpl;
@useResult
$Res call({
 String? url, String type, String? filename, int? sizeBytes, int? durationSeconds, String? localPath, bool isUploaded
});




}
/// @nodoc
class _$ChatAttachmentCopyWithImpl<$Res>
    implements $ChatAttachmentCopyWith<$Res> {
  _$ChatAttachmentCopyWithImpl(this._self, this._then);

  final ChatAttachment _self;
  final $Res Function(ChatAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = freezed,Object? type = null,Object? filename = freezed,Object? sizeBytes = freezed,Object? durationSeconds = freezed,Object? localPath = freezed,Object? isUploaded = null,}) {
  return _then(_self.copyWith(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,isUploaded: null == isUploaded ? _self.isUploaded : isUploaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAttachment].
extension ChatAttachmentPatterns on ChatAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatAttachment value)  $default,){
final _that = this;
switch (_that) {
case _ChatAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds,  String? localPath,  bool isUploaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds,_that.localPath,_that.isUploaded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds,  String? localPath,  bool isUploaded)  $default,) {final _that = this;
switch (_that) {
case _ChatAttachment():
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds,_that.localPath,_that.isUploaded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds,  String? localPath,  bool isUploaded)?  $default,) {final _that = this;
switch (_that) {
case _ChatAttachment() when $default != null:
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds,_that.localPath,_that.isUploaded);case _:
  return null;

}
}

}

/// @nodoc


class _ChatAttachment implements ChatAttachment {
  const _ChatAttachment({this.url, required this.type, this.filename, this.sizeBytes, this.durationSeconds, this.localPath, this.isUploaded = true});
  

// Null only for a pending item still uploading (see localPath/isUploaded below) — every
// attachment that came from the REST list or realtime always has this set.
@override final  String? url;
@override final  String type;
// 'image' | 'video' | 'pdf'
@override final  String? filename;
@override final  int? sizeBytes;
// Video only.
@override final  int? durationSeconds;
// Set only on a pending item, before url exists — lets the bubble render the picked file
// immediately (thumbnail/filename) while the upload is in flight. Mirrors what
// ChatMessage.localAttachmentPath used to do for the single-attachment case.
@override final  String? localPath;
// False only for a pending item whose upload hasn't completed yet.
@override@JsonKey() final  bool isUploaded;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatAttachmentCopyWith<_ChatAttachment> get copyWith => __$ChatAttachmentCopyWithImpl<_ChatAttachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatAttachment&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.isUploaded, isUploaded) || other.isUploaded == isUploaded));
}


@override
int get hashCode => Object.hash(runtimeType,url,type,filename,sizeBytes,durationSeconds,localPath,isUploaded);

@override
String toString() {
  return 'ChatAttachment(url: $url, type: $type, filename: $filename, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds, localPath: $localPath, isUploaded: $isUploaded)';
}


}

/// @nodoc
abstract mixin class _$ChatAttachmentCopyWith<$Res> implements $ChatAttachmentCopyWith<$Res> {
  factory _$ChatAttachmentCopyWith(_ChatAttachment value, $Res Function(_ChatAttachment) _then) = __$ChatAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String? url, String type, String? filename, int? sizeBytes, int? durationSeconds, String? localPath, bool isUploaded
});




}
/// @nodoc
class __$ChatAttachmentCopyWithImpl<$Res>
    implements _$ChatAttachmentCopyWith<$Res> {
  __$ChatAttachmentCopyWithImpl(this._self, this._then);

  final _ChatAttachment _self;
  final $Res Function(_ChatAttachment) _then;

/// Create a copy of ChatAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = freezed,Object? type = null,Object? filename = freezed,Object? sizeBytes = freezed,Object? durationSeconds = freezed,Object? localPath = freezed,Object? isUploaded = null,}) {
  return _then(_ChatAttachment(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,isUploaded: null == isUploaded ? _self.isUploaded : isUploaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
