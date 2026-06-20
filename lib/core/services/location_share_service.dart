import 'package:geolocator/geolocator.dart';

/// Captures the user's current position for sharing in chat / group chat.
///
/// Encapsulates the geolocator permission dance so both the 1:1 and group chat
/// screens share one tested path. Returns null if location is unavailable or
/// permission is denied (callers show a localized message).
class LocationShareService {
  const LocationShareService();

  /// Returns the current position, or null if unavailable / denied.
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      // Fall back to last known position if a fresh fix times out.
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Builds the message payload for a shared location.
  /// `content` is "lat,lng" (human/preview friendly); metadata carries doubles.
  static Map<String, dynamic> metadataFor(double lat, double lng) => {
        'isLocation': true,
        'lat': lat,
        'lng': lng,
      };

  /// A maps deep link for opening a shared location.
  static String mapsUrl(double lat, double lng) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  /// Parse "lat,lng" from a location message's content; null if malformed.
  static ({double lat, double lng})? parse(String content) {
    final parts = content.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
}
