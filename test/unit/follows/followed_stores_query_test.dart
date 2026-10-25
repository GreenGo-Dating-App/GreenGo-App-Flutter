import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';

/// FollowService.followedStoresPage (search + filters on the server-written
/// store fields) and the owner-only place facets.
void main() {
  late FakeFirebaseFirestore fs;
  late FollowService service;
  const uid = 'me';

  Future<void> store(String id,
      {required String name,
      String category = '',
      String country = '',
      String city = '',
      bool stamped = true}) async {
    await fs
        .collection('user_business_following')
        .doc(uid)
        .collection('businesses')
        .doc(id)
        .set({
      'createdAt': 1,
      'isStore': true,
      if (stamped) ...{
        'storeNameLower': name,
        'storeCategory': category,
        'storeCountry': country,
        'storeCityLower': city,
      },
    });
  }

  setUp(() async {
    fs = FakeFirebaseFirestore();
    service = FollowService(firestore: fs, overlay: FollowCountOverlay());
    await store('s1', name: 'cafe roma', category: 'Cafe', country: 'Italy', city: 'rome');
    await store('s2', name: 'caffe milano', category: 'Cafe', country: 'Italy', city: 'milan');
    await store('s3', name: 'casa porto', category: 'Bar', country: 'Portugal', city: 'porto');
    await store('s4', name: 'roma bar', category: 'Bar', country: 'Italy', city: 'rome');
  });

  Future<List<String>> ids(StoreFilter f, {int limit = 30}) async =>
      (await service.followedStoresPage(uid, filter: f, limit: limit)).userIds;

  // (Real Firestore leaves docs WITHOUT storeNameLower out of the ordered
  // search / filter queries; the fake cannot order over a missing field, so
  // the not-yet-backfilled mirror only exists in this test.)
  test('plain list: every store (isStore), never a personal account', () async {
    // Not backfilled yet: still in the plain list.
    await store('s5', name: '', stamped: false);
    // A personal account the user follows: never a store.
    await fs
        .collection('user_business_following')
        .doc(uid)
        .collection('businesses')
        .doc('person')
        .set({'createdAt': 1});
    expect(await ids(const StoreFilter()), ['s1', 's2', 's3', 's4', 's5']);
  });

  test('prefix search over ALL followed stores, accent / case-insensitive', () async {
    expect(await ids(const StoreFilter(query: 'CAF')), ['s1', 's2']);
    expect(await ids(const StoreFilter(query: 'Rôma')), ['s4']);
    expect(await ids(const StoreFilter(query: 'zzz')), isEmpty);
  });

  test('category / country / city filters, combined with the search', () async {
    expect(await ids(const StoreFilter(category: 'Bar')), ['s3', 's4']);
    expect(await ids(const StoreFilter(country: 'Italy')), ['s1', 's2', 's4']);
    expect(await ids(const StoreFilter(country: 'Italy', cityLower: 'rome')), ['s1', 's4']);
    expect(await ids(const StoreFilter(category: 'Cafe', country: 'Italy')), ['s1', 's2']);
    expect(
        await ids(const StoreFilter(query: 'ro', category: 'Bar', country: 'Italy', cityLower: 'rome')),
        ['s4']);
    // A city without its country is ignored (never queried alone).
    expect(const StoreFilter(cityLower: 'rome').isEmpty, isTrue);
  });

  test('pages with a cursor', () async {
    const f = StoreFilter(country: 'Italy');
    final p1 = await service.followedStoresPage(uid, filter: f, limit: 2);
    expect(p1.userIds, ['s1', 's2']);
    expect(p1.hasMore, isTrue);
    final p2 = await service.followedStoresPage(uid, filter: f, limit: 2, after: p1.cursor);
    expect(p2.userIds, ['s4']);
    expect(p2.hasMore, isFalse);
  });

  test('StoreFilter equality ignores how the query was typed', () {
    expect(const StoreFilter(query: ' Café '), const StoreFilter(query: 'cafe'));
    expect(const StoreFilter(country: 'Italy', cityLower: 'rome'),
        isNot(const StoreFilter(country: 'Italy')));
  });

  test('place facets: countries most stores first, cities of one country', () async {
    final places = fs.collection('user_store_places').doc(uid);
    await places.collection('countries').doc('a').set({'country': 'Portugal', 'n': 1});
    await places.collection('countries').doc('b').set({'country': 'Italy', 'n': 3});
    await places.collection('cities').doc('c').set(
        {'country': 'Italy', 'city': 'Rome', 'cityLower': 'rome', 'n': 2});
    await places.collection('cities').doc('d').set(
        {'country': 'Italy', 'city': 'Milan', 'cityLower': 'milan', 'n': 1});
    await places.collection('cities').doc('e').set(
        {'country': 'Portugal', 'city': 'Porto', 'cityLower': 'porto', 'n': 1});

    final countries = await service.followedStoreCountries(uid);
    expect(countries.map((p) => '${p.country}:${p.count}'), ['Italy:3', 'Portugal:1']);
    final cities = await service.followedStoreCities(uid, 'Italy');
    expect(cities.map((p) => '${p.city}/${p.cityLower}:${p.count}'), ['Rome/rome:2', 'Milan/milan:1']);
    expect(await service.followedStoreCities(uid, ''), isEmpty);
  });
}
