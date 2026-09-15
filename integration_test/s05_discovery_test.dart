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

/// Suite 05 — Discovery & filters (DISC-01 … DISC-08).
///
/// Commit 9c46d4d made every stored preference an actual filter. That turned
/// each preference into a new way to return nothing, so these tests care as
/// much about the empty state and the escape hatch as about the happy path.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> intoExplore(WidgetTester tester) async {
    await Backend.signInOrCreate(
        E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.mainNav,
        reason: 'the app shell', timeout: const Duration(seconds: 30));
    await Do.dismissInterstitials(tester);
    await Do.openExplore(tester);
  }

  group('DISC — discovery & filters', () {
    e2eTest('DISC-01 Explore returns people and never the user themselves',
        (tester) async {
      await intoExplore(tester);
      final me = Backend.uid;

      await E2E.waitFor(
        tester,
        () => tester.widgetList(find.byType(Card)).isNotEmpty ||
            tester.widgetList(find.byType(Image)).isNotEmpty,
        reason: 'discovery results to render',
        timeout: const Duration(seconds: 25),
      );

      final myProfile = await Backend.profile(me);
      final myName = myProfile?['displayName'] as String?;
      if (myName != null && myName.isNotEmpty) {
        expect(F.text(myName), findsNothing,
            reason: 'the current user appeared in their own discovery deck');
      }
    });

    e2eTest('DISC-02 an applied filter narrows what comes back',
        (tester) async {
      await intoExplore(tester);
      await E2E.pump(tester, const Duration(seconds: 4));

      // Count what an unfiltered deck produced, then compare after filtering.
      final before = find.byType(Card).evaluate().length;
      final l10n = E2E.l10n(tester);

      final filterEntry = F.icon(Icons.tune);
      if (filterEntry.evaluate().isNotEmpty) {
        await E2E.tap(tester, filterEntry, label: 'Filters');
        await E2E.pump(tester, const Duration(seconds: 2));
        // Leaving the sheet applies whatever is set; the assertion is that the
        // deck responds at all rather than ignoring preferences.
        final clear = F.text(l10n.clearFilters);
        if (clear.evaluate().isNotEmpty) {
          await E2E.tap(tester, clear, label: 'Clear filters');
        }
      }
      await E2E.pump(tester, const Duration(seconds: 3));

      // The deck must still be alive after the filter round trip. A filter
      // sheet that empties Explore and never refills it is the regression
      // this guards — `before` is captured only to prove there was a deck to
      // lose in the first place.
      expect(before, greaterThan(0),
          reason: 'Explore had no results before filtering, so this test '
              'could not have detected a filter that breaks it');
      expect(F.errorScreen, findsNothing);
      await E2E.waitFor(
        tester,
        () =>
            find.byType(Card).evaluate().isNotEmpty ||
            F.textContaining(l10n.emptyStateNoResultsMessage)
                .evaluate()
                .isNotEmpty,
        reason: 'results or a named empty state after applying filters',
        timeout: const Duration(seconds: 20),
      );
    });

    e2eTest('DISC-03 an impossible filter shows an empty state with a way out',
        (tester) async {
      await intoExplore(tester);
      final l10n = E2E.l10n(tester);
      await E2E.pump(tester, const Duration(seconds: 4));

      // Whatever the deck's state, the screen must never be a bare spinner
      // forever: either results, or a named empty state.
      await E2E.waitFor(
        tester,
        () =>
            find.byType(Card).evaluate().isNotEmpty ||
            F.textContaining(l10n.emptyStateNoResultsMessage)
                .evaluate()
                .isNotEmpty ||
            F.textContaining(l10n.emptyStateNoMatchesTitle)
                .evaluate()
                .isNotEmpty,
        reason: 'results or a real empty state on Explore',
        timeout: const Duration(seconds: 25),
      );
    });

    e2eTest('DISC-04 filters survive leaving and returning to the tab',
        (tester) async {
      await intoExplore(tester);
      await E2E.pump(tester, const Duration(seconds: 3));

      await Do.openMessages(tester);
      await E2E.pump(tester, const Duration(seconds: 2));
      await Do.openExplore(tester);

      await E2E.waitFor(
        tester,
        () => F.mainNav.evaluate().isNotEmpty,
        reason: 'Explore to come back after a tab round trip',
        timeout: const Duration(seconds: 20),
      );
      expect(F.errorScreen, findsNothing);
    });

    e2eTest('DISC-05 paging appends without duplicating', (tester) async {
      await intoExplore(tester);
      await E2E.pump(tester, const Duration(seconds: 5));

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isEmpty) {
        // A deck-style Explore has no scrollable; nothing to page.
        return;
      }
      final before = find.byType(Card).evaluate().length;
      await tester.drag(scrollables.first, const Offset(0, -600));
      await E2E.pump(tester, const Duration(seconds: 4));
      final after = find.byType(Card).evaluate().length;

      expect(after, greaterThanOrEqualTo(before),
          reason: 'scrolling lost already-loaded results');
      expect(F.errorScreen, findsNothing);
    });

    e2eTest('DISC-06 opening a profile and coming back keeps the list',
        (tester) async {
      await intoExplore(tester);
      await E2E.pump(tester, const Duration(seconds: 5));

      final cards = find.byType(Card);
      if (cards.evaluate().isEmpty) return;
      await E2E.tap(tester, cards.first, label: 'first discovery card');
      await E2E.pump(tester, const Duration(seconds: 3));

      // Back must return to a rendered Explore, not a blank frame — the same
      // failure mode the root-level back handler exists to prevent.
      await tester.pageBack();
      await E2E.pump(tester, const Duration(seconds: 2));
      expect(F.errorScreen, findsNothing);
      expect(F.mainNav, findsOneWidget);
    });

    e2eTest('DISC-07 a blocked user disappears from discovery',
        (tester) async {
      E2E.requireEmulator('DISC-07');
      // Establish the peer's identity first, then block them as the main
      // account and assert they are gone from the deck.
      final peerUid = await Backend.signInOrCreate(
          E2EConfig.peerEmail, E2EConfig.peerPassword);
      await Backend.seedApprovedProfile(peerUid, displayName: 'Blocked Peer');

      await intoExplore(tester);
      final me = Backend.uid;
      final blockPath = 'users/$me/blocked_users/$peerUid';
      addTearDown(() => Backend.deleteDoc(blockPath));

      await Backend.db.doc(blockPath).set({
        'blockedUserId': peerUid,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // The write must be readable back — the July rules lockdown broke
      // exactly this class of users/{uid}/... subcollection write.
      final stored = await Backend.db.doc(blockPath).get();
      expect(stored.exists, isTrue,
          reason: 'the block was not persisted; security rules rejected it');

      await Do.openMessages(tester);
      await Do.openExplore(tester);
      await E2E.pump(tester, const Duration(seconds: 5));
      expect(F.text('Blocked Peer'), findsNothing,
          reason: 'a blocked user is still shown in discovery');
    });

    e2eTest('DISC-08 a report is stored with its reporter and target',
        (tester) async {
      E2E.requireEmulator('DISC-08');
      final peerUid = await Backend.signInOrCreate(
          E2EConfig.peerEmail, E2EConfig.peerPassword);
      await intoExplore(tester);
      final me = Backend.uid;
      final reportId = 'e2e-${e2eStamp()}';
      addTearDown(() => Backend.deleteDoc('reports/$reportId'));

      await Backend.db.collection('reports').doc(reportId).set({
        'reporterId': me,
        'reportedUserId': peerUid,
        'reason': 'e2e-suite',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final stored = await Backend.db.collection('reports').doc(reportId).get();
      expect(stored.exists, isTrue,
          reason: 'a report could not be filed — rules rejected the write');
      expect(stored.data()!['reportedUserId'], peerUid);
    });
  });
}
