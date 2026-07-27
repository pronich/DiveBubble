import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Best-effort "city, country" from the device's current location — used only as a guest
/// profile placeholder, so any failure (permission denied, services off, no result) just
/// means no location shown rather than an error the user has to deal with.
class LocationService {
  final _geocoding = Geocoding();

  /// Raw device position — used by Explore's "Nearest" sort, which needs coordinates to
  /// compute distance against, not a display string. Same permission handling as
  /// [currentCityCountry]; any failure (permission denied, services off) returns null.
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

      // Without a time limit this can hang indefinitely waiting for a fix that never
      // arrives — a fresh Android emulator with no location set is the easiest way to hit
      // it, but a real device with poor GPS signal (indoors, cold start) can too, and every
      // caller here disables its own "skip/not now" escape hatch while awaiting this.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
    } catch (_) {
      return null;
    }
  }

  /// True if this device has never been asked (or was asked and declined once, but could
  /// still be re-asked) — deniedForever and already-granted are both false, since neither
  /// benefits from prompting again. Used to decide whether a returning diver on a new
  /// device/reinstall should see the "why" explanation before the OS dialog, same as a
  /// brand-new account does (see LoginSheet).
  Future<bool> permissionUndecided() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied;
  }

  Future<String?> currentCityCountry() async {
    try {
      final position = await currentPosition();
      if (position == null) return null;

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
