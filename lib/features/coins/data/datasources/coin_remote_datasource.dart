import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';

import '../../../chat/domain/chat_system_message.dart';
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
    // Default source: server when online (same freshness as before), cache
    // when offline instead of failing. Live updates come from balanceStream.
    final doc = await _balancesCollection.doc(userId).get();

    if (!doc.exists && doc.metadata.isFromCache) {
      // A cached "missing" is not proof the doc is missing on the server:
      // never create (and so possibly overwrite) a balance from the cache,
      // and don't show a fake 0 either. Same outcome as the old
      // server-only read when offline: an error.
      throw StateError('Coin balance unavailable offline');
    }

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

  /// Update coin balance (credits).
  ///
  /// Spending is server-authoritative (security audit C-03 / H-12): every
  /// debit goes through [spendCoins] or a gift callable, which price the
  /// feature and debit in one server transaction. A client-side debit here is
  /// refused so no new call site can slip back to the old path. The single
  /// exception is the legacy in-app admin tool ([adminAdjustCoins]).
  Future<void> updateBalance({
    required String userId,
    required int amount,
    required CoinTransactionType type,
    required CoinTransactionReason reason,
    String? relatedId,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    if (type == CoinTransactionType.debit &&
        reason != CoinTransactionReason.adminAdjustment) {
      throw UnsupportedError(
          'Client-side coin debits are not allowed; use spendCoins()');
    }
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

        newBatches.add(CoinBatch(
          batchId: batchId,
          initialCoins: amount,
          remainingCoins: amount,
          source: source,
          acquiredDate: acquiredDate,
        ));
      } else {
        // Debit: deduct from the oldest batches first (FIFO)
        var remainingToDeduct = amount;
        newBatches = newBatches.map((batch) {
          if (remainingToDeduct <= 0) return batch;

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
  /// Store-priced packages from the last successful store query this
  /// session. Store prices don't change mid-session, so re-opening the shop
  /// skips the billing round-trip.
  static List<CoinPackage>? _sessionPackages;

  Future<List<CoinPackage>> getAvailablePackages() async {
    final memo = _sessionPackages;
    if (memo != null) return memo;
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

      final priced = fallback.map((pkg) {
        final details = byId[pkg.productId];
        if (details == null) return pkg;
        return pkg.copyWith(
          storePrice: details.price,
          price: details.rawPrice,
          currency: details.currencyCode,
        );
      }).toList();
      _sessionPackages = priced; // only real store results are memoised
      return priced;
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

  // ===== Spending (server-authoritative) =====

  /// Spend coins on [featureId] through the `spendCoins` callable.
  ///
  /// The server owns the price table (the client never sends a price),
  /// refuses unknown features, debits FIFO over `coinBatches` in one
  /// transaction and, for server-owned effects (profile boost, incognito,
  /// event featuring, business promotion), applies the effect in that same
  /// transaction. [requestId] is the idempotency key for ONE user action:
  /// generate it once per tap and reuse it on retry, so a retried call never
  /// charges twice.
  ///
  /// [option] selects a priced option: hours for `event_boost`, days for
  /// `event_featured` / `business_promotion`.
  ///
  /// Throws [CoinRefusalException] for a refusal the user should understand
  /// (insufficient coins, unknown feature); other errors propagate.
  Future<CoinSpendReceipt> spendCoins({
    required String featureId,
    String? requestId,
    String? relatedId,
    int? option,
  }) async {
    final payload = <String, dynamic>{
      'featureId': featureId,
      'requestId': requestId ?? uuid.v4(),
      if (relatedId != null) 'relatedId': relatedId,
      if (option != null) 'option': option,
    };
    try {
      final result =
          await functions.httpsCallable('spendCoins').call<Object?>(payload);
      return CoinSpendReceipt.fromMap(
          Map<String, dynamic>.from(result.data as Map? ?? const {}));
    } on FirebaseFunctionsException catch (e) {
      throw CoinRefusalException.fromFunctions(e) ?? e;
    }
  }

  // ===== Gift Operations =====

  /// Instant coin transfer (Shop "send coins") through the `giftCoins`
  /// callable: the sender is debited and the receiver credited atomically on
  /// the server. Subject to the 72h hold on recently purchased coins and the
  /// daily gift limits ([CoinRefusalException]).
  Future<GiftCoinsResult> giftCoins({
    required String receiverId,
    required int amount,
    String? message,
    String? requestId,
  }) async {
    try {
      final result = await functions.httpsCallable('giftCoins').call<Object?>({
        'receiverId': receiverId,
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
        'requestId': requestId ?? uuid.v4(),
      });
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      return GiftCoinsResult(
        giftId: data['giftId'] as String?,
        senderNewBalance: (data['senderNewBalance'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      throw CoinRefusalException.fromFunctions(e) ?? e;
    }
  }

  /// Send gift.
  ///
  /// Runs server-side (`sendGift` callable): the sender is debited into a
  /// server escrow and the pending `coinGifts` doc is created there, so the
  /// receiver's accept / decline settles real, escrowed coins. [senderId] is
  /// taken from the auth context server-side.
  Future<CoinGiftModel> sendGift({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
    String? requestId,
  }) async {
    final Map<String, dynamic> data;
    try {
      final result = await functions.httpsCallable('sendGift').call<Object?>({
        'receiverId': receiverId,
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
        'requestId': requestId ?? uuid.v4(),
      });
      data = Map<String, dynamic>.from(result.data as Map? ?? const {});
    } on FirebaseFunctionsException catch (e) {
      throw CoinRefusalException.fromFunctions(e) ?? e;
    }

    final now = DateTime.now();
    DateTime? millis(Object? v) => v is num
        ? DateTime.fromMillisecondsSinceEpoch(v.toInt())
        : null;
    final gift = CoinGiftModel(
      giftId: data['giftId'] as String? ?? '',
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      message: data['message'] as String? ?? message,
      status: CoinGiftStatus.pending,
      sentAt: millis(data['sentAt']) ?? now,
      expiresAt: millis(data['expiresAt']) ??
          now.add(CoinGiftConstraints.expirationPeriod),
    );

    // After the gift is sent, create a chat notification for the receiver
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

    return gift;
  }

  /// Create a conversation and send a system message when coins are gifted
  Future<void> _createGiftChatNotification({
    required String senderId,
    required String receiverId,
    required int amount,
  }) async {
    // Get sender's display name
    final senderProfile = await firestore.collection('profiles').doc(senderId).get();
    // Empty when unknown: readers render a localized "Unknown user".
    final senderName = senderProfile.exists
        ? (senderProfile.data()?['nickname'] as String? ??
           senderProfile.data()?['displayName'] as String? ??
           '')
        : '';

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

    // English fallback (old app versions, server push). Readers render
    // `metadata.systemKey` / the notification `data.kind` in their language.
    final systemMessage =
        '${senderName.isNotEmpty ? senderName : 'Someone'} sent you $amount coins!';
    final systemMetadata = chatSystemMetadata(
      ChatSystemKey.coinsReceived,
      {'name': senderName, 'amount': amount},
    );

    await messageRef.set({
      'messageId': messageId,
      'matchId': matchId ?? '',
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': systemMessage,
      'type': 'system',
      'metadata': systemMetadata,
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
        'metadata': systemMetadata,
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
      'data': {
        'action': 'profile',
        'profileId': senderId,
        'senderId': senderId,
        // Lets the notification list render title + body localized.
        'kind': 'coin_gift',
        'senderName': senderName,
        'amount': amount,
      },
      'senderId': senderId,
      'conversationId': conversationId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept gift.
  ///
  /// Server-side (`acceptGift` callable): the receiver is credited from the
  /// gift's server escrow (or, for a gift sent by an older app version, only
  /// against the sender's proven debit). [userId] comes from the auth context.
  Future<void> acceptGift({
    required String giftId,
    required String userId,
  }) async {
    await functions.httpsCallable('acceptGift').call<Object?>(<String, dynamic>{
      'giftId': giftId,
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

  // ===== Promotion Operations =====

  /// Get active promotions
  Future<List<CoinPromotionModel>> getActivePromotions() async {
    final now = DateTime.now();
    final nowTs = Timestamp.fromDate(now);
    try {
      // Bounded: not-yet-ended promotions soonest-ending first, startDate
      // checked client-side. Needs index coinPromotions(isActive, endDate).
      final snapshot = await _promotionsCollection
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThanOrEqualTo: nowTs)
          .orderBy('endDate')
          .limit(20)
          .get();
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final startDate = data?['startDate'] as Timestamp?;
            return startDate != null && startDate.compareTo(nowTs) <= 0;
          })
          .map(CoinPromotionModel.fromFirestore)
          .toList();
    } on FirebaseException catch (e) {
      // Index not built yet -> previous (unbounded) query below.
      if (e.code != 'failed-precondition') rethrow;
      debugPrint('[Coins] promotions index missing, legacy query: $e');
    }

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

    // Create line item based on order type. `kind` (+ `coinCount`) is what
    // the app renders, localized; `description` is the English fallback.
    String description;
    String kind;
    switch (order.type) {
      case OrderType.coins:
        description = '${order.itemQuantity} GreenGo Coins';
        kind = InvoiceLineKind.coins;
        break;
      case OrderType.subscription:
        description = 'Subscription Plan';
        kind = InvoiceLineKind.subscription;
        break;
      case OrderType.gift:
        description = 'Coin Gift Package';
        kind = InvoiceLineKind.gift;
        break;
    }

    final lineItems = [
      InvoiceLineItem(
        itemId: order.packageId,
        description: description,
        quantity: 1,
        unitPrice: order.subtotal,
        totalPrice: order.subtotal,
        kind: kind,
        coinCount: order.type == OrderType.coins ? order.itemQuantity : null,
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

/// Receipt of a server-side coin spend (`spendCoins`).
class CoinSpendReceipt {
  const CoinSpendReceipt({
    required this.featureId,
    required this.charged,
    required this.newBalance,
    this.transactionId,
    this.alreadyProcessed = false,
    this.effect = const <String, dynamic>{},
  });

  factory CoinSpendReceipt.fromMap(Map<String, dynamic> data) {
    final effect = data['effect'];
    return CoinSpendReceipt(
      featureId: data['featureId'] as String? ?? '',
      charged: (data['charged'] as num?)?.toInt() ?? 0,
      newBalance: (data['newBalance'] as num?)?.toInt() ?? 0,
      transactionId: data['transactionId'] as String?,
      alreadyProcessed: data['alreadyProcessed'] as bool? ?? false,
      effect: effect is Map
          ? Map<String, dynamic>.from(effect)
          : const <String, dynamic>{},
    );
  }

  final String featureId;

  /// Coins actually debited (0 for testers).
  final int charged;
  final int newBalance;

  /// The `coinTransactions` doc id of the debit (null when nothing was charged).
  final String? transactionId;
  final bool alreadyProcessed;

  /// Server-applied effect values, epoch millis (e.g. `boostExpiry`,
  /// `incognitoExpiry`, `featuredUntil`, `businessPromotedUntil`).
  final Map<String, dynamic> effect;

  /// An effect timestamp as a [DateTime], or null.
  DateTime? effectTime(String key) {
    final v = effect[key];
    return v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
  }
}

/// Outcome of the `giftCoins` callable.
class GiftCoinsResult {
  const GiftCoinsResult({required this.senderNewBalance, this.giftId});
  final String? giftId;
  final int senderNewBalance;
}

/// A coin refusal the user should be told about in plain words.
///
/// [reason] is the server reason code: `insufficient-coins`,
/// `gift-purchase-hold`, `gift-velocity-limit` or `unknown-feature`. The code
/// is part of [toString] so it survives the repositories' string failures and
/// is still recognised by `classifyUserError`.
class CoinRefusalException implements Exception {
  const CoinRefusalException(this.reason, [this.message]);

  static const String insufficientCoins = 'insufficient-coins';
  static const String giftPurchaseHold = 'gift-purchase-hold';
  static const String giftVelocityLimit = 'gift-velocity-limit';
  static const String unknownFeature = 'unknown-feature';

  static const Set<String> knownReasons = {
    insufficientCoins,
    giftPurchaseHold,
    giftVelocityLimit,
    unknownFeature,
  };

  /// The refusal carried by a callable error, or null when it is not one.
  static CoinRefusalException? fromFunctions(FirebaseFunctionsException e) {
    final details = e.details;
    String? reason;
    if (details is Map && details['reason'] is String) {
      reason = details['reason'] as String;
    } else {
      final msg = e.message ?? '';
      for (final r in knownReasons) {
        if (msg.startsWith(r)) reason = r;
      }
    }
    if (reason == null || !knownReasons.contains(reason)) return null;
    return CoinRefusalException(reason, e.message);
  }

  /// Refusal [reason] found in an error or failure text, or null.
  static String? reasonIn(Object? error) {
    if (error is CoinRefusalException) return error.reason;
    final text = error?.toString() ?? '';
    for (final r in knownReasons) {
      if (text.contains(r)) return r;
    }
    return null;
  }

  final String reason;
  final String? message;

  bool get isInsufficientCoins => reason == insufficientCoins;

  @override
  String toString() => 'CoinRefusalException($reason): ${message ?? ''}';
}
