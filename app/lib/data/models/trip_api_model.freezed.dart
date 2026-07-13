// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripApiModel {

 String get id; String get title; String get location; DateTime get startTime; DateTime get createdAt; bool get joined;
/// Create a copy of TripApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripApiModelCopyWith<TripApiModel> get copyWith => _$TripApiModelCopyWithImpl<TripApiModel>(this as TripApiModel, _$identity);

  /// Serializes this TripApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joined, joined) || other.joined == joined));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,location,startTime,createdAt,joined);

@override
String toString() {
  return 'TripApiModel(id: $id, title: $title, location: $location, startTime: $startTime, createdAt: $createdAt, joined: $joined)';
}


}

/// @nodoc
abstract mixin class $TripApiModelCopyWith<$Res>  {
  factory $TripApiModelCopyWith(TripApiModel value, $Res Function(TripApiModel) _then) = _$TripApiModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String location, DateTime startTime, DateTime createdAt, bool joined
});




}
/// @nodoc
class _$TripApiModelCopyWithImpl<$Res>
    implements $TripApiModelCopyWith<$Res> {
  _$TripApiModelCopyWithImpl(this._self, this._then);

  final TripApiModel _self;
  final $Res Function(TripApiModel) _then;

/// Create a copy of TripApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? location = null,Object? startTime = null,Object? createdAt = null,Object? joined = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TripApiModel].
extension TripApiModelPatterns on TripApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripApiModel value)  $default,){
final _that = this;
switch (_that) {
case _TripApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _TripApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String location,  DateTime startTime,  DateTime createdAt,  bool joined)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripApiModel() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.createdAt,_that.joined);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String location,  DateTime startTime,  DateTime createdAt,  bool joined)  $default,) {final _that = this;
switch (_that) {
case _TripApiModel():
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.createdAt,_that.joined);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String location,  DateTime startTime,  DateTime createdAt,  bool joined)?  $default,) {final _that = this;
switch (_that) {
case _TripApiModel() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.createdAt,_that.joined);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripApiModel implements TripApiModel {
  const _TripApiModel({required this.id, required this.title, required this.location, required this.startTime, required this.createdAt, required this.joined});
  factory _TripApiModel.fromJson(Map<String, dynamic> json) => _$TripApiModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String location;
@override final  DateTime startTime;
@override final  DateTime createdAt;
@override final  bool joined;

/// Create a copy of TripApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripApiModelCopyWith<_TripApiModel> get copyWith => __$TripApiModelCopyWithImpl<_TripApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripApiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.joined, joined) || other.joined == joined));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,location,startTime,createdAt,joined);

@override
String toString() {
  return 'TripApiModel(id: $id, title: $title, location: $location, startTime: $startTime, createdAt: $createdAt, joined: $joined)';
}


}

/// @nodoc
abstract mixin class _$TripApiModelCopyWith<$Res> implements $TripApiModelCopyWith<$Res> {
  factory _$TripApiModelCopyWith(_TripApiModel value, $Res Function(_TripApiModel) _then) = __$TripApiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String location, DateTime startTime, DateTime createdAt, bool joined
});




}
/// @nodoc
class __$TripApiModelCopyWithImpl<$Res>
    implements _$TripApiModelCopyWith<$Res> {
  __$TripApiModelCopyWithImpl(this._self, this._then);

  final _TripApiModel _self;
  final $Res Function(_TripApiModel) _then;

/// Create a copy of TripApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? location = null,Object? startTime = null,Object? createdAt = null,Object? joined = null,}) {
  return _then(_TripApiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
