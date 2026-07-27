import '../../domain/entities/profile.dart';
import '../models/profile_api_model.dart';

extension ProfileApiMapper on ProfileApiModel {
  Profile toDomain() => Profile(
        id: id,
        displayName: displayName,
        avatarUrl: avatarUrl,
        location: location,
        bio: bio,
        diveCount: diveCount,
        certificationLevel: certificationLevel,
        certificationAgency: certificationAgency,
        certificationNumber: certificationNumber,
        certificationPhotoUrl: certificationPhotoUrl,
        certificationVerified: certificationVerified,
        languages: languages,
        memberSince: memberSince,
        isProductObserver: isProductObserver,
      );
}
