import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/community_favorites_service.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/domain/joined_favorites.dart';

Community c(String id, {String? name}) => Community(
      id: id,
      name: name ?? 'Community $id',
      description: 'about $id',
      type: CommunityType.languageCircle,
      createdByUserId: 'o',
      createdByName: 'O',
      createdAt: DateTime(2026, 1, 1),
      languages: const ['en'],
    );

void main() {
  group('arrangeJoinedCommunities', () {
    final joined = [c('a'), c('b'), c('c'), c('d')];

    test('favorites first, newest starred first; the rest keeps its order', () {
      final r =
          arrangeJoinedCommunities(joined: joined, favoriteIds: ['c', 'a']);
      expect(r.favorites.map((x) => x.id), ['a', 'c']);
      expect(r.others.map((x) => x.id), ['b', 'd']);
    });

    test('favorite docs fill in favorites not in the joined page', () {
      final r = arrangeJoinedCommunities(
          joined: [c('a')],
          favoriteIds: ['far'],
          favoriteDocs: {'far': c('far')},
          joinedLoaded: false);
      expect(r.favorites.map((x) => x.id), ['far']);
    });

    test('once the joined list is loaded, left communities are hidden', () {
      final r = arrangeJoinedCommunities(
          joined: [c('a')],
          favoriteIds: ['gone', 'a'],
          favoriteDocs: {'gone': c('gone')});
      expect(r.favorites.map((x) => x.id), ['a']);
      expect(r.others, isEmpty);
    });

    test('search filters both sections', () {
      final r = arrangeJoinedCommunities(
          joined: [c('a', name: 'Lisbon walkers'), c('b', name: 'Porto cafe')],
          favoriteIds: ['a'],
          query: 'porto');
      expect(r.favorites, isEmpty);
      expect(r.others.map((x) => x.id), ['b']);
    });
  });

  group('CommunityFavoritesService', () {
    test('ordered ids (starring order, de-duplicated) and capped loads',
        () async {
      final db = FakeFirebaseFirestore();
      final svc = CommunityFavoritesService(firestore: db);
      await svc.setFavorite('me', 'x', true);
      await svc.setFavorite('me', 'y', true);
      await svc.setFavorite('me', 'x', true); // arrayUnion: no duplicate
      expect(await svc.getOrdered('me'), ['x', 'y']);
      await svc.setFavorite('me', 'x', false);
      expect(await svc.getOrdered('me'), ['y']);

      for (var i = 0; i < 35; i++) {
        await db.collection('communities').doc('k$i').set({
          'name': 'K$i',
          'description': '',
          'type': 'languageCircle',
          'createdByUserId': 'o',
          'createdByName': 'O',
          'languages': ['en'],
        });
      }
      final docs = await svc
          .loadCommunities([for (var i = 0; i < 35; i++) 'k$i', 'missing']);
      expect(docs.length, 35); // two whereIn chunks; deleted ids skipped
      expect(docs['k34']!.name, 'K34');
      expect(CommunityFavoritesService.maxFavorites, 50);
    });
  });
}
