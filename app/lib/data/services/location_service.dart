import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Best-effort "city, country" from the device's current location — used only as a guest
/// profile placeholder, so any failure (permission denied, services off, no result) just
/// means no location shown rather than an error the user has to deal with.
class LocationService {
  final _geocoding = Geocoding();

  Future<String?> currentCityCountry() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final placemarks = await _geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final city = place.locality?.isNotEmpty ?? false ? place.locality! : place.administrativeArea;
      final country = place.country;
      if (city == null && country == null) return null;
      if (city == null) return country;
      if (country == null) return city;
      return '$city, $country';
    } catch (_) {
      return null;
    }
  }
}
