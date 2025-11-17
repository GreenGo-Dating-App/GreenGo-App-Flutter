import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/coin_balance.dart';
import '../../domain/entities/coin_gift.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../../domain/entities/coin_reward.dart';
import '../../domain/entities/coin_transaction.dart';
import '../models/coin_balance_model.dart';
import '../models/coin_gift_model.dart';
import '../models/coin_promotion_model.dart';
import '../models/coin_transaction_model.dart';

/// Coin Remote Data Source
/// Handles all coin-related operations with Firestore and in-app purchases
class CoinRemoteDataSource {
  final FirebaseFirestore firestore;
  final InAppPurchase inAppPurchase;
  final Uuid uuid;

  CoinRemoteDataSource({
    required this.firestore,
    required this.inAppPurchase,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  // Collection references
  CollectionReference get _balancesCollection =>
      firestore.collection('coinBalances');
  CollectionReference get _transactionsCollection =>
      firestore.collection('coinTransactions');
  CollectionReference get _giftsCollection => firestore.collection('coinGifts');
  CollectionReference get _promotionsCollection =>
      firestore.collection('coinPromotions');
  CollectionReference get _rewardsCollection =>
      firestore.collection('claimedRewards');

  /// Initialize in-app purchases
  Future<bool> initializePurchases() async {
    final available = await inAppPurchase.isAvailable();
    if (!available) return false;

    if (Platform.isAndroid) {
      final androidAddition =
          inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await androidAddition.enablePendingPurchases();
    }

    return true;
  }

  // ===== Balance Operations =====

  /// Get coin balance for user
  Future<CoinBalanceModel> getBalance(String userId) async {
    final doc = await _balancesCollection.doc(userId).get();

    if (!doc.exists) {
      // Create new balance if doesn't exist
      final newBalance = CoinBalanceModel.empty(userId);
      await _balancesCollection.doc(userId).set(newBalance.toFirestore());
      return newBalance;
    }

    return CoinBalanceModel.fromFirestore(doc);
  }

  /// Stream coin balance
  Stream<CoinBalanceModel> balanceStream(String userId) {
    return _balancesCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return CoinBalanceModel.empty(userId);
      }
      return CoinBalanceModel.fromFirestore(doc);
    });
  }

  /// Update coin balance
  Future<void> updateBalance({
    required String userId,
    required int amount,
    required CoinTransactionType type,
    required CoinTransactionReason reason,
    String? relatedId,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await firestore.runTransaction((transaction) async {
      final balanceRef = _balancesCollection.doc(userId);
      final balanceDoc = await transaction.get(balanceRef);

      CoinBalanceModel currentBalance;
      if (!balanceDoc.exists) {
        currentBalance = CoinBalanceModel.empty(userId);
      } else {
        currentBalance = CoinBalanceModel.fromFirestore(balanceDoc);
      }

      // Calculate new balance
      int newTotal;
      int newEarned = currentBalance.earnedCoins;
      int newPurchased = currentBalance.purchasedCoins;
      int newGifted = currentBalance.giftedCoins;
      int newSpent = currentBalance.spentCoins;

      if (type == CoinTransactionType.credit) {
        newTotal = currentBalance.totalCoins + amount;

        // Track source
        if (reason == CoinTransactionReason.coinPurchase) {
          newPurchased += amount;
        } else if (reason == CoinTransactionReason.giftReceived) {
          newGifted += amount;
        } else {
          newEarned += amount;
        }
      } else {
        // Debit
        if (currentBalance.totalCoins < amount) {
          throw Exception('Insufficient coins');
        }
        newTotal = currentBalance.totalCoins - amount;
        newSpent += amount;
      }

      // Create coin batch for credits
      List<CoinBatch> newBatches = List.from(currentBalance.coinBatches);
      if (type == CoinTransactionType.credit) {
        final source = _getCoinSource(reason);
        final batchId = uuid.v4();
        final acquiredDate = DateTime.now();
        final expirationDate = acquiredDate.add(const Duration(days: 365));

        newBatches.add(CoinBatch(
          batchId: batchId,
          initialCoins: amount,
          remainingCoins: amount,
          source: source,
          acquiredDate: acquiredDate,
          expirationDate: expirationDate,
        ));
      } else {
        // Debit: Deduct from oldest non-expired batches first (FIFO)
        int remainingToDeduct = amount;
        newBatches = newBatches.map((batch) {
          if (remainingToDeduct <= 0) return batch;
          if (batch.isExpired(DateTime.now())) return batch;

          final deductAmount = batch.remainingCoins <= remainingToDeduct
              ? batch.remainingCoins
              : remainingToDeduct;
          remainingToDeduct -= deductAmount;

          return CoinBatch(
            batchId: batch.batchId,
            initialCoins: batch.initialCoins,
            remainingCoins: batch.remainingCoins - deductAmount,
            source: batch.source,
            acquiredDate: batch.acquiredDate,
            expirationDate: batch.expirationDate,
          );
        }).where((batch) => batch.remainingCoins > 0).toList();
      }

      // Update balance
      final updatedBalance = CoinBalanceModel(
        userId: userId,
        totalCoins: newTotal,
        earnedCoins: newEarned,
        purchasedCoins: newPurchased,
        giftedCoins: newGifted,
        spentCoins: newSpent,
        lastUpdated: DateTime.now(),
        coinBatches: newBatches,
      );

      transaction.set(balanceRef, updatedBalance.toFirestore());

      // Create transaction record
      final transactionId = uuid.v4();
      final transactionModel = CoinTransactionModel(
        transactionId: transactionId,
        userId: userId,
        type: type,
        amount: amount,
        balanceAfter: newTotal,
        reason: reason,
        relatedId: relatedId,
        relatedUserId: relatedUserId,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      transaction.set(
        _transactionsCollection.doc(transactionId),
        transactionModel.toFirestore(),
      );
    });
  }

  /// Get coin source from transaction reason
  CoinSource _getCoinSource(CoinTransactionReason reason) {
    switch (reason) {
      case CoinTransactionReason.coinPurchase:
        return CoinSource.purchase;
      case CoinTransactionReason.giftReceived:
        return CoinSource.gift;
      case CoinTransactionReason.monthlyAllowance:
        return CoinSource.allowance;
      case CoinTransactionReason.promotionalBonus:
        return CoinSource.promotion;
      case CoinTransactionReason.refund:
        return CoinSource.refund;
      default:
        return CoinSource.reward;
    }
  }

  // ===== Purchase Operations =====

  /// Get available coin packages from store
  Future<List<CoinPackage>> getAvailablePackages() async {
    final productIds = CoinPackages.standardPackages
        .map((pkg) => pkg.productId)
        .toSet();

    final ProductDetailsResponse response =
        await inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      throw Exception('Failed to load products: ${response.error}');
    }

    // Merge with standard packages
    return CoinPackages.standardPackages;
  }

  /// Purchase coins
  Future<void> purchaseCoins({
    required ProductDetails product,
    required String userId,
  }) async {
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: userId,
    );

    await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Verify coin purchase (should be done server-side)
  Future<bool> verifyPurchase({
    required String userId,
    required String purchaseToken,
    required String platform,
  }) async {
    // This should call a Cloud Function to verify the purchase
    // For now, returning true for development
    return true;
  }

  // ===== Transaction Operations =====

  /// Get transaction history
  Future<List<CoinTransactionModel>> getTransactionHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => CoinTransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Stream transaction history
  Stream<List<CoinTransactionModel>> transactionStream({
    required String userId,
    int limit = 50,
  }) {
    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoinTransactionModel.fromFirestore(doc))
            .toList());
  }

  // ===== Reward Operations =====

  /// Claim reward
  Future<CoinTransactionModel> claimReward({
    required String userId,
    required CoinReward reward,
    Map<String, dynamic>? metadata,
  }) async {
    // Create transaction record first
    final transactionId = uuid.v4();
    final now = DateTime.now();

    await updateBalance(
      userId: userId,
      amount: reward.coinAmount,
      type: CoinTransactionType.credit,
      reason: _getReasonFromRewardType(reward.type),
      metadata: metadata ?? {'rewardId': reward.rewardId},
    );

    // Record claimed reward
    await _rewardsCollection.add({
      'userId': userId,
      'rewardId': reward.rewardId,
      'coinAmount': reward.coinAmount,
      'claimedAt': Timestamp.fromDate(now),
    });

    // Get the created transaction
    final transactions = await getTransactionHistory(
      userId: userId,
      limit: 1,
    );

    return transactions.first;
  }

  /// Check if reward can be claimed
  Future<bool> canClaimReward({
    required String userId,
    required String rewardId,
  }) async {
    final reward = CoinRewards.getById(rewardId);
    if (reward == null) return false;

    // Check if already claimed
    final claimedSnapshot = await _rewardsCollection
        .where('userId', isEqualTo: userId)
        .where('rewardId', isEqualTo: rewardId)
        .get();

    if (!reward.isRecurring && claimedSnapshot.docs.isNotEmpty) {
      return false; // Already claimed non-recurring reward
    }

    if (reward.maxClaims != null &&
        claimedSnapshot.docs.length >= reward.maxClaims!) {
      return false; // Max claims reached
    }

    if (reward.cooldownPeriod != null && claimedSnapshot.docs.isNotEmpty) {
      final lastClaim = claimedSnapshot.docs.first.data() as Map<String, dynamic>;
      final lastClaimedAt = (lastClaim['claimedAt'] as Timestamp).toDate();
      final cooldownEnd = lastClaimedAt.add(reward.cooldownPeriod!);

      if (DateTime.now().isBefore(cooldownEnd)) {
        return false; // Still in cooldown period
      }
    }

    return true;
  }

  /// Get claimed rewards
  Future<List<ClaimedReward>> getClaimedRewards(String userId) async {
    final snapshot = await _rewardsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('claimedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ClaimedReward(
        userId: data['userId'] as String,
        rewardId: data['rewardId'] as String,
        coinAmount: (data['coinAmount'] as num).toInt(),
        claimedAt: (data['claimedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  CoinTransactionReason _getReasonFromRewardType(RewardType type) {
    switch (type) {
      case RewardType.firstMatch:
        return CoinTransactionReason.firstMatchReward;
      case RewardType.profileCompletion:
        return CoinTransactionReason.completeProfileReward;
      case RewardType.dailyLogin:
      case RewardType.streak:
        return CoinTransactionReason.dailyLoginStreakReward;
      default:
        return CoinTransactionReason.achievementReward;
    }
  }

  // ===== Gift Operations =====

  /// Send gift
  Future<CoinGiftModel> sendGift({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  }) async {
    CoinGiftModel? gift;

    await firestore.runTransaction((transaction) async {
      // Deduct coins from sender
      await updateBalance(
        userId: senderId,
        amount: amount,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.giftSent,
        relatedUserId: receiverId,
        metadata: {'toUserId': receiverId},
      );

      // Create gift
      final giftId = uuid.v4();
      final now = DateTime.now();
      gift = CoinGiftModel(
        giftId: giftId,
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        message: message,
        status: CoinGiftStatus.pending,
        sentAt: now,
        expiresAt: now.add(CoinGiftConstraints.expirationPeriod),
      );

      transaction.set(_giftsCollection.doc(giftId), gift!.toFirestore());
    });

    return gift!;
  }

  /// Accept gift
  Future<void> acceptGift({
    required String giftId,
    required String userId,
  }) async {
    await firestore.runTransaction((transaction) async {
      final giftRef = _giftsCollection.doc(giftId);
      final giftDoc = await transaction.get(giftRef);

      if (!giftDoc.exists) {
        throw Exception('Gift not found');
      }

      final gift = CoinGiftModel.fromFirestore(giftDoc);

      if (gift.receiverId != userId) {
        throw Exception('Not authorized to accept this gift');
      }

      if (gift.status != CoinGiftStatus.pending) {
        throw Exception('Gift already processed');
      }

      // Credit coins to receiver
      await updateBalance(
        userId: userId,
        amount: gift.amount,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.giftReceived,
        relatedUserId: gift.senderId,
        metadata: {'fromUserId': gift.senderId},
      );

      // Update gift status
      transaction.update(giftRef, {
        'status': CoinGiftStatus.accepted.name,
        'receivedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Decline gift
  Future<void> declineGift({
    required String giftId,
    required String userId,
  }) async {
    await firestore.runTransaction((transaction) async {
      final giftRef = _giftsCollection.doc(giftId);
      final giftDoc = await transaction.get(giftRef);

      if (!giftDoc.exists) {
        throw Exception('Gift not found');
      }

      final gift = CoinGiftModel.fromFirestore(giftDoc);

      if (gift.receiverId != userId) {
        throw Exception('Not authorized to decline this gift');
      }

      // Refund sender
      await updateBalance(
        userId: gift.senderId,
        amount: gift.amount,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.refund,
        metadata: {'reason': 'gift_declined'},
      );

      // Update gift status
      transaction.update(giftRef, {
        'status': CoinGiftStatus.declined.name,
      });
    });
  }

  /// Get pending gifts
  Future<List<CoinGiftModel>> getPendingGifts(String userId) async {
    final snapshot = await _giftsCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CoinGiftStatus.pending.name)
        .orderBy('sentAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CoinGiftModel.fromFirestore(doc))
        .toList();
  }

  /// Get sent gifts
  Future<List<CoinGiftModel>> getSentGifts(String userId) async {
    final snapshot = await _giftsCollection
        .where('senderId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CoinGiftModel.fromFirestore(doc))
        .toList();
  }

  // ===== Monthly Allowance =====

  /// Grant monthly allowance
  Future<void> grantMonthlyAllowance({
    required String userId,
    required int amount,
    required String tier,
  }) async {
    await updateBalance(
      userId: userId,
      amount: amount,
      type: CoinTransactionType.credit,
      reason: CoinTransactionReason.monthlyAllowance,
      metadata: {
        'tier': tier,
        'year': DateTime.now().year,
        'month': DateTime.now().month,
      },
    );
  }

  /// Check if monthly allowance received
  Future<bool> hasReceivedMonthlyAllowance({
    required String userId,
    required int year,
    required int month,
  }) async {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('reason', isEqualTo: 'monthlyAllowance')
        .where('metadata.year', isEqualTo: year)
        .where('metadata.month', isEqualTo: month)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ===== Expiration Operations =====

  /// Process expired coins
  Future<void> processExpiredCoins(String userId) async {
    final balance = await getBalance(userId);
    final now = DateTime.now();
    int totalExpired = 0;

    for (final batch in balance.coinBatches) {
      if (batch.isExpired(now) && batch.remainingCoins > 0) {
        totalExpired += batch.remainingCoins;
      }
    }

    if (totalExpired > 0) {
      await updateBalance(
        userId: userId,
        amount: totalExpired,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.expired,
      );
    }
  }

  /// Get expiring coins
  Future<List<CoinBatch>> getExpiringCoins({
    required String userId,
    required int days,
  }) async {
    final balance = await getBalance(userId);
    final threshold = DateTime.now().add(Duration(days: days));

    return balance.coinBatches
        .where((batch) =>
            !batch.isExpired(DateTime.now()) &&
            batch.expirationDate.isBefore(threshold))
        .toList();
  }

  // ===== Promotion Operations =====

  /// Get active promotions
  Future<List<CoinPromotionModel>> getActivePromotions() async {
    final now = DateTime.now();
    final snapshot = await _promotionsCollection
        .where('isActive', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    return snapshot.docs
        .map((doc) => CoinPromotionModel.fromFirestore(doc))
        .toList();
  }

  /// Get promotion by code
  Future<CoinPromotionModel?> getPromotionByCode(String code) async {
    final snapshot = await _promotionsCollection
        .where('promoCode', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CoinPromotionModel.fromFirestore(snapshot.docs.first);
  }
}
