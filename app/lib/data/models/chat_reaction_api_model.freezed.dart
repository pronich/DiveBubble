// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_reaction_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatReactionApiModel {

 int get count; bool get reactedByMe;
/// Create a copy of ChatReactionApiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatReactionApiModelCopyWith<ChatReactionApiModel> get copyWith => _$ChatReactionApiModelCopyWithImpl<ChatReactionApiModel>(this as ChatReactionApiModel, _$identity);

  /// Serializes this ChatReactionApiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatReactionApiModel&&(identical(other.count, count) || other.count == count)&&(identical(other.reactedByMe, reactedByMe) || other.reactedByMe == reactedByMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,reactedByMe);

@override
String toString() {
  return 'ChatReactionApiModel(count: $count, reactedByMe: $reactedByMe)';
}


}

/// @nodoc
abstract mixin class $ChatReactionApiModelCopyWith<$Res>  {
  factory $ChatReactionApiModelCopyWith(ChatReactionApiModel value, $Res Function(ChatReactionApiModel) _then) = _$ChatReactionApiModelCopyWithImpl;
@useResult
$Res call({
 int count, bool reactedByMe
});




}
/// @nodoc
class _$ChatReactionApiModelCopyWithImpl<$Res>
    implements $ChatReactionApiModelCopyWith<$Res> {
  _$ChatReactionApiModelCopyWithImpl(this._self, this._then);

  final ChatReactionApiModel _self;
  final $Res Function(ChatReactionApiModel) _then;

/// Create a copy of ChatReactionApiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? reactedByMe = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactedByMe: null == reactedByMe ? _self.reactedByMe : reactedByMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatReactionApiModel].
extension ChatReactionApiModelPatterns on ChatReactionApiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatReactionApiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatReactionApiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatReactionApiModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatReactionApiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatReactionApiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatReactionApiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  bool reactedByMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatReactionApiModel() when $default != null:
return $default(_that.count,_that.reactedByMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  bool reactedByMe)  $default,) {final _that = this;
switch (_that) {
case _ChatReactionApiModel():
return $default(_that.count,_that.reactedByMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  bool reactedByMe)?  $default,) {final _that = this;
switch (_that) {
case _ChatReactionApiModel() when $default != null:
return $default(_that.count,_that.reactedByMe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatReactionApiModel implements ChatReactionApiModel {
  const _ChatReactionApiModel({required this.count, required this.reactedByMe});
  factory _ChatReactionApiModel.fromJson(Map<String, dynamic> json) => _$ChatReactionApiModelFromJson(json);

@override final  int count;
@override final  bool reactedByMe;

/// Create a copy of ChatReactionApiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatReactionApiModelCopyWith<_ChatReactionApiModel> get copyWith => __$ChatReactionApiModelCopyWithImpl<_ChatReactionApiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatReactionApiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatReactionApiModel&&(identical(other.count, count) || other.count == count)&&(identical(other.reactedByMe, reactedByMe) || other.reactedByMe == reactedByMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,reactedByMe);

@override
String toString() {
  return 'ChatReactionApiModel(count: $count, reactedByMe: $reactedByMe)';
}


}

/// @nodoc
abstract mixin class _$ChatReactionApiModelCopyWith<$Res> implements $ChatReactionApiModelCopyWith<$Res> {
  factory _$ChatReactionApiModelCopyWith(_ChatReactionApiModel value, $Res Function(_ChatReactionApiModel) _then) = __$ChatReactionApiModelCopyWithImpl;
@override @useResult
$Res call({
 int count, bool reactedByMe
});




}
/// @nodoc
class __$ChatReactionApiModelCopyWithImpl<$Res>
    implements _$ChatReactionApiModelCopyWith<$Res> {
  __$ChatReactionApiModelCopyWithImpl(this._self, this._then);

  final _ChatReactionApiModel _self;
  final $Res Function(_ChatReactionApiModel) _then;

/// Create a copy of ChatReactionApiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? reactedByMe = null,}) {
  return _then(_ChatReactionApiModel(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactedByMe: null == reactedByMe ? _self.reactedByMe : reactedByMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
