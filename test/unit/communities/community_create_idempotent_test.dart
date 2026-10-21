// Owner bug 2026-10-21: "I create a community and it appears 2 communities
// with the same data." Prod had two identical docs 12 s apart — the Create
// button stayed enabled while the (slow) create ran, and every tap called
// `communities.add()`, minting a new doc each time.
//
// Guards: the form keeps ONE client-generated id, the datasource create is
// idempotent on that id, the bloc drops a duplicate in-flight create, and the
// tab lists are de-duplicated by id.
import 'dart:math' as math;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';
import 'package:greengo_chat/features/communities/data/models/community_model.dart';
import 'package:greengo_chat/features/communities/data/repositories/communities_repository_impl.dart';
import 'package:greengo_chat/features/communities/domain/community_id.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';

Community _community({String id = 'c_new', String by = 'u1', String name = 'Brasileiras nos USA'}) =>
    Community(
      id: id,
      name: name,
      description: 'desc',
      type: CommunityType.general,
      createdByUserId: by,
      createdByName: 'Owner',
      createdAt: DateTime(2026, 10, 21, 19, 17),
      memberCount: 1,
      languages: const ['en', 'pt'],
      tags: const ['brazil'],
    );

void main() {
  group('newCommunityId', () {
    test('is a 20-char Firestore-style id', () {
      final id = newCommunityId();
      expect(id, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
    });

    test('differs between forms', () {
      final ids = {for (var i = 0; i < 200; i++) newCommunityId(math.Random(i))};
      expect(ids.length, 200);
    });
  });

  group('createCommunity datasource (idempotent on the client id)', () {
    test('two creates with the same id leave ONE community doc', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final model = CommunityModel.fromEntity(_community());

      final first = await ds.createCommunity(model);
      final second = await ds.createCommunity(model);

      final all = await db.collection('communities').get();
      expect(all.docs.map((d) => d.id), ['c_new']);
      expect(first.id, 'c_new');
      expect(second.id, 'c_new');
      final members =
          await db.collection('communities').doc('c_new').collection('members').get();
      expect(members.docs.map((d) => d.id), ['u1']);
    });

    test('a retry does not overwrite the existing doc', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      await ds.createCommunity(CommunityModel.fromEntity(_community()));
      await db.collection('communities').doc('c_new').update({'memberCount': 7});

      await ds.createCommunity(CommunityModel.fromEntity(_community()));

      final doc = await db.collection('communities').doc('c_new').get();
      expect(doc.data()!['memberCount'], 7);
    });

    test('an id owned by another creator is refused', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      await ds.createCommunity(CommunityModel.fromEntity(_community()));

      await expectLater(
        ds.createCommunity(CommunityModel.fromEntity(_community(by: 'u2', name: 'Other'))),
        throwsA(isA<StateError>()),
      );
      final doc = await db.collection('communities').doc('c_new').get();
      expect(doc.data()!['createdByUserId'], 'u1');
    });

    test('an empty id (legacy caller) still creates with an auto id', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final created = await ds.createCommunity(CommunityModel.fromEntity(_community(id: '')));
      expect(created.id, isNotEmpty);
      expect((await db.collection('communities').get()).docs, hasLength(1));
    });
  });

  group('CommunitiesBloc create', () {
    test('a double submit (two CreateCommunity, same id) creates ONE community', () async {
      final db = FakeFirebaseFirestore();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final bloc = CommunitiesBloc(
        repository: CommunitiesRepositoryImpl(remoteDataSource: ds),
        remoteDataSource: ds,
      );
      final created = <CommunityCreated>[];
      final sub = bloc.stream.listen((s) {
        if (s is CommunityCreated) created.add(s);
      });

      final event = CreateCommunity(community: _community(), userId: 'u1', userName: 'Owner');
      bloc
        ..add(event)
        ..add(event);
      await bloc.stream.firstWhere((s) => s is CommunityCreated);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final all = await db.collection('communities').get();
      expect(all.docs, hasLength(1));
      expect(created, hasLength(1));
      final doc = all.docs.single.data();
      expect(doc['memberCount'], 1, reason: 'creator counted once');

      await sub.cancel();
      await bloc.close();
    });
  });

  group('dedupeCommunitiesById', () {
    test('keeps the first of each id, order preserved', () {
      final a = _community(id: 'a');
      final b = _community(id: 'b');
      final a2 = _community(id: 'a', name: 'dup');
      final out = dedupeCommunitiesById([a, b, a2]);
      expect(out.map((c) => c.id), ['a', 'b']);
      expect(out.first.name, 'Brasileiras nos USA');
    });
  });
}
