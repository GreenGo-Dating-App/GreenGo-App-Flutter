import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/coin_balance.dart';
import '../../domain/entities/coin_gift.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_reward.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/order.dart';
import '../models/coin_balance_model.dart';
import '../models/coin_gift_model.dart';
import '../models/coin_promotion_model.dart';
import '../models/coin_transaction_model.dart';
import '../models/invoice_model.dart';
import '../models/order_model.dart';

/// Coin Remote Data Source
/// Handles all coin-related operations with Firestore and in-app purchases
class CoinRemoteDataSource {

  CoinRemoteDataSource({
    required this.firestore,
    required this.inAppPurchase,
    Uuid? uuid,
    FirebaseFunctions? functions,
  })  : uuid = uuid ?? const Uuid(),
        functions = functions ?? FirebaseFunctions.instance;
  final FirebaseFirestore firestore;
  final InAppPurchase inAppPurchase;
  final Uuid uuid;
  final FirebaseFunctions functions;

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
  CollectionReference get _ordersCollection =>
      firestore.collection('coinOrders');
  CollectionReference get _invoicesCollection =>
      firestore.collection('invoices');

  /// Initialize in-app purchases
  /// Note: Pending purchases are enabled by default in in_app_purchase 3.0+
  Future<bool> initializePurchases() async {
    final available = await inAppPurchase.isAvailable();
    return available;
  }

  // ===== Balance Operations =====

  /// Get coin balance for user
  Future<CoinBalanceModel> getBalance(String userId) async {
    final doc = await _balancesCollection.doc(userId).get(
      const GetOptions(source: Source.server),
    );

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
      var newEarned = currentBalance.earnedCoins;
      var newPurchased = currentBalance.purchasedCoins;
      var newGifted = currentBalance.giftedCoins;
      var newSpent = currentBalance.spentCoins;

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
      var newBatches = List<CoinBatch>.from(currentBalance.coinBatches);
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
        var remainingToDeduct = amount;
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

  /// Get available coin packages, priced with the REAL store price for the
  /// user's storefront (localized currency), not the hard-coded USD defaults.
  ///
  /// The catalog itself (which packages exist, and how many coins each grants)
  /// stays local — coin amounts are enforced server-side at verification time
  /// anyway. Only the *price label* comes from the store.
  ///
  /// Falls back to the hard-coded price for any product the store doesn't
  /// return, but a missing product is a store-misconfiguration signal, so it is
  /// logged loudly rather than swallowed.
  Future<List<CoinPackage>> getAvailablePackages() async {
    final fallback = CoinPackages.standardPackages;
    try {
      final available = await inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('[CoinShop] IAP not available — using fallback prices');
        return fallback;
      }

      final productIds = fallback.map((pkg) => pkg.productId).toSet();
      final response = await inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('[CoinShop] IAP query error: ${response.error} — using fallback prices');
        return fallback;
      }

      if (response.notFoundIDs.isNotEmpty) {
        // Loud on purpose: these IDs are missing/inactive in the store console,
        // or the build is not on a published track. Silently falling back here
        // is what hides a broken store setup until users complain.
        debugPrint(
          '[CoinShop] STORE MISCONFIGURATION — coin products not found: '
          '${response.notFoundIDs.join(', ')}',
        );
      }

      if (response.productDetails.isEmpty) {
        debugPrint('[CoinShop] No coin products returned — using fallback prices');
        return fallback;
      }

      // Merge the store's localized price into each package.
      final byId = <String, ProductDetails>{
        for (final pd in response.productDetails) pd.id: pd,
      };

      return fallback.map((pkg) {
        final details = byId[pkg.productId];
        if (details == null) return pkg;
        return pkg.copyWith(
          storePrice: details.price,
          price: details.rawPrice,
          currency: details.currencyCode,
        );
      }).toList();
    } catch (e) {
      debugPrint('[CoinShop] IAP error: $e — using fallback prices');
      return fallback;
    }
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

    await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  /// Verify a coin purchase receipt with the store, SERVER-SIDE, and credit the
  /// coins.
  ///
  /// This is the only sanctioned way to add purchased coins. The Cloud Function
  /// validates the receipt against the Google Play Developer API / App Store
  /// Server API, derives the coin amount from the *verified* product ID (never
  /// from anything the client sends), and writes the balance with the Admin SDK.
  /// The client never credits purchased coins itself.
  ///
  /// [purchaseToken] is `PurchaseDetails.purchaseID` (or the server verification
  /// data on Android); [verificationData] is
  /// `PurchaseDetails.verificationData.serverVerificationData` — the Play
  /// purchase token or the StoreKit 2 JWS.
  ///
  /// Returns the credited amount and the new balance. Idempotent: re-verifying
  /// the same receipt returns `coinsAdded: 0` with `alreadyProcessed: true`
  /// instead of double-crediting.
  Future<CoinPurchaseResult> verifyCoinPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
    String? verificationData,
  }) async {
    final callableName = platform == 'ios'
        ? 'verifyAppStoreCoinPurchase'
        : 'verifyGooglePlayCoinPurchase';

    final result = await functions.httpsCallable(callableName).call<Object?>({
      'productId': productId,
      'purchaseToken': purchaseToken,
      'verificationData': verificationData ?? purchaseToken,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    return CoinPurchaseResult(
      coinsAdded: (data['coinsAdded'] as num?)?.toInt() ?? 0,
      newBalance: (data['newBalance'] as num?)?.toInt() ?? 0,
      alreadyProcessed: data['alreadyProcessed'] as bool? ?? false,
    );
  }

  // ===== Transaction Operations =====

  /// Get transaction history
  Future<List<CoinTransactionModel>> getTransactionHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _transactionsCollection
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
        .map(CoinTransactionModel.fromFirestore)
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
            .map(CoinTransactionModel.fromFirestore)
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
        .limit(100) // Bounded (G0): ledger grows per user.
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

  /// Debit coins from a user's balance within an existing transaction.
  /// Returns the new total balance after deduction.
  Future<int> _debitInTransaction(
    Transaction transaction, {
    required String userId,
    required int amount,
    required CoinTransactionReason reason,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    final balanceRef = _balancesCollection.doc(userId);
    final balanceDoc = await transaction.get(balanceRef);

    CoinBalanceModel currentBalance;
    if (!balanceDoc.exists) {
      currentBalance = CoinBalanceModel.empty(userId);
    } else {
      currentBalance = CoinBalanceModel.fromFirestore(balanceDoc);
    }

    if (currentBalance.totalCoins < amount) {
      throw Exception('Insufficient coins');
    }

    final newTotal = currentBalance.totalCoins - amount;
    final newSpent = currentBalance.spentCoins + amount;

    // Deduct from oldest non-expired batches first (FIFO)
    var remainingToDeduct = amount;
    final newBatches = currentBalance.coinBatches.map((batch) {
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

    final updatedBalance = CoinBalanceModel(
      userId: userId,
      totalCoins: newTotal,
      earnedCoins: currentBalance.earnedCoins,
      purchasedCoins: currentBalance.purchasedCoins,
      giftedCoins: currentBalance.giftedCoins,
      spentCoins: newSpent,
      lastUpdated: DateTime.now(),
      coinBatches: newBatches,
    );

    transaction.set(balanceRef, updatedBalance.toFirestore());

    // Create transaction record
    final transactionId = uuid.v4();
    final txnModel = CoinTransactionModel(
      transactionId: transactionId,
      userId: userId,
      type: CoinTransactionType.debit,
      amount: amount,
      balanceAfter: newTotal,
      reason: reason,
      relatedUserId: relatedUserId,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    transaction.set(
      _transactionsCollection.doc(transactionId),
      txnModel.toFirestore(),
    );

    return newTotal;
  }

  /// Credit coins to a user's balance within an existing transaction.
  /// Returns the new total balance after credit.
  Future<int> _creditInTransaction(
    Transaction transaction, {
    required String userId,
    required int amount,
    required CoinTransactionReason reason,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    final balanceRef = _balancesCollection.doc(userId);
    final balanceDoc = await transaction.get(balanceRef);

    CoinBalanceModel currentBalance;
    if (!balanceDoc.exists) {
      currentBalance = CoinBalanceModel.empty(userId);
    } else {
      currentBalance = CoinBalanceModel.fromFirestore(balanceDoc);
    }

    final newTotal = currentBalance.totalCoins + amount;

    var newEarned = currentBalance.earnedCoins;
    var newPurchased = currentBalance.purchasedCoins;
    var newGifted = currentBalance.giftedCoins;

    if (reason == CoinTransactionReason.coinPurchase) {
      newPurchased += amount;
    } else if (reason == CoinTransactionReason.giftReceived) {
      newGifted += amount;
    } else {
      newEarned += amount;
    }

    // Create coin batch
    final source = _getCoinSource(reason);
    final batchId = uuid.v4();
    final acquiredDate = DateTime.now();
    final expirationDate = acquiredDate.add(const Duration(days: 365));

    final newBatches = List<CoinBatch>.from(currentBalance.coinBatches);
    newBatches.add(CoinBatch(
      batchId: batchId,
      initialCoins: amount,
      remainingCoins: amount,
      source: source,
      acquiredDate: acquiredDate,
      expirationDate: expirationDate,
    ));

    final updatedBalance = CoinBalanceModel(
      userId: userId,
      totalCoins: newTotal,
      earnedCoins: newEarned,
      purchasedCoins: newPurchased,
      giftedCoins: newGifted,
      spentCoins: currentBalance.spentCoins,
      lastUpdated: DateTime.now(),
      coinBatches: newBatches,
    );

    transaction.set(balanceRef, updatedBalance.toFirestore());

    // Create transaction record
    final transactionId = uuid.v4();
    final txnModel = CoinTransactionModel(
      transactionId: transactionId,
      userId: userId,
      type: CoinTransactionType.credit,
      amount: amount,
      balanceAfter: newTotal,
      reason: reason,
      relatedUserId: relatedUserId,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    transaction.set(
      _transactionsCollection.doc(transactionId),
      txnModel.toFirestore(),
    );

    return newTotal;
  }

  /// Send gift
  Future<CoinGiftModel> sendGift({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  }) async {
    CoinGiftModel? gift;

    await firestore.runTransaction((transaction) async {
      // Deduct coins from sender (inline, no nested transaction)
      await _debitInTransaction(
        transaction,
        userId: senderId,
        amount: amount,
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

    // After transaction succeeds, create a chat notification for the receiver
    try {
      await _createGiftChatNotification(
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
      );
    } catch (e) {
      debugPrint('[CoinGift] Failed to create chat notification: $e');
      // Don't throw — the gift was already sent successfully
    }

    return gift!;
  }

  /// Create a conversation and send a system message when coins are gifted
  Future<void> _createGiftChatNotification({
    required String senderId,
    required String receiverId,
    required int amount,
  }) async {
    // Get sender's display name
    final senderProfile = await firestore.collection('profiles').doc(senderId).get();
    final senderName = senderProfile.exists
        ? (senderProfile.data()?['nickname'] as String? ??
           senderProfile.data()?['displayName'] as String? ??
           'Someone')
        : 'Someone';

    // Check for existing conversation between these two users
    String? conversationId;
    String? matchId;

    // Try to find existing conversation (check both user orderings)
    final convQuery1 = await firestore.collection('conversations')
        .where('userId1', isEqualTo: senderId)
        .where('userId2', isEqualTo: receiverId)
        .limit(1)
        .get();

    if (convQuery1.docs.isNotEmpty) {
      conversationId = convQuery1.docs.first.id;
      matchId = convQuery1.docs.first.data()['matchId'] as String? ?? '';
    } else {
      final convQuery2 = await firestore.collection('conversations')
          .where('userId1', isEqualTo: receiverId)
          .where('userId2', isEqualTo: senderId)
          .limit(1)
          .get();

      if (convQuery2.docs.isNotEmpty) {
        conversationId = convQuery2.docs.first.id;
        matchId = convQuery2.docs.first.data()['matchId'] as String? ?? '';
      }
    }

    // If no conversation exists, create one
    if (conversationId == null) {
      final convRef = firestore.collection('conversations').doc();
      conversationId = convRef.id;

      // Create synthetic matchId for coin gift conversations
      final sortedIds = [senderId, receiverId]..sort();
      matchId = 'gift_${sortedIds[0]}_${sortedIds[1]}';

      await convRef.set({
        'conversationId': conversationId,
        'matchId': matchId,
        'userId1': senderId,
        'userId2': receiverId,
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'isTyping': false,
        'isPinned': false,
        'isMuted': false,
        'isArchived': false,
        'isDeleted': false,
        'conversationType': 'match',
        'theme': 'gold',
      });
    }

    // Send a system message in the conversation
    final messageId = uuid.v4();
    final messageRef = firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final systemMessage = '$senderName sent you $amount coins!';

    await messageRef.set({
      'messageId': messageId,
      'matchId': matchId ?? '',
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': systemMessage,
      'type': 'system',
      'sentAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
      'status': 'delivered',
    });

    // NOTE: we intentionally do NOT fabricate a "thank you" reply as the
    // receiver — writing a message with senderId = receiverId while running as
    // the sender is impersonation and is (correctly) denied by the message
    // security rule. Doing so also threw, which previously killed the receiver's
    // notification below. The single system message above is enough.

    // Update conversation with the real (sender's) system message as the last
    // message so the inbox preview + unread badge are correct.
    await firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': {
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': systemMessage,
        'type': 'system',
        'sentAt': Timestamp.fromDate(DateTime.now()),
      },
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });

    // Create notification for receiver. NOTE: the Flutter model reads `message`
    // (not `body`), so the body was invisible; also set the actor so the tile
    // shows the sender's tappable name.
    await firestore.collection('notifications').add({
      'userId': receiverId,
      'type': 'coin_gift',
      'title': 'You received coins!',
      'message': systemMessage,
      'body': systemMessage,
      'actorId': senderId,
      'data': {'action': 'profile', 'profileId': senderId, 'senderId': senderId},
      'senderId': senderId,
      'conversationId': conversationId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
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

      // Credit coins to receiver (inline, no nested transaction)
      await _creditInTransaction(
        transaction,
        userId: userId,
        amount: gift.amount,
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

  /// Decline gift.
  ///
  /// Declining refunds the ORIGINAL SENDER, which writes another user's
  /// `coinBalances` doc — a cross-user write Firestore rules (correctly) deny to
  /// the client. It therefore runs server-side via the `declineGift` callable
  /// (Admin SDK), which verifies the caller is the recipient, marks the gift
  /// 'declined', and refunds the sender atomically. [userId] is validated
  /// server-side from the auth context, so it is not sent.
  Future<void> declineGift({
    required String giftId,
    required String userId,
  }) async {
    final callable = functions.httpsCallable('declineGift');
    await callable.call<dynamic>(<String, dynamic>{
      'giftId': giftId,
    });
  }

  /// Get pending gifts
  Future<List<CoinGiftModel>> getPendingGifts(String userId) async {
    final snapshot = await _giftsCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CoinGiftStatus.pending.name)
        .orderBy('sentAt', descending: true)
        .limit(100) // Bounded (G0).
        .get();

    return snapshot.docs
        .map(CoinGiftModel.fromFirestore)
        .toList();
  }

  /// Get sent gifts
  Future<List<CoinGiftModel>> getSentGifts(String userId) async {
    final snapshot = await _giftsCollection
        .where('senderId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(100) // Bounded (G0).
        .get();

    return snapshot.docs
        .map(CoinGiftModel.fromFirestore)
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
    var totalExpired = 0;

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
    // Firestore only allows inequality on one field per query,
    // so filter startDate server-side and endDate client-side
    final snapshot = await _promotionsCollection
        .where('isActive', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    final nowTimestamp = Timestamp.fromDate(now);
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final endDate = data?['endDate'] as Timestamp?;
          return endDate != null && endDate.compareTo(nowTimestamp) >= 0;
        })
        .map(CoinPromotionModel.fromFirestore)
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

  // ===== Order Operations =====

  /// Create order
  Future<CoinOrderModel> createOrder({
    required String userId,
    required OrderType type,
    required String packageId,
    required int itemQuantity,
    required double subtotal,
    required double tax,
    required double total,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final orderId = uuid.v4();
    final order = CoinOrderModel(
      orderId: orderId,
      userId: userId,
      type: type,
      status: OrderStatus.pending,
      packageId: packageId,
      itemQuantity: itemQuantity,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _ordersCollection.doc(orderId).set(order.toFirestore());
    return order;
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? transactionId,
    String? paymentIntentId,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };

    if (transactionId != null) {
      updates['transactionId'] = transactionId;
    }

    if (paymentIntentId != null) {
      updates['paymentIntentId'] = paymentIntentId;
    }

    if (status == OrderStatus.completed) {
      updates['completedAt'] = Timestamp.fromDate(DateTime.now());
    }

    await _ordersCollection.doc(orderId).update(updates);
  }

  /// Get order by ID
  Future<CoinOrderModel?> getOrderById(String orderId) async {
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;
    return CoinOrderModel.fromFirestore(doc);
  }

  /// Get user orders
  Future<List<CoinOrderModel>> getUserOrders({
    required String userId,
    int? limit,
    OrderStatus? status,
  }) async {
    var query = _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(CoinOrderModel.fromFirestore)
        .toList();
  }

  /// Get all orders (admin)
  Future<List<CoinOrderModel>> getAllOrders({
    int? limit,
    OrderStatus? status,
    OrderType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _ordersCollection.orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

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
        .map(CoinOrderModel.fromFirestore)
        .toList();
  }

  /// Refund order
  Future<void> refundOrder({
    required String orderId,
    required String reason,
  }) async {
    await _ordersCollection.doc(orderId).update({
      'status': OrderStatus.refunded.name,
      'refundedAt': Timestamp.fromDate(DateTime.now()),
      'refundReason': reason,
    });
  }

  // ===== Invoice Operations =====

  /// Create invoice from order
  Future<InvoiceModel> createInvoiceFromOrder({
    required CoinOrder order,
    String? userEmail,
    String? userName,
  }) async {
    final invoiceId = uuid.v4();
    final invoiceNumber = InvoiceModel.generateInvoiceNumber();

    // Create line item based on order type
    String description;
    switch (order.type) {
      case OrderType.coins:
        description = '${order.itemQuantity} GreenGo Coins';
        break;
      case OrderType.subscription:
        description = 'Subscription Plan';
        break;
      case OrderType.gift:
        description = 'Coin Gift Package';
        break;
    }

    final lineItems = [
      InvoiceLineItem(
        itemId: order.packageId,
        description: description,
        quantity: 1,
        unitPrice: order.subtotal,
        totalPrice: order.subtotal,
      ),
    ];

    final invoice = InvoiceModel(
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      orderId: order.orderId,
      userId: order.userId,
      userEmail: userEmail,
      userName: userName,
      status: order.isCompleted ? InvoiceStatus.paid : InvoiceStatus.issued,
      issueDate: DateTime.now(),
      paidDate: order.completedAt,
      lineItems: lineItems,
      subtotal: order.subtotal,
      taxRate: order.tax > 0 ? (order.tax / order.subtotal) * 100 : 0.0,
      taxAmount: order.tax,
      total: order.total,
      currency: order.currency,
      paymentMethod: order.paymentMethod,
    );

    await _invoicesCollection.doc(invoiceId).set(invoice.toFirestore());
    return invoice;
  }

  /// Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    final doc = await _invoicesCollection.doc(invoiceId).get();
    if (!doc.exists) return null;
    return InvoiceModel.fromFirestore(doc);
  }

  /// Get user invoices
  Future<List<InvoiceModel>> getUserInvoices({
    required String userId,
    int? limit,
  }) async {
    var query = _invoicesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(InvoiceModel.fromFirestore)
        .toList();
  }

  /// Get all invoices (admin)
  Future<List<InvoiceModel>> getAllInvoices({
    int? limit,
    InvoiceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _invoicesCollection.orderBy('issueDate', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (startDate != null) {
      query = query.where('issueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('issueDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(InvoiceModel.fromFirestore)
        .toList();
  }

  // ===== Admin Operations =====

  /// Adjust user coin balance (admin only)
  Future<void> adminAdjustCoins({
    required String userId,
    required int amount,
    required String adminId,
    required String reason,
  }) async {
    await updateBalance(
      userId: userId,
      amount: amount.abs(),
      type: amount > 0 ? CoinTransactionType.credit : CoinTransactionType.debit,
      reason: CoinTransactionReason.adminAdjustment,
      metadata: {
        'adminId': adminId,
        'reason': reason,
        'adjustmentAmount': amount,
      },
    );
  }


  /// Search users by coin balance (admin)
  Future<List<Map<String, dynamic>>> searchUsersByCoins({
    int? minBalance,
    int? maxBalance,
    int limit = 50,
  }) async {
    var query = _balancesCollection.orderBy('totalCoins', descending: true);

    if (minBalance != null) {
      query = query.where('totalCoins', isGreaterThanOrEqualTo: minBalance);
    }

    if (maxBalance != null) {
      query = query.where('totalCoins', isLessThanOrEqualTo: maxBalance);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'userId': doc.id,
        ...data,
      };
    }).toList();
  }

  /// Get coin statistics (admin)
  Future<Map<String, dynamic>> getCoinStatistics() async {
    // Get total coins in circulation
    final balancesSnapshot = await _balancesCollection.get();
    var totalCoinsInCirculation = 0;
    var totalUsersWithCoins = 0;

    for (final doc in balancesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final balance = (data['totalCoins'] as num?)?.toInt() ?? 0;
      if (balance > 0) {
        totalCoinsInCirculation += balance;
        totalUsersWithCoins++;
      }
    }

    // Get recent orders stats
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final ordersSnapshot = await _ordersCollection
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .where('status', isEqualTo: OrderStatus.completed.name)
        .get();

    double totalRevenue = 0;
    final totalOrders = ordersSnapshot.docs.length;

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRevenue += (data['total'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalCoinsInCirculation': totalCoinsInCirculation,
      'totalUsersWithCoins': totalUsersWithCoins,
      'averageBalance': totalUsersWithCoins > 0
          ? totalCoinsInCirculation / totalUsersWithCoins
          : 0,
      'last30Days': {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
      },
    };
  }
}

/// Outcome of a server-verified coin purchase.
///
/// [alreadyProcessed] is true when the receipt had already been credited (for
/// example the global purchase-recovery listener and the shop screen both saw
/// the same purchase). Treat it as success — never as an error — and simply
/// refresh the balance.
class CoinPurchaseResult {
  const CoinPurchaseResult({
    required this.coinsAdded,
    required this.newBalance,
    this.alreadyProcessed = false,
  });

  final int coinsAdded;
  final int newBalance;
  final bool alreadyProcessed;
}
