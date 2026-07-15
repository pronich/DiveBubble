import '../../domain/entities/gear_ownership.dart';
import '../models/gear_ownership_api_model.dart';

extension GearOwnershipApiMapper on GearOwnershipApiModel {
  GearOwnership toDomain() => GearOwnership(itemKey: itemKey, status: status);
}
