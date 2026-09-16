import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Used only as a guest profile placeholder, so any failure (permission denied, services off, no result) just means no location shown rather than an error.
class LocationService {
  final _geocoding = Geocoding();

  /// Used by Explore's "Nearest" sort, which needs coordinates rather than a display string.
  Future<Position?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      // Without a time limit this can hang indefinitely waiting for a fix that never arrives (e.g. an Android emulator with no location set, or poor real-device GPS signal).
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
    } catch (_) {
      return null;
    }
  }

  /// True only for the re-askable "denied" state, not deniedForever or already-granted, since neither of those benefits from prompting again.
  Future<bool> permissionUndecided() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied;
  }

  Future<String?> currentCityCountry() async {
    try {
      final position = await currentPosition();
      if (position == null) return null;

      // No built-in timeout on the geocoding call itself, so a stalled network could otherwise hang this well past getCurrentPosition's own 10s limit above.
      final placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 10));
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
