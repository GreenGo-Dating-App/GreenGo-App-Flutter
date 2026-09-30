import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/data/datasources/people_tags_service.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late PeopleTagsService svc;

  setUp(() {
    PeopleTagsService.clearCache();
    fs = FakeFirebaseFirestore();
    svc = PeopleTagsService(firestore: fs);
  });

  test('library lists distinct tags, most-recently-used first', () async {
    await svc.setTagsForPerson(
        ownerId: 'me', targetUserId: 'a', tags: ['Work'], bump: ['Work']);
    await svc.setTagsForPerson(
        ownerId: 'me', targetUserId: 'b', tags: ['Gym'], bump: ['Gym']);
    await svc.setTagsForPerson(
        ownerId: 'me',
        targetUserId: 'c',
        tags: ['work', 'Travel'],
        bump: ['Travel']);

    final lib = svc.cachedLibrary('me')!;
    expect(lib.allTags, ['Travel', 'Gym', 'Work']);
    expect(lib.tagsFor('c'), ['work', 'Travel']);

    // Persisted and re-read from a cold cache in the same order.
    PeopleTagsService.clearCache();
    final cold = await svc.getLibrary('me');
    expect(cold.allTags, ['Travel', 'Gym', 'Work']);
  });

  test('legacy docs without recentTags rank by usage then A-Z', () async {
    await fs.collection('user_people_tags').doc('me').set({
      'peopleTags': {
        'a': ['Zeta', 'Alpha'],
        'b': ['Zeta'],
      },
    });
    final lib = await svc.getLibrary('me');
    expect(lib.allTags, ['Zeta', 'Alpha']);
  });

  test('tags no longer applied to anyone drop out of the library', () async {
    await svc.setTagsForPerson(
        ownerId: 'me', targetUserId: 'a', tags: ['Work'], bump: ['Work']);
    await svc.setTagsForPerson(ownerId: 'me', targetUserId: 'a', tags: []);
    expect((await svc.getLibrary('me')).allTags, isEmpty);
  });
}
