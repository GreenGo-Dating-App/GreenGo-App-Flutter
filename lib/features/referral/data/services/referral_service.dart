import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../coins/data/datasources/coin_remote_datasource.dart';
import '../../../coins/domain/entities/coin_transaction.dart';

/// Coins granted to BOTH the referrer and the new user when a referral code is
/// successfully redeemed. Adjustable.
const int kReferralReward = 200; // adjustable

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

/// Handles the "invite a friend" referral loop.
///
/// Data shape (index-free, bounded reads only):
///   referral_codes/{CODE}   = { ownerId, createdAt }
///   referrals/{userId}      = { code, invitedCount, coinsEarned,
///                               redeemedCode?, redeemedFrom?, redeemedAt? }
///
/// Coins are granted to both parties through the existing coin credit path
/// ([CoinRemoteDataSource.updateBalance] with a [CoinTransactionReason.referralBonus]).
class ReferralService {
  ReferralService({
    required this.firestore,
    required this.coinDataSource,
    Random? random,
  }) : _random = random ?? Random.secure();

  final FirebaseFirestore firestore;
  final CoinRemoteDataSource coinDataSource;
  final Random _random;

  // Unambiguous charset (no 0/O/1/I/L) for human-friendly codes.
  static const String _charset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const int _maxCreateAttempts = 6;

  CollectionReference<Map<String, dynamic>> get _codesCollection =>
      firestore.collection('referral_codes');
  CollectionReference<Map<String, dynamic>> get _referralsCollection =>
      firestore.collection('referrals');

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

  /// Redeems [code] for a brand-new user, granting [kReferralReward] coins to
  /// BOTH the referrer and the new user.
  ///
  /// Returns `true` on success. Returns `false` (no throw) when the code is
  /// invalid, is the user's own code, or the user has already redeemed a code.
  ///
  /// The single-redemption guard is claimed atomically inside a transaction on
  /// `referrals/{newUserId}.redeemedCode` before any coins are granted.
  Future<bool> redeemCode({
    required String newUserId,
    required String code,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    String? ownerId;

    try {
      ownerId = await firestore.runTransaction<String?>((transaction) async {
        final newUserRef = _referralsCollection.doc(newUserId);
        final newUserSnap = await transaction.get(newUserRef);

        // Already redeemed? — guard.
        final already = newUserSnap.data()?['redeemedCode'] as String?;
        if (already != null && already.isNotEmpty) {
          return null;
        }

        final codeSnap = await transaction.get(_codesCollection.doc(normalized));
        if (!codeSnap.exists) return null;

        final resolvedOwner = codeSnap.data()?['ownerId'] as String?;
        if (resolvedOwner == null || resolvedOwner.isEmpty) return null;

        // Cannot redeem your own code.
        if (resolvedOwner == newUserId) return null;

        // Claim the guard atomically (merge so we don't clobber an existing code).
        transaction.set(newUserRef, {
          'redeemedCode': normalized,
          'redeemedFrom': resolvedOwner,
          'redeemedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return resolvedOwner;
      });
    } catch (e) {
      debugPrint('[Referral] redeem transaction failed: $e');
      return false;
    }

    if (ownerId == null) return false;

    // Guard is claimed — now grant coins to both parties via the existing
    // coin credit path. relatedUserId is set to the redeeming user on the
    // referrer's ledger entry so the coinTransactions security rule (writer
    // must be a party to the entry) is satisfied.
    try {
      await coinDataSource.updateBalance(
        userId: ownerId,
        amount: kReferralReward,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.referralBonus,
        relatedUserId: newUserId,
        metadata: {'referredUserId': newUserId, 'code': normalized},
      );

      await coinDataSource.updateBalance(
        userId: newUserId,
        amount: kReferralReward,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.referralBonus,
        relatedUserId: ownerId,
        metadata: {'referrerId': ownerId, 'code': normalized},
      );

      // Increment the referrer's aggregate counters (merge in case the doc is
      // absent — e.g. referrer created their code on another device).
      await _referralsCollection.doc(ownerId).set({
        'invitedCount': FieldValue.increment(1),
        'coinsEarned': FieldValue.increment(kReferralReward),
      }, SetOptions(merge: true));

      // Track the new user's earned coins too.
      await _referralsCollection.doc(newUserId).set({
        'coinsEarned': FieldValue.increment(kReferralReward),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('[Referral] coin grant failed after redeem: $e');
      // Guard remains claimed; coins may be partially granted. MVP-acceptable.
      return false;
    }
  }
}
