import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

/// Fixtures for the Universal Search tests.
///
/// The search screen's `_searchProfiles` lives inside a StatefulWidget wired to
/// DI + FirebaseFirestore.instance, so it can't be unit-tested directly. Instead
/// we mirror its two load-bearing pieces here as pure, verifiable helpers:
///   * [passesProfileSearchFilter] — the exclusion predicate applied to every
///     candidate doc (self / ghost / admin / support / non-active / no-name).
///   * [businessSubset] — the People-vs-Business split (a business owner shows
///     BOTH in People and in Business).
/// Keeping these in one place lets the tests exercise the SAME rules the screen
/// applies, over real [ProfileModel.fromFirestore] documents.

/// Replicates the per-candidate exclusion logic in
/// `UniversalSearchScreen._searchProfiles`:
///
/// ```
/// if (p.userId == currentUserId) continue;
/// if (p.isGhostMode || p.isAdmin || p.isSupport) continue;
/// if (p.accountStatus != 'active') continue;
/// if (p.displayName.trim().isEmpty) continue;
/// ```
bool passesProfileSearchFilter(Profile p, {required String currentUserId}) {
  if (p.userId == currentUserId) return false;
  if (p.isGhostMode || p.isAdmin || p.isSupport) return false;
  if (p.accountStatus != 'active') return false;
  if (p.displayName.trim().isEmpty) return false;
  return true;
}

/// The Business subset of a People result — mirrors
/// `_business = profiles.where((p) => p.isBusiness)`.
List<Profile> businessSubset(List<Profile> people) =>
    people.where((p) => p.isBusiness).toList();

/// Runs the People pipeline over a set of candidate profiles exactly as the
/// screen does: apply [passesProfileSearchFilter], de-dupe by userId, and sort
/// by lowercased displayName.
List<Profile> runPeoplePipeline(
  Iterable<Profile> candidates, {
  required String currentUserId,
}) {
  final byId = <String, Profile>{};
  for (final p in candidates) {
    if (byId.containsKey(p.userId)) continue;
    if (!passesProfileSearchFilter(p, currentUserId: currentUserId)) continue;
    byId[p.userId] = p;
  }
  final list = byId.values.toList()
    ..sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return list;
}

/// Builds a [ProfileModel] with sensible defaults; override only what a test
/// cares about. Mirrors the field shape the app reads/writes in Firestore.
ProfileModel buildProfile({
  required String userId,
  String displayName = 'Test User',
  String? nickname,
  String accountStatus = 'active',
  bool isGhostMode = false,
  bool isAdmin = false,
  bool isSupport = false,
  bool isBusiness = false,
  String? businessName,
  String? businessCategory,
  String city = 'Lisbon',
  String country = 'Portugal',
  List<String> photoUrls = const ['https://example.com/a.png'],
}) {
  return ProfileModel(
    userId: userId,
    displayName: displayName,
    nickname: nickname,
    dateOfBirth: DateTime(1990, 1, 1),
    gender: 'other',
    accountStatus: accountStatus,
    isGhostMode: isGhostMode,
    isAdmin: isAdmin,
    isSupport: isSupport,
    isBusiness: isBusiness,
    businessName: businessName,
    businessCategory: businessCategory,
    photoUrls: photoUrls,
    bio: '',
    interests: const [],
    location: LocationModel(
      latitude: 38.72,
      longitude: -9.14,
      city: city,
      country: country,
      displayAddress: '$city, $country',
    ),
    languages: const ['en'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    isComplete: true,
  );
}

/// Seeds a fresh [FakeFirebaseFirestore] `profiles` collection from the given
/// models (written via their real `toJson()` so reads go through the same
/// serialization the app uses).
Future<FakeFirebaseFirestore> seedProfiles(List<ProfileModel> profiles) async {
  final db = FakeFirebaseFirestore();
  for (final p in profiles) {
    await db.collection('profiles').doc(p.userId).set(p.toJson());
  }
  return db;
}

/// Reads every `profiles` doc back through [ProfileModel.fromFirestore] — the
/// exact codec the search screen uses via `absorb()`.
Future<List<Profile>> readProfiles(FirebaseFirestore db) async {
  final snap = await db.collection('profiles').get();
  return snap.docs.map(ProfileModel.fromFirestore).toList();
}
