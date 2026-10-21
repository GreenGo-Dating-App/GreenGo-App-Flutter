import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';
import 'package:greengo_chat/features/communities/data/repositories/communities_repository_impl.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/community_message_feed.dart';

/// Owner request 2026-10-21: people filter the Tips tab by Language tip /
/// Cultural fact / City tip / Other. A selected chip must page THAT type on
/// the server (where type in [selected]) — not filter one loaded page of all
/// tips on the client, which would hide a rare type behind many pages.
void main() {
  final t0 = DateTime(2026, 10, 1, 12);

  /// 400 messages: a city tip every 40th (10 in all, 1 in the live page),
  /// a language tip every 3rd, the rest chat.
  Future<FakeFirebaseFirestore> seed() async {
    final db = FakeFirebaseFirestore();
    final col = db.collection('communities').doc('c1').collection('messages');
    for (var i = 1; i <= 400; i++) {
      final type = i % 40 == 0
          ? 'city_tip'
          : i % 3 == 0
              ? 'language_tip'
              : 'text';
      await col.doc('m$i').set({
        'senderId': 'u',
        'senderName': 'U',
        'content': 'message $i',
        'sentAt': Timestamp.fromDate(t0.add(Duration(minutes: i))),
        'type': type,
      });
    }
    return db;
  }

  test('datasource: tipType pages only that type, down to the first one',
      () async {
    final db = await seed();
    final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
    final page = await ds.getOlderCommunityMessages('c1',
        before: t0.add(const Duration(days: 1)), tipType: 'city_tip');
    expect(page.length, 10);
    expect(page.every((m) => m.type == CommunityMessageType.cityTip), isTrue);
    expect(page.first.id, 'm400');
    expect(page.last.id, 'm40');

    // An unknown type never widens to arbitrary types: falls back to tips.
    final any = await ds.getOlderCommunityMessages('c1',
        before: t0.add(const Duration(days: 1)), tipType: 'text', limit: 400);
    expect(any.every((m) => m.toEntity().isTip), isTrue);
  });

  test('feed: per-type cursor and has-more are independent of other types',
      () {
    CommunityMessage m(int i, CommunityMessageType type) => CommunityMessage(
          id: 'm$i',
          communityId: 'c1',
          senderId: 'u',
          senderName: 'U',
          content: 'x',
          sentAt: t0.add(Duration(minutes: i)),
          type: type,
        );
    final feed = CommunityMessageFeed(pageSize: 3)
      ..applyLive([
        for (var i = 103; i >= 101; i--) m(i, CommunityMessageType.text)
      ]);
    expect(feed.tipsCursorOf('city_tip'), feed.tipsCursor);
    feed.addTipsPageOf('city_tip', [
      m(90, CommunityMessageType.cityTip),
      m(50, CommunityMessageType.cityTip),
      m(10, CommunityMessageType.cityTip),
    ]);
    expect(feed.tipsCursorOf('city_tip'), m(10, CommunityMessageType.text).sentAt);
    expect(feed.hasMoreTipsOf('city_tip'), isTrue, reason: 'full page');
    // Other types are NOT advanced by a city page.
    expect(feed.tipsCursorOf('language_tip'), feed.tipsCursor);
    expect(feed.tipsCursor, m(101, CommunityMessageType.text).sentAt);
    feed.addTipsPageOf('city_tip', const []);
    expect(feed.hasMoreTipsOf('city_tip'), isFalse);
    expect(feed.hasMoreTipsOf('language_tip'), isTrue);
    expect(feed.hasMoreTipsByType, {'city_tip': false});
    // Wrong-type rows in a typed page are ignored.
    feed.addTipsPageOf('other_tip', [m(5, CommunityMessageType.cityTip)]);
    expect(feed.all.where((x) => x.id == 'm5'), isEmpty);
    // Removal also drops typed-page rows.
    feed.remove('m50');
    expect(feed.all.where((x) => x.id == 'm50'), isEmpty);
  });

  test('bloc: the City tip chip loads every city tip in one typed page',
      () async {
    final db = await seed();
    final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
    final bloc = CommunitiesBloc(
      repository: CommunitiesRepositoryImpl(remoteDataSource: ds),
      remoteDataSource: ds,
    );
    addTearDown(bloc.close);
    final community = Community(
      id: 'c1',
      name: 'C',
      description: 'd',
      type: CommunityType.general,
      createdByUserId: 'creator',
      createdByName: 'Creator',
      createdAt: t0,
      memberCount: 1,
    );
    bloc
      ..add(const SubscribeToCommunityMessages(communityId: 'c1'))
      ..add(LoadCommunityDetail(communityId: 'c1', community: community));
    await bloc.stream.firstWhere(
        (s) => s is CommunityDetailLoaded && s.messages.length == 50);

    var loads = 0;
    while ((bloc.state as CommunityDetailLoaded).hasMoreTipsOf('city_tip')) {
      bloc.add(const LoadOlderCommunityTips(
          communityId: 'c1', tipType: 'city_tip'));
      await bloc.stream.firstWhere(
          (s) => s is CommunityDetailLoaded && !s.isLoadingOlderTips);
      loads++;
      expect(loads, lessThan(5));
    }
    final s = bloc.state as CommunityDetailLoaded;
    final cityIds = s.messages
        .where((m) => m.type == CommunityMessageType.cityTip)
        .map((m) => m.id)
        .toSet();
    expect(cityIds.length, 10, reason: 'every city tip, oldest m40 included');
    expect(cityIds, contains('m40'));
    expect(loads, 1, reason: 'one typed page (9 older city tips < 50)');
    // Older language tips were NOT downloaded to find the city tips.
    expect(
        s.messages.where((m) =>
            m.type == CommunityMessageType.languageTip &&
            m.sentAt.isBefore(t0.add(const Duration(minutes: 351)))),
        isEmpty);
    // The unfiltered Tips list still has more to load.
    expect(s.hasMoreTipsOf(null), isTrue);
  });
}
