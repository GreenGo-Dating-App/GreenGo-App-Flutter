import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../coins/data/datasources/coin_remote_datasource.dart';
import '../../../coins/domain/entities/coin_transaction.dart';

/// A static mission definition from the catalog.
@immutable
class MissionDef {
  const MissionDef({
    required this.id,
    required this.title,
    required this.target,
    required this.coinReward,
    required this.icon,
  });

  final String id;

  /// English fallback title.
  // TODO(i18n): move mission titles into app_en.arb once keys are available.
  final String title;

  /// Units of progress needed to complete.
  final int target;

  /// Coins granted once when claimed.
  final int coinReward;

  final IconData icon;
}

/// Runtime state of a mission for a given user (progress + claim status).
@immutable
class MissionState {
  const MissionState({
    required this.def,
    required this.progress,
    required this.claimed,
  });

  final MissionDef def;

  /// Current progress, clamped to `[0, def.target]`.
  final int progress;

  /// Whether the coin reward has already been claimed.
  final bool claimed;

  bool get isComplete => progress >= def.target;

  /// 0..1 progress fraction for progress bars.
  double get fraction =>
      def.target <= 0 ? 1 : (progress / def.target).clamp(0.0, 1.0);
}

/// Missions / challenges that reward coins, derived cheaply from existing data.
///
/// Doc shape: `mission_progress/{userId} = { claimed: [missionId...], updatedAt }`.
/// Only the *claimed* set is persisted — live progress is DERIVED on demand from
/// the user's real activity (RSVP'd events, chat partners' countries, community
/// memberships, profile completeness, connection count). Every derivation query
/// is bounded (hard `limit`s / capped `whereIn`) and index-free (single-field
/// equality + document-id reads only), mirroring `PassportService`, so it scales
/// to millions of users without composite indexes.
class MissionsService {
  MissionsService({
    required CoinRemoteDataSource coinDataSource,
    FirebaseFirestore? firestore,
  })  : _coinDataSource = coinDataSource,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final CoinRemoteDataSource _coinDataSource;

  static const String _collection = 'mission_progress';
  static const String _conversationsCol = 'conversations';
  static const String _profilesCol = 'profiles';
  static const String _attendeesGroup = 'attendees';
  static const String _membersGroup = 'members';

  // Bounds — keep every read cheap regardless of how active the user is.
  static const int _maxConversationsPerSide = 40;
  static const int _maxPartners = 30;
  static const int _maxEventRsvps = 20;
  static const int _whereInBatch = 10; // Firestore `whereIn` hard cap.

  /// Mission ids (stable — persisted in the claimed set).
  static const String mAttendEvents = 'attend_3_events';
  static const String mConnectCountries = 'connect_3_countries';
  static const String mJoinCommunity = 'join_community';
  static const String mCompleteProfile = 'complete_profile';
  static const String mAddPeople = 'add_5_people';

  /// The fixed mission catalog (~5 missions).
  static const List<MissionDef> catalog = <MissionDef>[
    MissionDef(
      id: mAttendEvents,
      title: 'Attend 3 events',
      target: 3,
      coinReward: 100,
      icon: Icons.event_available_rounded,
    ),
    MissionDef(
      id: mConnectCountries,
      title: 'Connect with people from 3 countries',
      target: 3,
      coinReward: 150,
      icon: Icons.public_rounded,
    ),
    MissionDef(
      id: mJoinCommunity,
      title: 'Join a community',
      target: 1,
      coinReward: 50,
      icon: Icons.groups_rounded,
    ),
    MissionDef(
      id: mCompleteProfile,
      title: 'Complete your profile',
      target: 5,
      coinReward: 75,
      icon: Icons.badge_rounded,
    ),
    MissionDef(
      id: mAddPeople,
      title: 'Add 5 people',
      target: 5,
      coinReward: 100,
      icon: Icons.person_add_alt_1_rounded,
    ),
  ];

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_collection).doc(userId);

  /// Loads every mission's derived progress + claim status for [userId].
  ///
  /// Each derivation is independent and failure-isolated (a failing query yields
  /// 0 progress for that mission, never blanks the whole list). Chat partners are
  /// resolved once and reused for both the "countries" and "add people" missions.
  Future<List<MissionState>> load(String userId) async {
    if (userId.isEmpty) {
      return catalog
          .map((d) => MissionState(def: d, progress: 0, claimed: false))
          .toList();
    }

    // Claimed set (persisted).
    final claimed = <String>{};
    try {
      final snap = await _doc(userId).get();
      final list = snap.data()?['claimed'] as List<dynamic>?;
      if (list != null) {
        claimed.addAll(list.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('MissionsService.load claimed read failed: $e');
    }

    // Resolve chat partners once (reused by two missions).
    List<String> partnerIds = const <String>[];
    try {
      partnerIds = await _partnerUserIds(userId);
    } catch (e) {
      debugPrint('MissionsService.load partners failed: $e');
    }

    final results = await Future.wait<int>(<Future<int>>[
      _guard(() => _attendedEventCount(userId)), // attend events
      _guard(() => _distinctPartnerCountries(partnerIds)), // countries
      _guard(() => _joinedCommunityCount(userId)), // join community
      _guard(() => _profileCompletionSections(userId)), // complete profile
      Future<int>.value(partnerIds.length), // add people
    ]);

    return <MissionState>[
      _state(catalog[0], results[0], claimed),
      _state(catalog[1], results[1], claimed),
      _state(catalog[2], results[2], claimed),
      _state(catalog[3], results[3], claimed),
      _state(catalog[4], results[4], claimed),
    ];
  }

  MissionState _state(MissionDef def, int rawProgress, Set<String> claimed) =>
      MissionState(
        def: def,
        progress: rawProgress.clamp(0, def.target),
        claimed: claimed.contains(def.id),
      );

  /// Claims [missionId]'s reward for [userId] exactly once.
  ///
  /// Verifies the mission is complete and not yet claimed, atomically records the
  /// claim (arrayUnion), then credits coins through the existing coin path. Safe
  /// against double-claims: the transaction throws if already claimed.
  Future<void> claim(String userId, String missionId) async {
    if (userId.isEmpty) return;
    final def = catalog.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw ArgumentError('Unknown mission: $missionId'),
    );

    // Re-derive progress server-side-of-truth (cheap, bounded) to prevent
    // claiming an incomplete mission.
    final states = await load(userId);
    final state = states.firstWhere((s) => s.def.id == missionId);
    if (!state.isComplete) {
      throw StateError('Mission not complete: $missionId');
    }
    if (state.claimed) {
      throw StateError('Mission already claimed: $missionId');
    }

    // Atomically mark claimed (guards against concurrent double-claim).
    await _firestore.runTransaction((txn) async {
      final ref = _doc(userId);
      final snap = await txn.get(ref);
      final already = <String>{
        ...?(snap.data()?['claimed'] as List<dynamic>?)?.map((e) => e.toString()),
      };
      if (already.contains(missionId)) {
        throw StateError('Mission already claimed: $missionId');
      }
      txn.set(ref, <String, dynamic>{
        'claimed': FieldValue.arrayUnion(<String>[missionId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Credit coins via the existing ledger path.
    await _coinDataSource.updateBalance(
      userId: userId,
      amount: def.coinReward,
      type: CoinTransactionType.credit,
      reason: CoinTransactionReason.achievementReward,
      metadata: <String, dynamic>{
        'missionId': missionId,
        'source': 'mission_reward',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Derivation helpers (all bounded, index-free)
  // ---------------------------------------------------------------------------

  static Future<int> _guard(Future<int> Function() run) async {
    try {
      return await run();
    } catch (e) {
      debugPrint('MissionsService derivation failed: $e');
      return 0;
    }
  }

  /// Distinct events the user RSVP'd to / is attending, capped.
  Future<int> _attendedEventCount(String userId) async {
    final snap = await _firestore
        .collectionGroup(_attendeesGroup)
        .where('userId', isEqualTo: userId)
        .limit(_maxEventRsvps)
        .get();
    final eventIds = <String>{};
    for (final doc in snap.docs) {
      // Path: events/{eventId}/attendees/{docId}
      final segments = doc.reference.path.split('/');
      if (segments.length >= 2) eventIds.add(segments[1]);
    }
    return eventIds.length;
  }

  /// Communities the user is a member of (capped — we only need >= 1).
  Future<int> _joinedCommunityCount(String userId) async {
    final snap = await _firestore
        .collectionGroup(_membersGroup)
        .where(FieldPath.documentId, isEqualTo: userId)
        .limit(5)
        .get();
    return snap.docs.length;
  }

  /// The other participants of the user's 1:1 conversations, capped.
  Future<List<String>> _partnerUserIds(String userId) async {
    final ids = <String>{};

    Future<void> collect(String field) async {
      final snap = await _firestore
          .collection(_conversationsCol)
          .where(field, isEqualTo: userId)
          .limit(_maxConversationsPerSide)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        final other = u1 == userId ? u2 : u1;
        if (other != null && other.isNotEmpty && other != userId) {
          ids.add(other);
        }
        if (ids.length >= _maxPartners) break;
      }
    }

    await collect('userId1');
    if (ids.length < _maxPartners) await collect('userId2');
    return ids.take(_maxPartners).toList();
  }

  /// Number of distinct countries among the user's chat partners.
  Future<int> _distinctPartnerCountries(List<String> partnerIds) async {
    if (partnerIds.isEmpty) return 0;
    final countries = <String>{};
    for (var i = 0; i < partnerIds.length; i += _whereInBatch) {
      final batch = partnerIds.skip(i).take(_whereInBatch).toList();
      if (batch.isEmpty) break;
      final snap = await _firestore
          .collection(_profilesCol)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snap.docs) {
        final location = doc.data()['location'];
        if (location is Map) {
          final country = location['country']?.toString().trim();
          if (country != null && country.isNotEmpty) countries.add(country);
        }
      }
    }
    return countries.length;
  }

  /// How many of the 5 core profile sections are filled (photo, bio, interests,
  /// languages, location). Mirrors the profile-completion fields used elsewhere.
  Future<int> _profileCompletionSections(String userId) async {
    final snap = await _firestore.collection(_profilesCol).doc(userId).get();
    final data = snap.data();
    if (data == null) return 0;

    var filled = 0;
    final photoUrls = data['photoUrls'];
    if (photoUrls is List && photoUrls.isNotEmpty) filled++;
    final bio = data['bio'];
    if (bio is String && bio.trim().isNotEmpty) filled++;
    final interests = data['interests'];
    if (interests is List && interests.isNotEmpty) filled++;
    final languages = data['languages'];
    if (languages is List && languages.isNotEmpty) filled++;
    final location = data['location'];
    if (location is Map) {
      final city = location['city']?.toString().trim();
      if (city != null && city.isNotEmpty) filled++;
    }
    return filled;
  }
}
