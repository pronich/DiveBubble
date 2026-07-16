// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripPhoto {

 String get id; String get url; int get position;
/// Create a copy of TripPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripPhotoCopyWith<TripPhoto> get copyWith => _$TripPhotoCopyWithImpl<TripPhoto>(this as TripPhoto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,position);

@override
String toString() {
  return 'TripPhoto(id: $id, url: $url, position: $position)';
}


}

/// @nodoc
abstract mixin class $TripPhotoCopyWith<$Res>  {
  factory $TripPhotoCopyWith(TripPhoto value, $Res Function(TripPhoto) _then) = _$TripPhotoCopyWithImpl;
@useResult
$Res call({
 String id, String url, int position
});




}
/// @nodoc
class _$TripPhotoCopyWithImpl<$Res>
    implements $TripPhotoCopyWith<$Res> {
  _$TripPhotoCopyWithImpl(this._self, this._then);

  final TripPhoto _self;
  final $Res Function(TripPhoto) _then;

/// Create a copy of TripPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? position = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TripPhoto].
extension TripPhotoPatterns on TripPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripPhoto value)  $default,){
final _that = this;
switch (_that) {
case _TripPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _TripPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String url,  int position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripPhoto() when $default != null:
return $default(_that.id,_that.url,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String url,  int position)  $default,) {final _that = this;
switch (_that) {
case _TripPhoto():
return $default(_that.id,_that.url,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String url,  int position)?  $default,) {final _that = this;
switch (_that) {
case _TripPhoto() when $default != null:
return $default(_that.id,_that.url,_that.position);case _:
  return null;

}
}

}

/// @nodoc


class _TripPhoto implements TripPhoto {
  const _TripPhoto({required this.id, required this.url, required this.position});
  

@override final  String id;
@override final  String url;
@override final  int position;

/// Create a copy of TripPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripPhotoCopyWith<_TripPhoto> get copyWith => __$TripPhotoCopyWithImpl<_TripPhoto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,position);

@override
String toString() {
  return 'TripPhoto(id: $id, url: $url, position: $position)';
}


}

/// @nodoc
abstract mixin class _$TripPhotoCopyWith<$Res> implements $TripPhotoCopyWith<$Res> {
  factory _$TripPhotoCopyWith(_TripPhoto value, $Res Function(_TripPhoto) _then) = __$TripPhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String url, int position
});




}
/// @nodoc
class __$TripPhotoCopyWithImpl<$Res>
    implements _$TripPhotoCopyWith<$Res> {
  __$TripPhotoCopyWithImpl(this._self, this._then);

  final _TripPhoto _self;
  final $Res Function(_TripPhoto) _then;

/// Create a copy of TripPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? position = null,}) {
  return _then(_TripPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
