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
        unreadCount: unreadCount,
        endDate: endDate,
        description: description,
        meetingPoint: meetingPoint,
        diveCountMin: diveCountMin,
        diveCountMax: diveCountMax,
        depthMinM: depthMinM,
        depthMaxM: depthMaxM,
        minCertification: minCertification,
        bookingCode: bookingCode,
        maxParticipants: maxParticipants,
        bookingStatus: bookingStatus,
        photoUrl: photoUrl,
        diveCenterId: diveCenterId,
        priceMinor: priceMinor,
        currency: currency,
      );
}
