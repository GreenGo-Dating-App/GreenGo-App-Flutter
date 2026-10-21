// Owner request 2026-10-21: "who created a community can change the
// community info and featured image".
//
// The save path: UpdateCommunity -> repository -> datasource update (strips
// the denormalised counters, recomputes searchKeywords) -> the bloc emits the
// one-shot CommunityInfoUpdated (list patch, edit form closes) and re-emits
// the open detail with the saved community.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';
import 'package:greengo_chat/features/communities/data/models/community_model.dart';
import 'package:greengo_chat/features/communities/data/repositories/communities_repository_impl.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';

Community _community({
  String id = 'c1',
  String name = 'Old name',
  String? imageUrl = 'https://example.test/old.jpg',
  String? city = 'Porto',
}) =>
    Community(
      id: id,
      name: name,
      description: 'An old description',
      type: CommunityType.general,
      imageUrl: imageUrl,
      createdByUserId: 'creator',
      createdByName: 'Creator',
      createdAt: DateTime(2026, 10, 1, 10),
      memberCount: 1,
      languages: const ['en'],
      tags: const ['coffee'],
      city: city,
    );

void main() {
  group('Community.copyWith clear flags', () {
    test('clearImageUrl / clearCity / clearCountry drop the values', () {
      final c = _community().copyWith(country: 'Portugal');
      final cleared =
          c.copyWith(clearImageUrl: true, clearCity: true, clearCountry: true);
      expect(cleared.imageUrl, isNull);
      expect(cleared.city, isNull);
      expect(cleared.country, isNull);
      expect(cleared.name, c.name);
    });

    test('without flags the values are kept or replaced', () {
      final c = _community();
      expect(c.copyWith().imageUrl, c.imageUrl);
      expect(c.copyWith(imageUrl: 'https://x/new.jpg').imageUrl,
          'https://x/new.jpg');
    });
  });

  group('datasource updateCommunity (info edit)', () {
    test('writes the new info, removes the cover, keeps the member counter',
        () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      await ds.createCommunity(CommunityModel.fromEntity(_community()));
      // Joins happened meanwhile: the edit must not reset the counter.
      await db.collection('communities').doc('c1').update({'memberCount': 42});

      final edited = _community().copyWith(
        name: 'Lisbon Walkers',
        description: 'Walks around Lisbon every weekend',
        type: CommunityType.travelGroup,
        clearImageUrl: true,
        languages: const ['en', 'pt'],
        tags: const ['walks'],
        city: 'Lisbon',
        isPublic: false,
      );
      await ds.updateCommunity(CommunityModel.fromEntity(edited));

      final d = (await db.collection('communities').doc('c1').get()).data()!;
      expect(d['name'], 'Lisbon Walkers');
      expect(d['description'], 'Walks around Lisbon every weekend');
      expect(d['type'], CommunityType.travelGroup.value);
      expect(d['imageUrl'], isNull);
      expect(d['languages'], ['en', 'pt']);
      expect(d['tags'], ['walks']);
      expect(d['city'], 'Lisbon');
      expect(d['isPublic'], false);
      expect(d['memberCount'], 42);
      expect(d['createdByUserId'], 'creator');
      expect((d['searchKeywords'] as List).cast<String>(),
          containsAll(<String>['lisbon', 'walks']));
      expect((d['searchKeywords'] as List).cast<String>(),
          isNot(contains('coffee')));
    });
  });

  group('CommunitiesBloc UpdateCommunity', () {
    test(
        'emits CommunityInfoUpdated then the open detail with the saved '
        'community', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      await ds.createCommunity(CommunityModel.fromEntity(_community()));
      final bloc = CommunitiesBloc(
        repository: CommunitiesRepositoryImpl(remoteDataSource: ds),
        remoteDataSource: ds,
      );
      bloc.add(LoadCommunityDetail(
          communityId: 'c1', community: _community(), userId: 'creator'));
      await bloc.stream.firstWhere((s) => s is CommunityDetailLoaded);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final seen = <CommunitiesState>[];
      final sub = bloc.stream.listen(seen.add);
      final edited = _community(
          name: 'New name', imageUrl: 'https://example.test/new.jpg');
      bloc.add(UpdateCommunity(community: edited));
      await bloc.stream.firstWhere((s) =>
          s is CommunityDetailLoaded && s.community.name == 'New name');

      final infoIdx = seen.indexWhere((s) => s is CommunityInfoUpdated);
      expect(infoIdx, isNot(-1));
      expect((seen[infoIdx] as CommunityInfoUpdated).community.name,
          'New name');
      final detail = seen.skip(infoIdx + 1).whereType<CommunityDetailLoaded>().first;
      expect(detail.community.imageUrl, 'https://example.test/new.jpg');
      expect(detail.membershipLoaded, isTrue,
          reason: 'the detail keeps its membership/messages');

      // A later re-load without a community repaints the SAVED one.
      bloc.add(const LoadCommunityDetail(communityId: 'c1'));
      final reloaded = await bloc.stream
          .firstWhere((s) => s is CommunityDetailLoaded) as CommunityDetailLoaded;
      expect(reloaded.community.name, 'New name');

      final d = (await db.collection('communities').doc('c1').get()).data()!;
      expect(d['name'], 'New name');
      await sub.cancel();
      await bloc.close();
    });

    test('a failed save emits CommunitiesError and no CommunityInfoUpdated',
        () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final bloc = CommunitiesBloc(
        repository: CommunitiesRepositoryImpl(remoteDataSource: ds),
        remoteDataSource: ds,
      );
      final seen = <CommunitiesState>[];
      final sub = bloc.stream.listen(seen.add);
      // No doc: update() fails (NOT_FOUND).
      bloc.add(UpdateCommunity(community: _community(id: 'missing')));
      await bloc.stream.firstWhere((s) => s is CommunitiesError);
      expect(seen.whereType<CommunityInfoUpdated>(), isEmpty);
      await sub.cancel();
      await bloc.close();
    });
  });

  group('replaceCommunityInLoaded', () {
    test('swaps the edited community in every list, by id', () {
      final a = _community(id: 'a');
      final b = _community(id: 'b');
      final loaded = CommunitiesLoaded(
        communities: [a, b],
        userCommunities: [b],
        recommended: [a],
        languageCircles: const [],
        managedCommunities: [a],
      );
      final a2 = _community(id: 'a', name: 'Renamed');
      final out = replaceCommunityInLoaded(loaded, a2);
      expect(out.communities.map((c) => c.name), ['Renamed', 'Old name']);
      expect(out.userCommunities.single.name, 'Old name');
      expect(out.recommended.single.name, 'Renamed');
      expect(out.managedCommunities.single.name, 'Renamed');
      expect(identical(out.userCommunities, loaded.userCommunities), isTrue,
          reason: 'untouched lists are reused');
    });
  });
}
