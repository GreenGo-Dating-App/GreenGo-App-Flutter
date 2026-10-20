import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/community_message_feed.dart';

/// Owner notes 2026-10-20: community chat and tips load only the newest 50
/// (newest first), older pages of 50 on endless scroll until the beginning,
/// new messages still live (the live listener covers only the newest page).
void main() {
  final t0 = DateTime(2026, 10, 1, 12);

  CommunityMessage msg(int i, {CommunityMessageType type = CommunityMessageType.text}) =>
      CommunityMessage(
        id: 'm$i',
        communityId: 'c1',
        senderId: 'u',
        senderName: 'U',
        content: 'message $i',
        sentAt: t0.add(Duration(minutes: i)),
        type: type,
      );

  /// Newest first, like the Firestore queries.
  List<CommunityMessage> range(int from, int toInclusive) =>
      [for (var i = toInclusive; i >= from; i--) msg(i)];

  group('CommunityMessageFeed', () {
    test('a full live page leaves older pages to load; a short one does not',
        () {
      final full = CommunityMessageFeed()..applyLive(range(51, 100));
      expect(full.hasMoreMessages, isTrue);
      expect(full.hasMoreTips, isTrue);
      expect(full.messagesCursor, msg(51).sentAt);

      final short = CommunityMessageFeed()..applyLive(range(1, 10));
      expect(short.hasMoreMessages, isFalse);
      expect(short.hasMoreTips, isFalse);
    });

    test('older pages append until the beginning, newest first, no dupes',
        () {
      final feed = CommunityMessageFeed()..applyLive(range(51, 100));
      feed.addOlderPage(range(1, 50));
      expect(feed.hasMoreMessages, isTrue, reason: 'a full page');
      expect(feed.messagesCursor, msg(1).sentAt);
      feed.addOlderPage(const []);
      expect(feed.hasMoreMessages, isFalse);
      final ids = feed.all.map((m) => m.id).toList();
      expect(ids.length, 100);
      expect(ids.first, 'm100');
      expect(ids.last, 'm1');
    });

    test('a new live message pushes the oldest live one into the older set',
        () {
      final feed = CommunityMessageFeed()..applyLive(range(51, 100));
      feed.addOlderPage(range(1, 50));
      feed.applyLive(range(52, 101)); // m101 arrived, m51 left the window
      final ids = feed.all.map((m) => m.id).toSet();
      expect(ids.contains('m101'), isTrue);
      expect(ids.contains('m51'), isTrue, reason: 'kept, not lost');
      expect(ids.length, 101);
    });

    test('a message gone from inside the live window was deleted', () {
      final feed = CommunityMessageFeed()..applyLive(range(51, 100));
      feed.applyLive([...range(51, 100)]..removeWhere((m) => m.id == 'm70'));
      expect(feed.all.any((m) => m.id == 'm70'), isFalse);
    });

    test('remove() drops an older-page message (not live)', () {
      final feed = CommunityMessageFeed()..applyLive(range(51, 100));
      feed.addOlderPage(range(1, 50));
      feed.remove('m10');
      expect(feed.all.any((m) => m.id == 'm10'), isFalse);
    });

    test('tips cursor: tips are complete down to the older of both feeds',
        () {
      final feed = CommunityMessageFeed()..applyLive(range(51, 100));
      expect(feed.tipsCursor, msg(51).sentAt);
      feed.addTipsPage([
        msg(30, type: CommunityMessageType.languageTip),
        msg(20, type: CommunityMessageType.cityTip),
      ]);
      expect(feed.tipsCursor, msg(20).sentAt);
      expect(feed.hasMoreTips, isFalse, reason: 'short tips page');
      expect(feed.hasMoreMessages, isTrue, reason: 'chat is separate');
      // Tips pages never leak plain messages into the feed.
      feed.addTipsPage([msg(5)]);
      expect(feed.all.any((m) => m.id == 'm5'), isFalse);
    });
  });

  group('getOlderCommunityMessages (keyset pages of 50)', () {
    Future<FakeFirebaseFirestore> seed(int n, {int tipEvery = 0}) async {
      final db = FakeFirebaseFirestore();
      final col = db.collection('communities').doc('c1').collection('messages');
      for (var i = 1; i <= n; i++) {
        final tip = tipEvery > 0 && i % tipEvery == 0;
        await col.doc('m$i').set({
          'senderId': 'u',
          'senderName': 'U',
          'content': 'message $i',
          'sentAt': Timestamp.fromDate(t0.add(Duration(minutes: i))),
          'type': tip ? 'language_tip' : 'text',
        });
      }
      return db;
    }

    test('live page = newest 50; older pages page to the beginning',
        () async {
      final db = await seed(120);
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final live = await ds.getCommunityMessages('c1').first;
      expect(live.length, kMessagePageSize);
      expect(live.first.id, 'm120');
      expect(live.last.id, 'm71');

      final feed = CommunityMessageFeed()
        ..applyLive([for (final m in live) m.toEntity()]);
      var pages = 0;
      while (feed.hasMoreMessages) {
        final page = await ds.getOlderCommunityMessages('c1',
            before: feed.messagesCursor!);
        expect(page.length, lessThanOrEqualTo(kMessagePageSize));
        feed.addOlderPage([for (final m in page) m.toEntity()]);
        pages++;
        expect(pages, lessThan(10));
      }
      expect(pages, 2); // 50 + 20
      final ids = feed.all.map((m) => m.id).toList();
      expect(ids.length, 120);
      expect(ids, [for (var i = 120; i >= 1; i--) 'm$i']);
    });

    test('tips pages skip plain chat messages', () async {
      final db = await seed(200, tipEvery: 10); // 20 tips
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);
      final live = await ds.getCommunityMessages('c1').first;
      final feed = CommunityMessageFeed()
        ..applyLive([for (final m in live) m.toEntity()]);
      final tips = await ds.getOlderCommunityMessages('c1',
          before: feed.tipsCursor!, tipsOnly: true);
      expect(tips.every((m) => m.toEntity().isTip), isTrue);
      expect(tips.length, 15); // tips older than the live page (m10..m150)
      feed.addTipsPage([for (final m in tips) m.toEntity()]);
      expect(feed.hasMoreTips, isFalse);
      expect(feed.all.where((m) => m.isTip).length, 20);
    });
  });
}
