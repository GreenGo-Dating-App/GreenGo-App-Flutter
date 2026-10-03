import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/user_experiences/data/datasources/user_experiences_remote_datasource.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';

/// Experiences posted in a community: the listing query (published, this
/// community, pictures only, newest first, paged 20), the host-only drafts,
/// the fail-safe fallback while the composite index builds, and the
/// create-only / immutable community link in the payloads.
Map<String, dynamic> _doc({
  required String communityId,
  String status = 'published',
  String hostId = 'h1',
  String photo = 'https://cdn.example.com/p.jpg',
  required int minute,
}) =>
    {
      'communityId': communityId,
      'communityName': 'Lisbon Foodies',
      'status': status,
      'hostId': hostId,
      'title': 'Experience $minute',
      'description': 'x' * 40,
      'category': 'foodDrink',
      'mainPhotoUrl': photo,
      'included': ['Snacks'],
      'locationName': 'Lisbon',
      'durationMinutes': 60,
      'languages': ['English'],
      'maxGroupSize': 5,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1, 0, minute)),
    };

class _ThrowingPager implements ExperienceFeedPager {
  int calls = 0;
  @override
  bool get hasMore => true;
  @override
  Future<List<UserExperience>> next() async {
    calls++;
    throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'The query requires an index.');
  }
}

class _DeniedPager implements ExperienceFeedPager {
  @override
  bool get hasMore => true;
  @override
  Future<List<UserExperience>> next() async => throw FirebaseException(
      plugin: 'cloud_firestore', code: 'permission-denied');
}

void main() {
  late FakeFirebaseFirestore db;
  late UserExperiencesRemoteDataSource ds;

  setUp(() {
    db = FakeFirebaseFirestore();
    ds = UserExperiencesRemoteDataSource(firestore: db);
  });

  test('lists only published experiences of the community, newest first',
      () async {
    final col = db.collection('user_experiences');
    await col.doc('a').set(_doc(communityId: 'c1', minute: 1));
    await col.doc('b').set(_doc(communityId: 'c1', minute: 3));
    await col
        .doc('draft')
        .set(_doc(communityId: 'c1', minute: 5, status: 'draft'));
    await col.doc('other').set(_doc(communityId: 'c2', minute: 4));
    await col.doc('nopic').set(_doc(communityId: 'c1', minute: 2, photo: ''));

    final pager = ds.communityExperiences('c1');
    final page = await pager.next();

    expect(page.map((e) => e.id), ['b', 'a']);
    expect(page.every((e) => e.communityId == 'c1'), isTrue);
    expect(page.first.communityName, 'Lisbon Foodies');
    expect(pager.hasMore, isFalse);
  });

  test('pages 20 at a time', () async {
    final col = db.collection('user_experiences');
    for (var i = 0; i < 25; i++) {
      await col.doc('e$i').set(_doc(communityId: 'c1', minute: i));
    }
    final pager = ds.communityExperiences('c1');
    final first = await pager.next();
    expect(first, hasLength(20));
    expect(first.first.id, 'e24');
    expect(pager.hasMore, isTrue);
    final second = await pager.next();
    expect(second.map((e) => e.id), ['e4', 'e3', 'e2', 'e1', 'e0']);
  });

  test("host drafts: only the host's not-published listings in the community",
      () async {
    final col = db.collection('user_experiences');
    await col
        .doc('d1')
        .set(_doc(communityId: 'c1', minute: 1, status: 'draft'));
    await col
        .doc('d2')
        .set(_doc(communityId: 'c1', minute: 2, status: 'draft'));
    await col.doc('pub').set(_doc(communityId: 'c1', minute: 3));
    await col.doc('x').set(
        _doc(communityId: 'c1', minute: 4, status: 'draft', hostId: 'h2'));
    await col
        .doc('y')
        .set(_doc(communityId: 'c2', minute: 5, status: 'draft'));

    final drafts = await ds.hostCommunityDrafts('c1', 'h1');
    expect(drafts.map((e) => e.id), ['d2', 'd1']);
  });

  test('missing index: empty page (no error), then the feed ends', () async {
    final inner = _ThrowingPager();
    final pager = FailSafeExperiencePager(inner, label: 'test');
    expect(await pager.next(), isEmpty);
    expect(pager.indexMissing, isTrue);
    expect(pager.hasMore, isFalse);
    expect(await pager.next(), isEmpty);
    expect(inner.calls, 1);
  });

  test('other Firestore errors still surface', () async {
    final pager = FailSafeExperiencePager(_DeniedPager());
    await expectLater(pager.next(), throwsA(isA<FirebaseException>()));
  });

  test('communityId is sent on create only, never in edits', () {
    final e =
        UserExperienceModel.fromMap('id1', _doc(communityId: 'c1', minute: 1));
    expect(e.isInCommunity, isTrue);
    final create = UserExperienceModel.createPayload(e);
    expect(create['communityId'], 'c1');
    expect(create.containsKey('communityName'), isFalse,
        reason: 'the server stores the name itself');
    final edit = UserExperienceModel.editablePayload(e);
    expect(edit.containsKey('communityId'), isFalse);
    expect(edit.containsKey('communityName'), isFalse);

    final unlinked =
        UserExperienceModel.fromMap('id2', _doc(communityId: '', minute: 1));
    expect(unlinked.isInCommunity, isFalse);
    expect(
        UserExperienceModel.createPayload(unlinked).containsKey('communityId'),
        isFalse);
  });

  test('the link survives copyWith / asFree', () {
    final e =
        UserExperienceModel.fromMap('id1', _doc(communityId: 'c1', minute: 1));
    expect(e.copyWith(status: ExperienceStatus.draft).communityId, 'c1');
    expect(e.asFree().communityName, 'Lisbon Foodies');
  });
}
