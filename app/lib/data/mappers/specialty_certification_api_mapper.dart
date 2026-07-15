import '../../domain/entities/specialty_certification.dart';
import '../models/specialty_certification_api_model.dart';

extension SpecialtyCertificationApiMapper on SpecialtyCertificationApiModel {
  SpecialtyCertification toDomain() => SpecialtyCertification(
        id: id,
        specialty: specialty,
        customLabel: customLabel,
        agency: agency,
        certNumber: certNumber,
        photoUrl: photoUrl,
        verified: verified,
        createdAt: createdAt,
      );
}
