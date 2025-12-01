import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Attempts to get a current position with a timeout and reasonable fallbacks.
  /// Returns null if no usable location is available.
  static Future<Position?> getPositionWithFallback({Duration timeout = const Duration(seconds: 12)}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: timeout);
        return pos;
      } catch (_) {
        // Transient error / timeout - try last known position
        final last = await Geolocator.getLastKnownPosition();
        return last;
      }
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
