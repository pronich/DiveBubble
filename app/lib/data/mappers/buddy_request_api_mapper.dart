import '../../domain/entities/buddy_request.dart';
import '../models/buddy_request_api_model.dart';

extension BuddyRequestApiMapper on BuddyRequestApiModel {
  BuddyRequest toDomain() => BuddyRequest(
        id: id,
        tripId: tripId,
        userId: userId,
        createdAt: createdAt,
        joinedCount: joinedCount,
        joined: joined,
        maxMembers: maxMembers,
        creatorName: creatorName,
        creatorLevel: creatorLevel,
        creatorDiveCount: creatorDiveCount,
      );
}
