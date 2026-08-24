// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_attachment_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatAttachmentApiModel {

 String get url; String get type; String? get filename; int? get sizeBytes; int? get durationSeconds;
/// Create a copy of ChatAttachmentApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAttachmentApiModelCopyWith<ChatAttachmentApiModel> get copyWith => _$ChatAttachmentApiModelCopyWithImpl<ChatAttachmentApiModel>(this as ChatAttachmentApiModel, _$identity);

  /// Serializes this ChatAttachmentApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAttachmentApiModel&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,type,filename,sizeBytes,durationSeconds);

@override
String toString() {
  return 'ChatAttachmentApiModel(url: $url, type: $type, filename: $filename, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class $ChatAttachmentApiModelCopyWith<$Res>  {
  factory $ChatAttachmentApiModelCopyWith(ChatAttachmentApiModel value, $Res Function(ChatAttachmentApiModel) _then) = _$ChatAttachmentApiModelCopyWithImpl;
@useResult
$Res call({
 String url, String type, String? filename, int? sizeBytes, int? durationSeconds
});




}
/// @nodoc
class _$ChatAttachmentApiModelCopyWithImpl<$Res>
    implements $ChatAttachmentApiModelCopyWith<$Res> {
  _$ChatAttachmentApiModelCopyWithImpl(this._self, this._then);

  final ChatAttachmentApiModel _self;
  final $Res Function(ChatAttachmentApiModel) _then;

/// Create a copy of ChatAttachmentApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? type = null,Object? filename = freezed,Object? sizeBytes = freezed,Object? durationSeconds = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAttachmentApiModel].
extension ChatAttachmentApiModelPatterns on ChatAttachmentApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatAttachmentApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatAttachmentApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatAttachmentApiModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatAttachmentApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatAttachmentApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatAttachmentApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatAttachmentApiModel() when $default != null:
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _ChatAttachmentApiModel():
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String type,  String? filename,  int? sizeBytes,  int? durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _ChatAttachmentApiModel() when $default != null:
return $default(_that.url,_that.type,_that.filename,_that.sizeBytes,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatAttachmentApiModel implements ChatAttachmentApiModel {
  const _ChatAttachmentApiModel({required this.url, required this.type, this.filename, this.sizeBytes, this.durationSeconds});
  factory _ChatAttachmentApiModel.fromJson(Map<String, dynamic> json) => _$ChatAttachmentApiModelFromJson(json);

@override final  String url;
@override final  String type;
@override final  String? filename;
@override final  int? sizeBytes;
@override final  int? durationSeconds;

/// Create a copy of ChatAttachmentApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatAttachmentApiModelCopyWith<_ChatAttachmentApiModel> get copyWith => __$ChatAttachmentApiModelCopyWithImpl<_ChatAttachmentApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatAttachmentApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatAttachmentApiModel&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,type,filename,sizeBytes,durationSeconds);

@override
String toString() {
  return 'ChatAttachmentApiModel(url: $url, type: $type, filename: $filename, sizeBytes: $sizeBytes, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$ChatAttachmentApiModelCopyWith<$Res> implements $ChatAttachmentApiModelCopyWith<$Res> {
  factory _$ChatAttachmentApiModelCopyWith(_ChatAttachmentApiModel value, $Res Function(_ChatAttachmentApiModel) _then) = __$ChatAttachmentApiModelCopyWithImpl;
@override @useResult
$Res call({
 String url, String type, String? filename, int? sizeBytes, int? durationSeconds
});




}
/// @nodoc
class __$ChatAttachmentApiModelCopyWithImpl<$Res>
    implements _$ChatAttachmentApiModelCopyWith<$Res> {
  __$ChatAttachmentApiModelCopyWithImpl(this._self, this._then);

  final _ChatAttachmentApiModel _self;
  final $Res Function(_ChatAttachmentApiModel) _then;

/// Create a copy of ChatAttachmentApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? type = null,Object? filename = freezed,Object? sizeBytes = freezed,Object? durationSeconds = freezed,}) {
  return _then(_ChatAttachmentApiModel(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
