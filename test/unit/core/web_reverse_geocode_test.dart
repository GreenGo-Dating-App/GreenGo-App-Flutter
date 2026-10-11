import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/web_location_fallback.dart';

/// Legal audit 2026-10: web reverse geocoding goes through the
/// `reverseGeocodeCoarse` callable with ~1 km coordinates, never straight
/// from the browser to Nominatim with the exact fix.
void main() {
  final original = WebLocationFallback.reverseCall;
  tearDown(() => WebLocationFallback.reverseCall = original);

  test('only rounded coordinates are sent; exact ones stay on the Location',
      () async {
    final sent = <List<double>>[];
    WebLocationFallback.reverseCall = (lat, lng) async {
      sent.add([lat, lng]);
      return {'success': true, 'city': 'Lisbon', 'country': 'Portugal'};
    };
    final loc = await WebLocationFallback.reverseGeocode(38.722301, -9.139337);
    expect(sent, [
      [38.72, -9.14]
    ]);
    expect(loc!.city, 'Lisbon');
    expect(loc.country, 'Portugal');
    expect(loc.latitude, 38.722301);
  });

  test('nothing resolved or a failure returns null', () async {
    WebLocationFallback.reverseCall =
        (lat, lng) async => {'success': true, 'city': '', 'country': ''};
    expect(await WebLocationFallback.reverseGeocode(1.5, 2.5), isNull);
    WebLocationFallback.reverseCall = (lat, lng) async => throw Exception('x');
    expect(await WebLocationFallback.reverseGeocode(1.5, 2.5), isNull);
  });
}
