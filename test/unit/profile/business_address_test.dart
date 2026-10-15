import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/place_search_service.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';

import '../../support/profile_fixtures.dart';

void main() {
  const shop = BusinessAddress(
    address: 'Rua Augusta 1500',
    latitude: -23.5596,
    longitude: -46.6588,
    city: 'São Paulo',
    country: 'Brazil',
    placeId: 'gp_123',
  );

  test('map round trip, with a precision-9 geohash for nearest-first queries', () {
    final m = shop.toMap();
    expect(m['geohash'], isA<String>());
    expect((m['geohash'] as String).length, 9);
    expect(BusinessAddress.fromMap(m), shop);
  });

  test('from the event-style picker', () {
    const p = PickedPlace(address: 'Via Roma 1', lat: 45.07, lng: 7.68, city: 'Torino', country: 'Italy');
    final a = BusinessAddress.fromPicked(p);
    expect(a.latitude, 45.07);
    expect(a.placeId, isNull);
    expect(a.summary, 'Via Roma 1, Torino');
  });

  test('summary does not repeat a city already in the address', () {
    expect(shop.copyWithAddress('Rua Augusta 1500, São Paulo').summary, 'Rua Augusta 1500, São Paulo');
  });

  test('unusable data is ignored', () {
    expect(BusinessAddress.fromMap(null), isNull);
    expect(BusinessAddress.fromMap({'address': 'x'}), isNull);
    expect(BusinessAddress.fromMap({'address': 'x', 'latitude': 0, 'longitude': 0}), isNull);
    expect(BusinessAddress.fromMap({'address': 'x', 'latitude': 99, 'longitude': 10}), isNull);
    expect(BusinessAddress.fromMap({'address': ' ', 'latitude': 10, 'longitude': 10}), isNull);
  });

  test('ProfileModel saves and reads it; clearing removes it', () {
    final withAddr = buildBusinessProfile().copyWith(businessAddress: shop);
    final json = ProfileModel.fromEntity(withAddr).toJson();
    expect((json['businessAddress'] as Map)['address'], 'Rua Augusta 1500');
    expect(ProfileModel.fromJson(json).businessAddress, shop);

    final cleared = withAddr.copyWith(clearBusinessAddress: true);
    expect(cleared.businessAddress, isNull);
    expect(ProfileModel.fromEntity(cleared).toJson()['businessAddress'], isNull);
  });
}

extension on BusinessAddress {
  BusinessAddress copyWithAddress(String a) =>
      BusinessAddress(address: a, latitude: latitude, longitude: longitude, city: city, country: country, placeId: placeId);
}
