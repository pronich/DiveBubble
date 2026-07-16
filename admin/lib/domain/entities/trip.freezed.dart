// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Trip {

 String get id; String get title; String get location; DateTime get startTime; bool get joined; String? get creatorUserId; int get participantCount; int get unreadCount; DateTime? get endDate; String? get description; String? get meetingPoint; int? get diveCountMin; int? get diveCountMax; int? get depthMinM; int? get depthMaxM; String? get minCertification; String? get bookingCode; int? get maxParticipants; String get bookingStatus; String? get photoUrl;// Business fields — always present for a trip created from admin/, since admin never
// creates an individual trip. Not yet read by app/'s own Trip entity (see CLAUDE.md's
// Business/dive centers section) — that's a separate, still-pending piece of work.
 String? get diveCenterId; int? get priceMinor; String get currency;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.joined, joined) || other.joined == joined)&&(identical(other.creatorUserId, creatorUserId) || other.creatorUserId == creatorUserId)&&(identical(other.participantCount, participantCount) || other.participantCount == participantCount)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.meetingPoint, meetingPoint) || other.meetingPoint == meetingPoint)&&(identical(other.diveCountMin, diveCountMin) || other.diveCountMin == diveCountMin)&&(identical(other.diveCountMax, diveCountMax) || other.diveCountMax == diveCountMax)&&(identical(other.depthMinM, depthMinM) || other.depthMinM == depthMinM)&&(identical(other.depthMaxM, depthMaxM) || other.depthMaxM == depthMaxM)&&(identical(other.minCertification, minCertification) || other.minCertification == minCertification)&&(identical(other.bookingCode, bookingCode) || other.bookingCode == bookingCode)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.bookingStatus, bookingStatus) || other.bookingStatus == bookingStatus)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.diveCenterId, diveCenterId) || other.diveCenterId == diveCenterId)&&(identical(other.priceMinor, priceMinor) || other.priceMinor == priceMinor)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,location,startTime,joined,creatorUserId,participantCount,unreadCount,endDate,description,meetingPoint,diveCountMin,diveCountMax,depthMinM,depthMaxM,minCertification,bookingCode,maxParticipants,bookingStatus,photoUrl,diveCenterId,priceMinor,currency]);

@override
String toString() {
  return 'Trip(id: $id, title: $title, location: $location, startTime: $startTime, joined: $joined, creatorUserId: $creatorUserId, participantCount: $participantCount, unreadCount: $unreadCount, endDate: $endDate, description: $description, meetingPoint: $meetingPoint, diveCountMin: $diveCountMin, diveCountMax: $diveCountMax, depthMinM: $depthMinM, depthMaxM: $depthMaxM, minCertification: $minCertification, bookingCode: $bookingCode, maxParticipants: $maxParticipants, bookingStatus: $bookingStatus, photoUrl: $photoUrl, diveCenterId: $diveCenterId, priceMinor: $priceMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, String title, String location, DateTime startTime, bool joined, String? creatorUserId, int participantCount, int unreadCount, DateTime? endDate, String? description, String? meetingPoint, int? diveCountMin, int? diveCountMax, int? depthMinM, int? depthMaxM, String? minCertification, String? bookingCode, int? maxParticipants, String bookingStatus, String? photoUrl, String? diveCenterId, int? priceMinor, String currency
});




}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? location = null,Object? startTime = null,Object? joined = null,Object? creatorUserId = freezed,Object? participantCount = null,Object? unreadCount = null,Object? endDate = freezed,Object? description = freezed,Object? meetingPoint = freezed,Object? diveCountMin = freezed,Object? diveCountMax = freezed,Object? depthMinM = freezed,Object? depthMaxM = freezed,Object? minCertification = freezed,Object? bookingCode = freezed,Object? maxParticipants = freezed,Object? bookingStatus = null,Object? photoUrl = freezed,Object? diveCenterId = freezed,Object? priceMinor = freezed,Object? currency = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,creatorUserId: freezed == creatorUserId ? _self.creatorUserId : creatorUserId // ignore: cast_nullable_to_non_nullable
as String?,participantCount: null == participantCount ? _self.participantCount : participantCount // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,meetingPoint: freezed == meetingPoint ? _self.meetingPoint : meetingPoint // ignore: cast_nullable_to_non_nullable
as String?,diveCountMin: freezed == diveCountMin ? _self.diveCountMin : diveCountMin // ignore: cast_nullable_to_non_nullable
as int?,diveCountMax: freezed == diveCountMax ? _self.diveCountMax : diveCountMax // ignore: cast_nullable_to_non_nullable
as int?,depthMinM: freezed == depthMinM ? _self.depthMinM : depthMinM // ignore: cast_nullable_to_non_nullable
as int?,depthMaxM: freezed == depthMaxM ? _self.depthMaxM : depthMaxM // ignore: cast_nullable_to_non_nullable
as int?,minCertification: freezed == minCertification ? _self.minCertification : minCertification // ignore: cast_nullable_to_non_nullable
as String?,bookingCode: freezed == bookingCode ? _self.bookingCode : bookingCode // ignore: cast_nullable_to_non_nullable
as String?,maxParticipants: freezed == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int?,bookingStatus: null == bookingStatus ? _self.bookingStatus : bookingStatus // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,diveCenterId: freezed == diveCenterId ? _self.diveCenterId : diveCenterId // ignore: cast_nullable_to_non_nullable
as String?,priceMinor: freezed == priceMinor ? _self.priceMinor : priceMinor // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String location,  DateTime startTime,  bool joined,  String? creatorUserId,  int participantCount,  int unreadCount,  DateTime? endDate,  String? description,  String? meetingPoint,  int? diveCountMin,  int? diveCountMax,  int? depthMinM,  int? depthMaxM,  String? minCertification,  String? bookingCode,  int? maxParticipants,  String bookingStatus,  String? photoUrl,  String? diveCenterId,  int? priceMinor,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.joined,_that.creatorUserId,_that.participantCount,_that.unreadCount,_that.endDate,_that.description,_that.meetingPoint,_that.diveCountMin,_that.diveCountMax,_that.depthMinM,_that.depthMaxM,_that.minCertification,_that.bookingCode,_that.maxParticipants,_that.bookingStatus,_that.photoUrl,_that.diveCenterId,_that.priceMinor,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String location,  DateTime startTime,  bool joined,  String? creatorUserId,  int participantCount,  int unreadCount,  DateTime? endDate,  String? description,  String? meetingPoint,  int? diveCountMin,  int? diveCountMax,  int? depthMinM,  int? depthMaxM,  String? minCertification,  String? bookingCode,  int? maxParticipants,  String bookingStatus,  String? photoUrl,  String? diveCenterId,  int? priceMinor,  String currency)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.joined,_that.creatorUserId,_that.participantCount,_that.unreadCount,_that.endDate,_that.description,_that.meetingPoint,_that.diveCountMin,_that.diveCountMax,_that.depthMinM,_that.depthMaxM,_that.minCertification,_that.bookingCode,_that.maxParticipants,_that.bookingStatus,_that.photoUrl,_that.diveCenterId,_that.priceMinor,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String location,  DateTime startTime,  bool joined,  String? creatorUserId,  int participantCount,  int unreadCount,  DateTime? endDate,  String? description,  String? meetingPoint,  int? diveCountMin,  int? diveCountMax,  int? depthMinM,  int? depthMaxM,  String? minCertification,  String? bookingCode,  int? maxParticipants,  String bookingStatus,  String? photoUrl,  String? diveCenterId,  int? priceMinor,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.title,_that.location,_that.startTime,_that.joined,_that.creatorUserId,_that.participantCount,_that.unreadCount,_that.endDate,_that.description,_that.meetingPoint,_that.diveCountMin,_that.diveCountMax,_that.depthMinM,_that.depthMaxM,_that.minCertification,_that.bookingCode,_that.maxParticipants,_that.bookingStatus,_that.photoUrl,_that.diveCenterId,_that.priceMinor,_that.currency);case _:
  return null;

}
}

}

/// @nodoc


class _Trip implements Trip {
  const _Trip({required this.id, required this.title, required this.location, required this.startTime, required this.joined, this.creatorUserId, this.participantCount = 0, this.unreadCount = 0, this.endDate, this.description, this.meetingPoint, this.diveCountMin, this.diveCountMax, this.depthMinM, this.depthMaxM, this.minCertification, this.bookingCode, this.maxParticipants, this.bookingStatus = 'open', this.photoUrl, this.diveCenterId, this.priceMinor, this.currency = 'DKK'});
  

@override final  String id;
@override final  String title;
@override final  String location;
@override final  DateTime startTime;
@override final  bool joined;
@override final  String? creatorUserId;
@override@JsonKey() final  int participantCount;
@override@JsonKey() final  int unreadCount;
@override final  DateTime? endDate;
@override final  String? description;
@override final  String? meetingPoint;
@override final  int? diveCountMin;
@override final  int? diveCountMax;
@override final  int? depthMinM;
@override final  int? depthMaxM;
@override final  String? minCertification;
@override final  String? bookingCode;
@override final  int? maxParticipants;
@override@JsonKey() final  String bookingStatus;
@override final  String? photoUrl;
// Business fields — always present for a trip created from admin/, since admin never
// creates an individual trip. Not yet read by app/'s own Trip entity (see CLAUDE.md's
// Business/dive centers section) — that's a separate, still-pending piece of work.
@override final  String? diveCenterId;
@override final  int? priceMinor;
@override@JsonKey() final  String currency;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.joined, joined) || other.joined == joined)&&(identical(other.creatorUserId, creatorUserId) || other.creatorUserId == creatorUserId)&&(identical(other.participantCount, participantCount) || other.participantCount == participantCount)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.meetingPoint, meetingPoint) || other.meetingPoint == meetingPoint)&&(identical(other.diveCountMin, diveCountMin) || other.diveCountMin == diveCountMin)&&(identical(other.diveCountMax, diveCountMax) || other.diveCountMax == diveCountMax)&&(identical(other.depthMinM, depthMinM) || other.depthMinM == depthMinM)&&(identical(other.depthMaxM, depthMaxM) || other.depthMaxM == depthMaxM)&&(identical(other.minCertification, minCertification) || other.minCertification == minCertification)&&(identical(other.bookingCode, bookingCode) || other.bookingCode == bookingCode)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.bookingStatus, bookingStatus) || other.bookingStatus == bookingStatus)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.diveCenterId, diveCenterId) || other.diveCenterId == diveCenterId)&&(identical(other.priceMinor, priceMinor) || other.priceMinor == priceMinor)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,location,startTime,joined,creatorUserId,participantCount,unreadCount,endDate,description,meetingPoint,diveCountMin,diveCountMax,depthMinM,depthMaxM,minCertification,bookingCode,maxParticipants,bookingStatus,photoUrl,diveCenterId,priceMinor,currency]);

@override
String toString() {
  return 'Trip(id: $id, title: $title, location: $location, startTime: $startTime, joined: $joined, creatorUserId: $creatorUserId, participantCount: $participantCount, unreadCount: $unreadCount, endDate: $endDate, description: $description, meetingPoint: $meetingPoint, diveCountMin: $diveCountMin, diveCountMax: $diveCountMax, depthMinM: $depthMinM, depthMaxM: $depthMaxM, minCertification: $minCertification, bookingCode: $bookingCode, maxParticipants: $maxParticipants, bookingStatus: $bookingStatus, photoUrl: $photoUrl, diveCenterId: $diveCenterId, priceMinor: $priceMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String location, DateTime startTime, bool joined, String? creatorUserId, int participantCount, int unreadCount, DateTime? endDate, String? description, String? meetingPoint, int? diveCountMin, int? diveCountMax, int? depthMinM, int? depthMaxM, String? minCertification, String? bookingCode, int? maxParticipants, String bookingStatus, String? photoUrl, String? diveCenterId, int? priceMinor, String currency
});




}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? location = null,Object? startTime = null,Object? joined = null,Object? creatorUserId = freezed,Object? participantCount = null,Object? unreadCount = null,Object? endDate = freezed,Object? description = freezed,Object? meetingPoint = freezed,Object? diveCountMin = freezed,Object? diveCountMax = freezed,Object? depthMinM = freezed,Object? depthMaxM = freezed,Object? minCertification = freezed,Object? bookingCode = freezed,Object? maxParticipants = freezed,Object? bookingStatus = null,Object? photoUrl = freezed,Object? diveCenterId = freezed,Object? priceMinor = freezed,Object? currency = null,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,joined: null == joined ? _self.joined : joined // ignore: cast_nullable_to_non_nullable
as bool,creatorUserId: freezed == creatorUserId ? _self.creatorUserId : creatorUserId // ignore: cast_nullable_to_non_nullable
as String?,participantCount: null == participantCount ? _self.participantCount : participantCount // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,meetingPoint: freezed == meetingPoint ? _self.meetingPoint : meetingPoint // ignore: cast_nullable_to_non_nullable
as String?,diveCountMin: freezed == diveCountMin ? _self.diveCountMin : diveCountMin // ignore: cast_nullable_to_non_nullable
as int?,diveCountMax: freezed == diveCountMax ? _self.diveCountMax : diveCountMax // ignore: cast_nullable_to_non_nullable
as int?,depthMinM: freezed == depthMinM ? _self.depthMinM : depthMinM // ignore: cast_nullable_to_non_nullable
as int?,depthMaxM: freezed == depthMaxM ? _self.depthMaxM : depthMaxM // ignore: cast_nullable_to_non_nullable
as int?,minCertification: freezed == minCertification ? _self.minCertification : minCertification // ignore: cast_nullable_to_non_nullable
as String?,bookingCode: freezed == bookingCode ? _self.bookingCode : bookingCode // ignore: cast_nullable_to_non_nullable
as String?,maxParticipants: freezed == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int?,bookingStatus: null == bookingStatus ? _self.bookingStatus : bookingStatus // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,diveCenterId: freezed == diveCenterId ? _self.diveCenterId : diveCenterId // ignore: cast_nullable_to_non_nullable
as String?,priceMinor: freezed == priceMinor ? _self.priceMinor : priceMinor // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
