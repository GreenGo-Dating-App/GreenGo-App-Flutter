import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/web_location_fallback.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';

void main() {
  group('publicDisplayAddress', () {
    test('keeps a normal place label', () {
      expect(publicDisplayAddress('Milan, Italy', city: 'Milan', country: 'Italy'),
          'Milan, Italy');
    });

    test('web browser fallback "lat, lng" never goes public', () {
      expect(publicDisplayAddress('45.4642, 9.1900'), '');
      expect(
          publicDisplayAddress('45.4642, 9.1900', city: '', country: 'Italy'),
          'Italy');
    });

    test('traveller picker labels lose their coordinates', () {
      expect(
          publicDisplayAddress('Lisbon (38.7223, -9.1393)', city: 'Lisbon'),
          'Lisbon');
      expect(
          publicDisplayAddress(
              '38.7223, -9.1393 — could not resolve address'),
          '');
      expect(publicDisplayAddress('Lisbon (38.7223, -9.1393)'), 'Lisbon');
    });
  });

  group('publicSafeProfileJson scrubs coordinate labels', () {
    test('set (nested)', () {
      final out = publicSafeProfileJson({
        'location': {
          'latitude': 45.4642,
          'longitude': 9.19,
          'city': '',
          'country': '',
          'displayAddress': '45.4642, 9.1900',
        },
      });
      final loc = out['location'] as Map;
      expect(loc.containsKey('latitude'), isFalse);
      expect(loc['displayAddress'], '');
    });

    test('update (dotted)', () {
      final out = publicSafeProfileJson({
        'travelerLocation': {
          'latitude': 38.7223,
          'longitude': -9.1393,
          'city': 'Lisbon',
          'country': 'Portugal',
          'displayAddress': '38.722300, -9.139300',
        },
      }, forUpdate: true);
      expect(out['travelerLocation.displayAddress'], 'Lisbon, Portugal');
      expect(out.containsKey('travelerLocation.latitude'), isFalse);
    });
  });

  test('Nominatim gets the browser position rounded to ~1 km', () {
    expect(WebLocationFallback.coarseCoordinate(45.464213), '45.46');
    expect(WebLocationFallback.coarseCoordinate(-9.139312), '-9.14');
  });
}
