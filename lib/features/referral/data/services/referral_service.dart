import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Immutable snapshot of a user's referral state.
@immutable
class ReferralStats {
  const ReferralStats({
    required this.code,
    required this.invitedCount,
    required this.coinsEarned,
    required this.hasRedeemed,
  });

  /// The user's own shareable referral code (may be empty until created).
  final String code;

  /// How many friends have redeemed this user's code.
  final int invitedCount;

  /// Total coins this user has earned through referrals.
  final int coinsEarned;

  /// Whether this user has already redeemed someone else's code.
  final bool hasRedeemed;

  ReferralStats copyWith({
    String? code,
    int? invitedCount,
    int? coinsEarned,
    bool? hasRedeemed,
  }) {
    return ReferralStats(
      code: code ?? this.code,
      invitedCount: invitedCount ?? this.invitedCount,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      hasRedeemed: hasRedeemed ?? this.hasRedeemed,
    );
  }
}

/// Paid tier a referral milestone unlocks (display only; the server grants it).
enum ReferralMilestoneTier { silver, gold, platinum }

/// One lifetime invite milestone: [count] friends joined -> 1 month of [tier].
/// Mirrors REFERRAL_MILESTONES in functions/src/referral/referralRules.ts.
@immutable
class ReferralMilestone {
  const ReferralMilestone(this.count, this.tier);

  final int count;
  final ReferralMilestoneTier tier;
}

/// Server-authoritative invite progress (`referral_stats/{uid}`, written only
/// by the redeemReferral Cloud Function; owner read-only).
@immutable
class ReferralProgress {
  const ReferralProgress({
    required this.invitedCount,
    required this.coinsEarned,
    this.milestonesGranted = const <int>{},
  });

  static const ReferralProgress empty =
      ReferralProgress(invitedCount: 0, coinsEarned: 0);

  /// Lifetime friends who joined with this user's code (every invitation
  /// counts, including those past the monthly coin cap).
  final int invitedCount;

  /// Total coins earned through invitations.
  final int coinsEarned;

  /// Milestone thresholds already granted by the server (e.g. {5, 10}).
  final Set<int> milestonesGranted;

  /// A milestone is shown as unlocked once the server granted it (or, while
  /// the grant is in flight, once the count reached it).
  bool isUnlocked(ReferralMilestone m) =>
      milestonesGranted.contains(m.count) || invitedCount >= m.count;

  /// The next milestone not reached yet, or null when all are unlocked.
  ReferralMilestone? get nextMilestone {
    for (final m in ReferralService.milestones) {
      if (invitedCount < m.count) return m;
    }
    return null;
  }

  /// Friends still needed for [nextMilestone] (0 when all are unlocked).
  int get remainingToNext {
    final next = nextMilestone;
    return next == null ? 0 : next.count - invitedCount;
  }

  static ReferralProgress fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    final granted = <int>{};
    final raw = data['milestonesGranted'];
    if (raw is List) {
      for (final v in raw) {
        if (v is num) granted.add(v.toInt());
      }
    }
    final failed = data['milestonesFailed'];
    if (failed is List) {
      for (final v in failed) {
        if (v is num) granted.remove(v.toInt());
      }
    }
    return ReferralProgress(
      invitedCount: (data['invitedCount'] as num?)?.toInt() ?? 0,
      coinsEarned: (data['coinsEarned'] as num?)?.toInt() ?? 0,
      milestonesGranted: granted,
    );
  }
}

/// Handles the "invite a friend" referral loop.
///
/// Data shape (index-free, bounded reads only):
///   referral_codes/{CODE}   = { ownerId, createdAt }
///   referrals/{userId}      = { code, invitedCount, coinsEarned,
///                               redeemedCode?, redeemedFrom?, redeemedAt? }
///                             (counters here are a display-only mirror)
///   referral_stats/{userId} = { invitedCount, coinsEarned, milestonesGranted }
///                             (server-authoritative, owner read-only)
///
/// Rewards are granted only by the redeemReferral Cloud Function.
class ReferralService {
  ReferralService({
    required this.firestore,
    Random? random,
    Future<String?> Function()? serverCode,
  })  : _random = random ?? Random.secure(),
        _serverCode = serverCode ?? _ensureCodeOnServer;

  final FirebaseFirestore firestore;
  final Random _random;
  final Future<String?> Function() _serverCode;

  /// `ensureReferralCode` callable: returns (creating when missing) the
  /// caller's invite code server-side.
  static Future<String?> _ensureCodeOnServer() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('ensureReferralCode',
            options: HttpsCallableOptions(timeout: requestTimeout))
        .call<dynamic>();
    final data = result.data;
    final code = data is Map ? data['code'] : null;
    return code is String && code.isNotEmpty ? code : null;
  }

  /// Coins the REFERRER earns per friend who redeems their code.
  /// Mirrors REFERRER_COIN_REWARD in functions/src/referral/referralRules.ts
  /// (the server is the source of truth; this is only used for display).
  static const int referrerCoinReward = 50;

  /// Monthly cap on referral coins for one referrer.
  /// Mirrors REFERRER_MONTHLY_CAP in functions/src/referral/referralRules.ts.
  static const int referrerMonthlyCap = 1000;

  /// Lifetime invite milestones, ascending.
  /// Mirrors REFERRAL_MILESTONES in functions/src/referral/referralRules.ts.
  static const List<ReferralMilestone> milestones = [
    ReferralMilestone(5, ReferralMilestoneTier.silver),
    ReferralMilestone(10, ReferralMilestoneTier.gold),
    ReferralMilestone(20, ReferralMilestoneTier.platinum),
  ];

  /// Timeout for the code lookup/creation so the screen never spins forever.
  static const Duration requestTimeout = Duration(seconds: 15);

  // Unambiguous charset (no 0/O/1/I/L) for human-friendly codes.
  static const String _charset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const int _maxCreateAttempts = 6;

  CollectionReference<Map<String, dynamic>> get _codesCollection =>
      firestore.collection('referral_codes');
  CollectionReference<Map<String, dynamic>> get _referralsCollection =>
      firestore.collection('referrals');
  CollectionReference<Map<String, dynamic>> get _statsCollection =>
      firestore.collection('referral_stats');

  String _randomCode() {
    final buffer = StringBuffer();
    for (var i = 0; i < _codeLength; i++) {
      buffer.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  /// Returns the user's existing referral code, or creates a new unique one.
  ///
  /// Idempotent: repeated calls return the same code. Bounded to a handful of
  /// single-doc reads/writes (no queries, no indexes).
  Future<String> getOrCreateCode(String userId) async {
    final referralDoc = await _referralsCollection.doc(userId).get();
    final existing = referralDoc.data()?['code'] as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // Server-side creation first (every user gets an invite link); the
    // client path below stays as a fallback for an older backend.
    try {
      final serverCode = await _serverCode();
      if (serverCode != null) return serverCode;
    } catch (e) {
      debugPrint('ReferralService: ensureReferralCode unavailable: $e');
    }

    // Generate a unique code with bounded retries.
    for (var attempt = 0; attempt < _maxCreateAttempts; attempt++) {
      final code = _randomCode();
      final codeRef = _codesCollection.doc(code);
      final codeSnapshot = await codeRef.get();
      if (codeSnapshot.exists) {
        continue; // collision — try another
      }

      await codeRef.set({
        'ownerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _referralsCollection.doc(userId).set({
        'code': code,
        'invitedCount': 0,
        'coinsEarned': 0,
      }, SetOptions(merge: true));

      return code;
    }

    throw Exception('Could not generate a unique referral code');
  }

  /// Streams the current user's referral stats for live UI updates.
  Stream<ReferralStats> statsStream(String userId) {
    return _referralsCollection.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return ReferralStats(
        code: (data?['code'] as String?) ?? '',
        invitedCount: (data?['invitedCount'] as num?)?.toInt() ?? 0,
        coinsEarned: (data?['coinsEarned'] as num?)?.toInt() ?? 0,
        hasRedeemed: (data?['redeemedCode'] as String?)?.isNotEmpty ?? false,
      );
    });
  }

  /// Streams the server-authoritative invite progress (`referral_stats/{uid}`).
  /// Rewards and milestone checkmarks come only from this document.
  Stream<ReferralProgress> progressStream(String userId) {
    return _statsCollection
        .doc(userId)
        .snapshots()
        .map((doc) => ReferralProgress.fromMap(doc.data()));
  }
}
