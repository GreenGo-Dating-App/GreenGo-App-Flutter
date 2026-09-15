import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Direct backend access for seeding fixtures and for asserting what the app
/// actually wrote.
///
/// A UI assertion alone cannot tell "the balance is 20" from "the balance
/// label says 20 but nothing was persisted". Several suites therefore check
/// the rendered screen *and* the document behind it; the pairs are where the
/// real regressions hide (double-credited coins, RSVP counted twice, a block
/// that never reached the rules).
class Backend {
  const Backend._();

  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static String get uid {
    final u = auth.currentUser;
    if (u == null) fail('Expected a signed-in user, found none.');
    return u.uid;
  }

  static String? get uidOrNull => auth.currentUser?.uid;

  // --- Reads ----------------------------------------------------------------

  static Future<Map<String, dynamic>?> profile(String userId) async {
    final d = await db.collection('profiles').doc(userId).get();
    return d.data();
  }

  static Future<Map<String, dynamic>?> user(String userId) async {
    final d = await db.collection('users').doc(userId).get();
    return d.data();
  }

  /// Polls until [read] returns a value satisfying [matches], so a test can
  /// assert an eventually-consistent write (a Cloud Function's effect, a
  /// fan-out) without sleeping for a fixed and arbitrary duration.
  static Future<T> waitForValue<T>(
    Future<T> Function() read,
    bool Function(T) matches, {
    required String reason,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    T last = await read();
    while (DateTime.now().isBefore(deadline)) {
      if (matches(last)) return last;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      last = await read();
    }
    fail('Backend never reached the expected state: $reason (last value: $last)');
  }

  /// Number of documents a query returns right now.
  static Future<int> count(Query<Map<String, dynamic>> q) async =>
      (await q.get()).size;

  // --- Writes (emulator only) ----------------------------------------------

  /// Signs in, creating the account if the emulator does not have it yet.
  /// Returns the uid. Used by fixtures, never by a test that is itself
  /// exercising the login UI.
  static Future<String> signInOrCreate(String email, String password) async {
    E2E.requireEmulator('Backend.signInOrCreate');
    try {
      final c = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      return c.user!.uid;
    } on FirebaseAuthException {
      final c = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return c.user!.uid;
    }
  }

  /// Writes a complete, approved profile — the state a real user reaches after
  /// onboarding. Field names mirror a production document.
  static Future<void> seedApprovedProfile(
    String userId, {
    String displayName = 'E2E User',
    String? nickname,
    bool isComplete = true,
    bool isBanned = false,
    bool isAdmin = false,
    bool isBusiness = false,
    String approvalStatus = 'approved',
    String verificationStatus = 'approved',
    String membershipTier = 'basic',
    List<String> languages = const ['en'],
    String country = 'IT',
  }) async {
    E2E.requireEmulator('Backend.seedApprovedProfile');
    await db.collection('profiles').doc(userId).set({
      'userId': userId,
      'displayName': displayName,
      'nickname': nickname ?? 'e2e_${userId.substring(0, 6)}',
      'bio': 'Seeded by the end-to-end suite.',
      'dateOfBirth': Timestamp.fromDate(DateTime(1995, 6, 15)),
      'isComplete': isComplete,
      'isBanned': isBanned,
      'isAdmin': isAdmin,
      'isBusiness': isBusiness,
      'verificationStatus': verificationStatus,
      'membershipTier': membershipTier,
      'languages': languages,
      'nativeLanguage': languages.first,
      'primaryOrigin': country,
      'photoUrls': <String>[],
      'interests': <String>['culture', 'languages'],
      'showOnMap': true,
      'isOnline': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await db.collection('users').doc(userId).set({
      'approvalStatus': approvalStatus,
      'membershipTier': membershipTier,
      'accessDate': Timestamp.fromDate(DateTime(2020)),
      'hasEarlyAccess': true,
      'notificationsEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes a seeded document tree. Every suite that creates data calls this
  /// in `tearDown`; a suite that leaves events and conversations behind stops
  /// being repeatable by the third run.
  static Future<void> deleteDoc(String path) async {
    E2E.requireEmulator('Backend.deleteDoc');
    try {
      await db.doc(path).delete();
    } catch (_) {
      // Already gone.
    }
  }

  static Future<void> deleteAll(Iterable<String> paths) async {
    for (final p in paths) {
      await deleteDoc(p);
    }
  }
}
