import '../../domain/entities/trip_photo.dart';
import '../models/trip_photo_api_model.dart';

extension TripPhotoApiMapper on TripPhotoApiModel {
  TripPhoto toDomain() => TripPhoto(id: id, url: url, position: position);
}
