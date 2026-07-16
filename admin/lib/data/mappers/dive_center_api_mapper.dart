import '../../domain/entities/dive_center.dart';
import '../models/dive_center_api_model.dart';

extension DiveCenterApiMapper on DiveCenterApiModel {
  DiveCenter toDomain() => DiveCenter(
        id: id,
        name: name,
        location: location,
        description: description,
        logoUrl: logoUrl,
        agency: agency,
        agencyDetail: agencyDetail,
        languages: languages,
        website: website,
        phone: phone,
        email: email,
        createdAt: createdAt,
        role: role ?? '',
      );
}
