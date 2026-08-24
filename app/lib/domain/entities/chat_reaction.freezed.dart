// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatReaction {

 int get count; bool get reactedByMe;
/// Create a copy of ChatReaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatReactionCopyWith<ChatReaction> get copyWith => _$ChatReactionCopyWithImpl<ChatReaction>(this as ChatReaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatReaction&&(identical(other.count, count) || other.count == count)&&(identical(other.reactedByMe, reactedByMe) || other.reactedByMe == reactedByMe));
}


@override
int get hashCode => Object.hash(runtimeType,count,reactedByMe);

@override
String toString() {
  return 'ChatReaction(count: $count, reactedByMe: $reactedByMe)';
}


}

/// @nodoc
abstract mixin class $ChatReactionCopyWith<$Res>  {
  factory $ChatReactionCopyWith(ChatReaction value, $Res Function(ChatReaction) _then) = _$ChatReactionCopyWithImpl;
@useResult
$Res call({
 int count, bool reactedByMe
});




}
/// @nodoc
class _$ChatReactionCopyWithImpl<$Res>
    implements $ChatReactionCopyWith<$Res> {
  _$ChatReactionCopyWithImpl(this._self, this._then);

  final ChatReaction _self;
  final $Res Function(ChatReaction) _then;

/// Create a copy of ChatReaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? reactedByMe = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactedByMe: null == reactedByMe ? _self.reactedByMe : reactedByMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatReaction].
extension ChatReactionPatterns on ChatReaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatReaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatReaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatReaction value)  $default,){
final _that = this;
switch (_that) {
case _ChatReaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatReaction value)?  $default,){
final _that = this;
switch (_that) {
case _ChatReaction() when $default != null:
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
case _ChatReaction() when $default != null:
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
case _ChatReaction():
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
case _ChatReaction() when $default != null:
return $default(_that.count,_that.reactedByMe);case _:
  return null;

}
}

}

/// @nodoc


class _ChatReaction implements ChatReaction {
  const _ChatReaction({required this.count, required this.reactedByMe});
  

@override final  int count;
@override final  bool reactedByMe;

/// Create a copy of ChatReaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatReactionCopyWith<_ChatReaction> get copyWith => __$ChatReactionCopyWithImpl<_ChatReaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatReaction&&(identical(other.count, count) || other.count == count)&&(identical(other.reactedByMe, reactedByMe) || other.reactedByMe == reactedByMe));
}


@override
int get hashCode => Object.hash(runtimeType,count,reactedByMe);

@override
String toString() {
  return 'ChatReaction(count: $count, reactedByMe: $reactedByMe)';
}


}

/// @nodoc
abstract mixin class _$ChatReactionCopyWith<$Res> implements $ChatReactionCopyWith<$Res> {
  factory _$ChatReactionCopyWith(_ChatReaction value, $Res Function(_ChatReaction) _then) = __$ChatReactionCopyWithImpl;
@override @useResult
$Res call({
 int count, bool reactedByMe
});




}
/// @nodoc
class __$ChatReactionCopyWithImpl<$Res>
    implements _$ChatReactionCopyWith<$Res> {
  __$ChatReactionCopyWithImpl(this._self, this._then);

  final _ChatReaction _self;
  final $Res Function(_ChatReaction) _then;

/// Create a copy of ChatReaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? reactedByMe = null,}) {
  return _then(_ChatReaction(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reactedByMe: null == reactedByMe ? _self.reactedByMe : reactedByMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
