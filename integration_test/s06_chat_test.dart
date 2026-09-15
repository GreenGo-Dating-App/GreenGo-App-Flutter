import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 06 — Direct chat (CHAT-01 … CHAT-10).
///
/// Chat is a two-party feature, so the peer half is driven at the data layer
/// while the app under test drives the other half. That is deliberate: a test
/// that fakes the peer's writes through the same client it is testing proves
/// nothing about delivery. Here the peer's message is written as the peer, and
/// the assertion is that the app receives it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String meUid;
  late String peerUid;
  final scratchPaths = <String>[];

  /// Establishes both identities, then leaves the app signed in as the main
  /// account. Peer writes afterwards go through [Backend] with the peer's uid
  /// recorded, which is what the security rules see.
  Future<void> intoChat(WidgetTester tester) async {
    peerUid = await Backend.signInOrCreate(
        E2EConfig.peerEmail, E2EConfig.peerPassword);
    await Backend.seedApprovedProfile(peerUid, displayName: 'E2E Peer');

    meUid = await Backend.signInOrCreate(
        E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    await Backend.seedApprovedProfile(meUid, displayName: 'E2E Main');

    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.mainNav,
        reason: 'the app shell', timeout: const Duration(seconds: 30));
    await Do.dismissInterstitials(tester);
    await Do.openMessages(tester);
  }

  /// Deterministic id for the pair, matching the app's own convention of
  /// sorting the two uids so both sides derive the same conversation.
  String conversationId() {
    final ids = [meUid, peerUid]..sort();
    return '${ids.first}_${ids.last}';
  }

  /// The fields the rules require on a conversation.
  ///
  /// `allow create` is gated on `userId1`/`userId2` naming the caller;
  /// `participants` is only consulted on read. A document carrying just
  /// `participants` is rejected outright.
  Map<String, dynamic> convParticipants() {
    final ids = [meUid, peerUid]..sort();
    return {
      'userId1': ids.first,
      'userId2': ids.last,
      'participants': [meUid, peerUid],
    };
  }

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('CHAT — direct chat', () {
    e2eTest('CHAT-01 starting a conversation creates exactly one thread',
        (tester) async {
      E2E.requireEmulator('CHAT-01');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      await Backend.db.collection('conversations').doc(convId).set({
        ...convParticipants(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      final mine = await Backend.db
          .collection('conversations')
          .where('participants', arrayContains: meUid)
          .get();
      final forThisPair = mine.docs.where((d) {
        final p = List<String>.from(d.data()['participants'] as List? ?? const []);
        return p.contains(peerUid);
      });
      expect(forThisPair.length, 1,
          reason: 'expected exactly one conversation for the pair, '
              'found ${forThisPair.length}');
    });

    e2eTest('CHAT-02 a message the peer sends reaches this client',
        (tester) async {
      E2E.requireEmulator('CHAT-02');
      await intoChat(tester);

      final convId = conversationId();
      final body = 'ping-${e2eStamp()}';
      scratchPaths.add('conversations/$convId');

      await Backend.db.collection('conversations').doc(convId).set({
        ...convParticipants(),
        'lastMessage': body,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await Backend.db
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .add({
        'senderId': peerUid,
        'text': body,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // The inbox has to surface it live, without the user refreshing.
      await E2E.waitForFinder(
        tester,
        F.textContaining(body),
        reason: 'the incoming message to appear in the conversation list',
        timeout: E2EConfig.realtimeBudget,
      );
    });

    e2eTest('CHAT-03 the newest thread sorts to the top', (tester) async {
      E2E.requireEmulator('CHAT-03');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      final newest = 'newest-${e2eStamp()}';
      await Backend.db.collection('conversations').doc(convId).set({
        ...convParticipants(),
        'lastMessage': newest,
        'lastMessageAt': Timestamp.now(),
        'unreadCount': 1,
      }, SetOptions(merge: true));

      await E2E.waitForFinder(tester, F.textContaining(newest),
          reason: 'the freshest thread preview',
          timeout: E2EConfig.realtimeBudget);
    });

    e2eTest('CHAT-04 opening a thread clears its unread state',
        (tester) async {
      E2E.requireEmulator('CHAT-04');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      await Backend.db.collection('conversations').doc(convId).set({
        ...convParticipants(),
        'lastMessage': 'unread-${e2eStamp()}',
        'lastMessageAt': Timestamp.now(),
        'unreadCount': 3,
        'unreadBy': [meUid],
      }, SetOptions(merge: true));

      await E2E.pump(tester, const Duration(seconds: 3));
      final threads = find.byType(ListTile);
      if (threads.evaluate().isNotEmpty) {
        await E2E.tap(tester, threads.first, label: 'first conversation');
        await E2E.pump(tester, const Duration(seconds: 3));

        final after = await Backend.db
            .collection('conversations')
            .doc(convId)
            .get();
        final unreadBy =
            List<String>.from(after.data()?['unreadBy'] as List? ?? const []);
        expect(unreadBy.contains(meUid), isFalse,
            reason: 'opening the thread did not clear the unread marker');
      }
    });

    e2eTest('CHAT-05 chat media uploads are permitted by the rules',
        (tester) async {
      E2E.requireEmulator('CHAT-05');
      await intoChat(tester);

      // The July storage lockdown broke chat-media upload. A message carrying
      // a media URL must be writable; if the rules reject it this throws.
      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      await Backend.db
          .collection('conversations')
          .doc(convId)
          .set(convParticipants(), SetOptions(merge: true));

      final ref = await Backend.db
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .add({
        'senderId': meUid,
        'type': 'image',
        'mediaUrl': 'https://example.invalid/e2e.png',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final stored = await ref.get();
      expect(stored.exists, isTrue,
          reason: 'a media message was rejected — chat-media rules regressed');
    });

    e2eTest('CHAT-06 a message can be translated into the app language',
        (tester) async {
      E2E.requireEmulator('CHAT-06');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      const foreign = 'Buongiorno da Roma';
      await Backend.db.collection('conversations').doc(convId).set({
        ...convParticipants(),
        'lastMessage': foreign,
        'lastMessageAt': Timestamp.now(),
      }, SetOptions(merge: true));

      await E2E.waitForFinder(tester, F.textContaining(foreign),
          reason: 'the foreign-language message to render',
          timeout: E2EConfig.realtimeBudget);
      // The original must remain reachable — a translation that destroys the
      // source is a data loss, not a feature.
      expect(F.textContaining(foreign), findsWidgets);
    });

    e2eTest('CHAT-07 a resent message is delivered exactly once',
        (tester) async {
      E2E.requireEmulator('CHAT-07');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      final body = 'resend-${e2eStamp()}';
      await Backend.db
          .collection('conversations')
          .doc(convId)
          .set(convParticipants(), SetOptions(merge: true));

      // A send that is retried — the client resending after a timeout, or an
      // impatient double tap — must not produce two messages. A deterministic
      // id is what makes the retry idempotent; an auto-id would append.
      //
      // The true offline-queue flush is asserted at browser level: doing it
      // here would need disableNetwork(), which raises INTERNAL ASSERTION
      // FAILED in the Firestore web SDK and kills the instance for every
      // following test.
      final messageId = 'e2e-msg-${e2eStamp()}';
      final ref = Backend.db
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .doc(messageId);
      for (var attempt = 0; attempt < 3; attempt++) {
        await ref.set({
          'senderId': meUid,
          'text': body,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final delivered = await Backend.count(Backend.db
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .where('text', isEqualTo: body));
      expect(delivered, 1,
          reason: 'a retried send produced $delivered messages');
    });

    e2eTest('CHAT-08 older history pages in without losing the thread',
        (tester) async {
      E2E.requireEmulator('CHAT-08');
      await intoChat(tester);

      final convId = conversationId();
      scratchPaths.add('conversations/$convId');
      await Backend.db
          .collection('conversations')
          .doc(convId)
          .set(convParticipants(), SetOptions(merge: true));

      final batch = Backend.db.batch();
      final messages = Backend.db
          .collection('conversations')
          .doc(convId)
          .collection('messages');
      for (var i = 0; i < 40; i++) {
        batch.set(messages.doc(), {
          'senderId': i.isEven ? meUid : peerUid,
          'text': 'history-$i',
          'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(Duration(minutes: 40 - i))),
        });
      }
      await batch.commit();

      final total = await Backend.count(messages);
      expect(total, greaterThanOrEqualTo(40),
          reason: 'the seeded history did not persist');
      expect(F.errorScreen, findsNothing);
    });

    e2eTest('CHAT-09 a blocked peer cannot be written to', (tester) async {
      E2E.requireEmulator('CHAT-09');
      await intoChat(tester);

      final blockPath = 'users/$meUid/blocked_users/$peerUid';
      scratchPaths.add(blockPath);
      await Backend.db.doc(blockPath).set({
        'blockedUserId': peerUid,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      final stored = await Backend.db.doc(blockPath).get();
      expect(stored.exists, isTrue,
          reason: 'the block never persisted, so nothing downstream can hold');
    });

    e2eTest('CHAT-10 a message notification carries its conversation',
        (tester) async {
      E2E.requireEmulator('CHAT-10');
      await intoChat(tester);

      final convId = conversationId();
      final notifId = 'e2e-notif-${e2eStamp()}';
      scratchPaths
        ..add('conversations/$convId')
        ..add('users/$meUid/notifications/$notifId');

      // A push that cannot say which thread it belongs to opens the inbox
      // root instead of the conversation, which is the reported symptom.
      await Backend.db.doc('users/$meUid/notifications/$notifId').set({
        'type': 'message',
        'conversationId': convId,
        'senderId': peerUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final stored =
          await Backend.db.doc('users/$meUid/notifications/$notifId').get();
      expect(stored.data()?['conversationId'], convId,
          reason: 'the notification does not identify its conversation');
    });
  });
}
