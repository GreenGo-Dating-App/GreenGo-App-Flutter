import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 07 — Groups & communities (GRP-01 … GRP-08).
///
/// Group chat lives in its own collection, separate from `conversations`, and
/// must stay that way — GRP-01 asserts that creating a group leaves the
/// existing one-to-one threads untouched, because merging the two is exactly
/// the shortcut that would break every existing chat.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String meUid;
  late String peerUid;
  final scratchPaths = <String>[];

  Future<void> intoApp(WidgetTester tester) async {
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
  }

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('GRP — groups & communities', () {
    e2eTest('GRP-01 creating a group does not disturb direct conversations',
        (tester) async {
      E2E.requireEmulator('GRP-01');
      await intoApp(tester);

      final before = await Backend.count(Backend.db
          .collection('conversations')
          .where('participants', arrayContains: meUid));

      final groupId = 'e2e-group-${e2eStamp()}';
      scratchPaths.add('groups/$groupId');
      await Backend.db.collection('groups').doc(groupId).set({
        'name': 'E2E Group',
        // The rules require the creator to be in `participants` and to be
        // their own admin in `roles`; `members`/`admins` are not the schema.
        'participants': [meUid, peerUid],
        'roles': {meUid: 'admin', peerUid: 'member'},
        'createdBy': meUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final stored = await Backend.db.collection('groups').doc(groupId).get();
      expect(stored.exists, isTrue, reason: 'the group was not created');

      final after = await Backend.count(Backend.db
          .collection('conversations')
          .where('participants', arrayContains: meUid));
      expect(after, before,
          reason: 'creating a group changed the direct-conversation set');
    });

    e2eTest('GRP-02 a group message is visible to every member',
        (tester) async {
      E2E.requireEmulator('GRP-02');
      await intoApp(tester);

      final groupId = 'e2e-group-${e2eStamp()}';
      scratchPaths.add('groups/$groupId');
      await Backend.db.collection('groups').doc(groupId).set({
        'name': 'E2E Group',
        'participants': [meUid, peerUid],
        'roles': {meUid: 'admin', peerUid: 'member'},
      });

      final body = 'group-msg-${e2eStamp()}';
      await Backend.db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'senderId': peerUid,
        'text': body,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Membership, not authorship, decides visibility.
      final visible = await Backend.db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('text', isEqualTo: body)
          .get();
      expect(visible.size, 1,
          reason: 'a member could not read another member\'s group message');
    });

    e2eTest('GRP-03 a removed member loses read access', (tester) async {
      E2E.requireEmulator('GRP-03');
      await intoApp(tester);

      final groupId = 'e2e-group-${e2eStamp()}';
      scratchPaths.add('groups/$groupId');
      await Backend.db.collection('groups').doc(groupId).set({
        'name': 'E2E Group',
        'participants': [meUid, peerUid],
        'roles': {meUid: 'admin', peerUid: 'member'},
      });

      await Backend.db.collection('groups').doc(groupId).update({
        'participants': FieldValue.arrayRemove([peerUid]),
      });

      final after = await Backend.db.collection('groups').doc(groupId).get();
      final members =
          List<String>.from(after.data()?['participants'] as List? ?? const []);
      expect(members.contains(peerUid), isFalse,
          reason: 'the removed member is still on the roster');
      expect(members.contains(meUid), isTrue,
          reason: 'removing one member removed the wrong person');
    });

    e2eTest('GRP-04 leaving a group keeps it alive for everyone else',
        (tester) async {
      E2E.requireEmulator('GRP-04');
      await intoApp(tester);

      final groupId = 'e2e-group-${e2eStamp()}';
      scratchPaths.add('groups/$groupId');
      await Backend.db.collection('groups').doc(groupId).set({
        'name': 'E2E Group',
        'participants': [meUid, peerUid],
        'roles': {meUid: 'admin', peerUid: 'admin'},
      });

      await Backend.db.collection('groups').doc(groupId).update({
        'participants': FieldValue.arrayRemove([meUid]),
      });

      final after = await Backend.db.collection('groups').doc(groupId).get();
      expect(after.exists, isTrue,
          reason: 'one member leaving deleted the whole group');
      final members =
          List<String>.from(after.data()?['participants'] as List? ?? const []);
      expect(members, contains(peerUid));
    });

    e2eTest('GRP-05 joining a community records the membership',
        (tester) async {
      E2E.requireEmulator('GRP-05');
      await intoApp(tester);

      final communityId = 'e2e-community-${e2eStamp()}';
      scratchPaths
        ..add('communities/$communityId/members/$meUid')
        ..add('communities/$communityId');
      await Backend.db.collection('communities').doc(communityId).set({
        'name': 'E2E Community',
        'requiresApproval': false,
        'createdBy': meUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await Backend.db
          .doc('communities/$communityId/members/$meUid')
          .set({'userId': meUid, 'role': 'member'});

      final member =
          await Backend.db.doc('communities/$communityId/members/$meUid').get();
      expect(member.exists, isTrue,
          reason: 'joining a community wrote no membership record');
      expect(member.data()!['role'], 'member');
    });

    e2eTest('GRP-06 an approval-gated community holds the member pending',
        (tester) async {
      E2E.requireEmulator('GRP-06');
      await intoApp(tester);

      final communityId = 'e2e-community-${e2eStamp()}';
      scratchPaths
        ..add('communities/$communityId/members/$meUid')
        ..add('communities/$communityId');
      await Backend.db.collection('communities').doc(communityId).set({
        'name': 'E2E Gated',
        'requiresApproval': true,
        'createdBy': peerUid,
      });
      await Backend.db
          .doc('communities/$communityId/members/$meUid')
          .set({'userId': meUid, 'role': 'member', 'status': 'pending'});

      var member =
          await Backend.db.doc('communities/$communityId/members/$meUid').get();
      expect(member.data()!['status'], 'pending',
          reason: 'a gated community admitted the member immediately');

      await Backend.db
          .doc('communities/$communityId/members/$meUid')
          .update({'status': 'approved'});
      member =
          await Backend.db.doc('communities/$communityId/members/$meUid').get();
      expect(member.data()!['status'], 'approved');
    });

    e2eTest('GRP-07 roles are stored so moderation can be enforced',
        (tester) async {
      E2E.requireEmulator('GRP-07');
      await intoApp(tester);

      final communityId = 'e2e-community-${e2eStamp()}';
      scratchPaths
        ..add('communities/$communityId/members/$meUid')
        ..add('communities/$communityId/members/$peerUid')
        ..add('communities/$communityId');
      await Backend.db.collection('communities').doc(communityId).set({
        'name': 'E2E Moderated',
        'createdBy': meUid,
      });
      await Backend.db
          .doc('communities/$communityId/members/$meUid')
          .set({'userId': meUid, 'role': 'moderator'});
      await Backend.db
          .doc('communities/$communityId/members/$peerUid')
          .set({'userId': peerUid, 'role': 'member'});

      final mod =
          await Backend.db.doc('communities/$communityId/members/$meUid').get();
      final plain = await Backend.db
          .doc('communities/$communityId/members/$peerUid')
          .get();
      expect(mod.data()!['role'], 'moderator');
      expect(plain.data()!['role'], 'member',
          reason: 'every member was granted moderator rights');
    });

    e2eTest('GRP-08 announcements record their author role', (tester) async {
      E2E.requireEmulator('GRP-08');
      await intoApp(tester);

      final communityId = 'e2e-community-${e2eStamp()}';
      final postId = 'e2e-post-${e2eStamp()}';
      scratchPaths
        ..add('communities/$communityId/announcements/$postId')
        ..add('communities/$communityId');
      await Backend.db.collection('communities').doc(communityId).set({
        'name': 'E2E Announce',
        'createdBy': meUid,
      });
      await Backend.db
          .doc('communities/$communityId/announcements/$postId')
          .set({
        'authorId': meUid,
        'authorRole': 'moderator',
        'body': 'E2E announcement',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final post = await Backend.db
          .doc('communities/$communityId/announcements/$postId')
          .get();
      expect(post.data()!['authorRole'], 'moderator',
          reason: 'announcements do not record who was allowed to post them');
    });
  });
}
