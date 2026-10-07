import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/passport/data/services/passport_service.dart';

void main() {
  group('PassportService.visitedCountries', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    Future<List<dynamic>?> stored(String uid) async =>
        (await db.collection('user_passports').doc(uid).get())
            .data()?[PassportService.visitedCountriesField] as List<dynamic>?;

    test('counts the current real country and records it', () async {
      await db.collection('profiles').doc('u1').set({
        'location': {'country': 'Brazil'},
        // Traveler mode is virtual: it must not count as visited.
        'isTraveler': true,
        'travelerLocation': {'country': 'Japan'},
      });

      final visited = await PassportService(firestore: db).visitedCountries('u1');

      expect(visited, {'BR'});
      expect(await stored('u1'), ['BR']);
    });

    test('merges stored visits with the current country, no duplicates',
        () async {
      await db.collection('profiles').doc('u1').set({
        'location': {'country': 'Italy'},
      });
      await db.collection('user_passports').doc('u1').set({
        PassportService.visitedCountriesField: ['BR', 'IT'],
      });

      final visited = await PassportService(firestore: db).visitedCountries('u1');

      expect(visited, {'BR', 'IT'});
      expect(await stored('u1'), ['BR', 'IT']);
    });

    test('recordVisitedCountry adds a new country once', () async {
      final service = PassportService(firestore: db);
      await service.recordVisitedCountry('u1', 'France');
      await service.recordVisitedCountry('u1', 'FR');
      await service.recordVisitedCountry('u1', '');

      expect(await stored('u1'), ['FR']);
    });
  });
}
