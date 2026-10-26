import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/discovery/domain/discovery_visibility.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/data/store_visibility_view.dart';
import 'package:greengo_chat/features/profile/domain/entities/store_visibility.dart';

import '../../support/profile_fixtures.dart';

Map<String, dynamic> _store(String? visibility) => {
      'userId': 'shop1',
      'displayName': 'Ana Lima',
      'isBusiness': true,
      'businessName': 'Café Ana',
      'businessLogoUrl': 'https://x/logo.jpg',
      'businessAddress': {'address': 'Rua A 1', 'latitude': -23.5, 'longitude': -46.6},
      if (visibility != null) 'storeVisibility': visibility,
    };

void main() {
  late String? viewer;
  setUp(() {
    viewer = 'someone';
    storeViewerUid = () => viewer;
  });

  test('wire values; missing or unknown = visible', () {
    expect(StoreVisibility.fromWire(null), StoreVisibility.visible);
    expect(StoreVisibility.fromWire('nonsense'), StoreVisibility.visible);
    expect(StoreVisibility.fromWire('hidden'), StoreVisibility.hiddenFromDiscovery);
    expect(StoreVisibility.fromWire('off'), StoreVisibility.fullyHidden);
  });

  test('fully hidden: other viewers read a personal profile without the store face', () {
    final p = ProfileModel.fromJson(_store('off'));
    expect(p.isBusiness, isFalse);
    expect(p.businessName, isNull);
    expect(p.businessLogoOrNull, isNull);
    expect(p.businessAddress, isNull);
    expect(p.displayName, 'Ana Lima');
  });

  test('fully hidden: the owner still gets the real store', () {
    viewer = 'shop1';
    final p = ProfileModel.fromJson(_store('off'));
    expect(p.isBusiness, isTrue);
    expect(p.businessName, 'Café Ana');
    expect(p.storeVisibility, StoreVisibility.fullyHidden);
  });

  test('fully hidden with no known viewer (signed out) is still masked', () {
    viewer = null;
    expect(ProfileModel.fromJson(_store('off')).isBusiness, isFalse);
  });

  test('hidden from Discover: still a store, but not discoverable', () {
    final p = ProfileModel.fromJson(_store('hidden'));
    expect(p.isBusiness, isTrue);
    expect(p.businessName, 'Café Ana');
    expect(DiscoveryVisibility.isStoreHidden(p), isTrue);
  });

  test('visible (default): discoverable', () {
    final p = ProfileModel.fromJson(_store(null));
    expect(p.storeVisibility, StoreVisibility.visible);
    expect(DiscoveryVisibility.isStoreHidden(p), isFalse);
  });

  test('isVisible drops a hidden store, keeps a visible one', () {
    final shop = buildBusinessProfile();
    expect(DiscoveryVisibility.isStoreHidden(shop), isFalse);
    final hidden = shop.copyWith(storeVisibility: StoreVisibility.hiddenFromDiscovery);
    // Same profile, only the owner's choice differs.
    expect(DiscoveryVisibility.isVisible(shop, viewerId: 'viewer', viewerIsPrivileged: true), isTrue);
    expect(DiscoveryVisibility.isVisible(hidden, viewerId: 'viewer', viewerIsPrivileged: true), isFalse);
  });

  test('a full-profile save never writes storeVisibility (only its own switch does)', () {
    final p = ProfileModel.fromJson(_store('hidden'));
    expect(p.toJson().containsKey('storeVisibility'), isFalse);
  });
}
