import '../../domain/entities/trip.dart';
import '../models/trip_api_model.dart';

extension TripApiMapper on TripApiModel {
  Trip toDomain() => Trip(
        id: id,
        title: title,
        location: location,
        startTime: startTime,
        joined: joined,
        creatorUserId: creatorUserId,
        participantCount: participantCount,
      );
}
