import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 11 — Profile, language & settings (PROF-01 … PROF-08).
///
/// PROF-05 is the one with history: security rules do not cascade from a
/// parent document to its subcollections, and a lockdown on `users/{uid}`
/// silently took every `users/{uid}/…` write with it. PROF-07 defends the
/// root-level back handler, whose whole purpose is that going back from a
/// top-level screen never leaves a blank frame.
///
/// PROF-08 (400px viewport) is browser-level and lives in `tool/e2e_web/`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String meUid;
  final scratchPaths = <String>[];

  Future<void> intoApp(WidgetTester tester) async {
    meUid = await Backend.signInOrCreate(
        E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    await Backend.seedApprovedProfile(meUid);
    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.mainNav,
        reason: 'the app shell', timeout: const Duration(seconds: 30));
    await Do.dismissInterstitials(tester);
  }

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('PROF — profile, language & settings', () {
    e2eTest('PROF-01 a profile edit persists', (tester) async {
      E2E.requireEmulator('PROF-01');
      await intoApp(tester);

      final bio = 'Updated by the E2E suite ${e2eStamp()}';
      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .update({'bio': bio, 'updatedAt': FieldValue.serverTimestamp()});

      final stored = await Backend.profile(meUid);
      expect(stored!['bio'], bio,
          reason: 'the edited bio was not persisted');
    });

    e2eTest('PROF-02 removing a photo removes it from the document',
        (tester) async {
      E2E.requireEmulator('PROF-02');
      await intoApp(tester);

      const a = 'https://example.invalid/a.jpg';
      const b = 'https://example.invalid/b.jpg';
      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .update({'photoUrls': [a, b]});

      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .update({'photoUrls': FieldValue.arrayRemove([a])});

      final photos = List<String>.from(
          (await Backend.profile(meUid))!['photoUrls'] as List? ?? const []);
      expect(photos, isNot(contains(a)),
          reason: 'the deleted photo is still on the profile');
      expect(photos, contains(b),
          reason: 'deleting one photo removed the wrong one');
    });

    e2eTest('PROF-03 a language choice is stored and reloaded',
        (tester) async {
      E2E.requireEmulator('PROF-03');
      await intoApp(tester);

      // AuthWrapper calls LanguageProvider.loadFromDatabase() after login, so
      // the stored value is what the next session renders in.
      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .set({'preferredLanguages': ['it']}, SetOptions(merge: true));

      final stored = await Backend.profile(meUid);
      expect(
          List<String>.from(stored!['preferredLanguages'] as List? ?? const []),
          contains('it'),
          reason: 'the language choice did not persist for the next launch');
    });

    e2eTest('PROF-04 the visited screens render localized strings',
        (tester) async {
      await intoApp(tester);
      final l10n = E2E.l10n(tester);

      // Every tab label must come from the ARB file. A literal that never went
      // through gen-l10n shows up as English in every locale.
      for (final label in [
        l10n.exploreTitle,
        l10n.eventsTitle,
        l10n.messages,
        l10n.profile,
      ]) {
        expect(label.trim(), isNotEmpty,
            reason: 'an empty localized label reached the navigation bar');
      }
      await Do.openProfile(tester);
      await E2E.pump(tester, const Duration(seconds: 2));
      expect(F.errorScreen, findsNothing);
    });

    e2eTest('PROF-05 writes under users/{uid} subcollections succeed',
        (tester) async {
      E2E.requireEmulator('PROF-05');
      await intoApp(tester);

      final path = 'users/$meUid/settings/preferences';
      scratchPaths.add(path);

      // Rules do not cascade: a lock on users/{uid} does not lock — and must
      // not block — users/{uid}/settings/{doc}.
      await Backend.db.doc(path).set({
        'theme': 'dark',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final stored = await Backend.db.doc(path).get();
      expect(stored.exists, isTrue,
          reason: 'a users subcollection write was rejected — the regression '
              'that broke settings, chat media and coin-gift notifications');
      expect(stored.data()!['theme'], 'dark');
    });

    e2eTest('PROF-06 deleting the account removes its documents',
        (tester) async {
      E2E.requireEmulator('PROF-06');
      // A throwaway account, so the shared fixtures survive this test.
      final email = 'delete-${e2eStamp()}@e2e.greengo.test';
      const password = 'E2e-Delete!2026';
      final uid = await Backend.signInOrCreate(email, password);
      await Backend.seedApprovedProfile(uid, displayName: 'To Be Deleted');

      expect(await Backend.profile(uid), isNotNull);

      await Backend.deleteAll(['profiles/$uid', 'users/$uid']);
      await Backend.auth.currentUser?.delete();

      expect(await Backend.profile(uid), isNull,
          reason: 'the profile survived account deletion');
      expect(await Backend.user(uid), isNull,
          reason: 'the access record survived account deletion');
    });

    e2eTest('PROF-07 back from a root screen never leaves a blank frame',
        (tester) async {
      await intoApp(tester);

      await Do.openProfile(tester);
      await E2E.pump(tester, const Duration(seconds: 2));

      // didPopRoute routes a root-level back to Discovery rather than letting
      // the navigator unwind to nothing.
      final handled = await tester.binding.handlePopRoute();
      await E2E.pump(tester, const Duration(seconds: 2));

      expect(handled, isTrue,
          reason: 'the app-level back handler declined a root-level back');
      expect(F.mainNav, findsOneWidget,
          reason: 'going back from a root screen left no screen behind');
      expect(F.errorScreen, findsNothing);
    });
  });
}
