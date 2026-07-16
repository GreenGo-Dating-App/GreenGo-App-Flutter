import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/profile/data/models/profile_model.dart';

import '../../support/search_fixtures.dart';

/// Master Test Plan — Universal Search over a fake Firestore.
/// Seeds real `profiles` docs, reads them back through
/// [ProfileModel.fromFirestore] (the same codec the screen uses in `absorb()`),
/// applies the People pipeline, and asserts the excluded accounts never leak
/// while a business owner surfaces in both People and Business.
void main() {
  const me = 'me_uid';

  Future<List<ProfileModel>> seed() async {
    return [
      buildProfile(userId: me, displayName: 'Me Myself', nickname: 'me'),
      buildProfile(userId: 'ava', displayName: 'Ava Reyes', nickname: 'ava'),
      buildProfile(
          userId: 'bruno', displayName: 'Bruno Costa', nickname: 'bruno'),
      buildProfile(
          userId: 'ghost',
          displayName: 'Ghosty',
          nickname: 'ghost',
          isGhostMode: true),
      buildProfile(
          userId: 'admin', displayName: 'GreenGo Admin', isAdmin: true),
      buildProfile(
          userId: 'support', displayName: 'GreenGo Support', isSupport: true),
      buildProfile(
          userId: 'deleted',
          displayName: 'Deleted Dan',
          accountStatus: 'deleted'),
      buildProfile(
        userId: 'elena',
        displayName: 'Elena Marco',
        nickname: 'elena',
        isBusiness: true,
        businessName: "Elena's Cafe",
        businessCategory: 'Cafe',
      ),
    ];
  }

  test('excluded accounts never appear in People results', () async {
    final db = await seedProfiles(await seed());
    final all = await readProfiles(db);

    final people = runPeoplePipeline(all, currentUserId: me);
    final ids = people.map((p) => p.userId).toSet();

    expect(ids, containsAll(['ava', 'bruno', 'elena']));
    expect(ids, isNot(contains(me)), reason: 'self excluded');
    expect(ids, isNot(contains('ghost')), reason: 'ghost-mode excluded');
    expect(ids, isNot(contains('admin')), reason: 'admin excluded');
    expect(ids, isNot(contains('support')), reason: 'support excluded');
    expect(ids, isNot(contains('deleted')),
        reason: 'non-active accountStatus excluded');
  });

  test('a business profile surfaces in BOTH People and Business', () async {
    final db = await seedProfiles(await seed());
    final all = await readProfiles(db);

    final people = runPeoplePipeline(all, currentUserId: me);
    final business = businessSubset(people);

    expect(people.any((p) => p.userId == 'elena'), isTrue,
        reason: 'business owner is still a searchable person');
    expect(business.map((p) => p.userId), ['elena']);
    expect(business.single.businessName, "Elena's Cafe");
  });

  test('ProfileModel round-trips through the fake Firestore doc', () async {
    final db = await seedProfiles(await seed());
    final doc = await db.collection('profiles').doc('elena').get();

    final p = ProfileModel.fromFirestore(doc);

    expect(p.userId, 'elena');
    expect(p.displayName, 'Elena Marco');
    expect(p.nickname, 'elena');
    expect(p.isBusiness, isTrue);
    expect(p.businessName, "Elena's Cafe");
    expect(p.accountStatus, 'active');
    // Location survives the countryLower denormalization on write.
    expect(p.location.city, 'Lisbon');
    expect(p.location.country, 'Portugal');
  });

  test('results are sorted by lowercased displayName', () async {
    final db = await seedProfiles(await seed());
    final all = await readProfiles(db);

    final people = runPeoplePipeline(all, currentUserId: me);
    final names = people.map((p) => p.displayName.toLowerCase()).toList();
    final sorted = [...names]..sort();
    expect(names, sorted);
  });
}
