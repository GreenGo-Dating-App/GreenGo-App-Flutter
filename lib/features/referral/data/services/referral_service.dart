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
    Random? random,
  }) : _random = random ?? Random.secure();

  final FirebaseFirestore firestore;
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

  /// Redeems [code] via the secure `redeemReferral` Cloud Function, which grants
  /// the referrer +100 coins (capped at 1000/month) and gives this new user 1
  /// month of Platinum. All validation (self-referral, single-redemption, cap)
  /// is enforced server-side.
  ///
  /// [newUserId] is accepted for API compatibility but the server uses the
  /// caller's auth uid. Returns `true` on success, `false` on any rejection
  /// (invalid / own code / already redeemed) — never throws.
  Future<bool> redeemCode({
    required String newUserId,
    required String code,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('redeemReferral')
          .call<dynamic>({'code': normalized});
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Referral] redeemReferral failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Referral] redeemReferral error: $e');
      return false;
    }
  }
}
