import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../data/datasources/coin_remote_datasource.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../bloc/coin_bloc.dart';
import '../bloc/coin_event.dart';
import '../bloc/coin_state.dart';

/// Coin Shop Screen
/// Point 157: Coin purchase interface with packages and membership
class CoinShopScreen extends StatefulWidget {
  final String userId;
  final SubscriptionTier? currentTier;
  final int initialTab;

  const CoinShopScreen({
    super.key,
    required this.userId,
    this.currentTier,
    this.initialTab = 0,
  });

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CoinPackage? _selectedPackage;
  CoinPromotion? _activePromotion;
  SubscriptionTier? _selectedTier;
  bool _isLoadingSubscription = false;
  bool _isLoadingCoinPurchase = false;
  InAppPurchase? _inAppPurchase;
  int _currentCoinBalance = 0;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Cached packages so they survive BLoC state transitions
  // Pre-populated with fallback packages to prevent blank screen
  List<CoinPackage> _cachedPackages = CoinPackages.standardPackages;
  List<CoinPromotion> _cachedPromotions = [];

  // Send coins state
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isSendingCoins = false;

  // Monthly vs yearly toggle for membership tab
  bool _isYearlySelected = false;

  // Mutable current tier — loaded from Firestore, updated after purchase
  late SubscriptionTier _currentTier;

  // Base membership state
  bool _hasBaseMembership = false;
  DateTime? _baseMembershipEndDate;

  // Current membership end date (for tier plans)
  DateTime? _membershipEndDate;

  @override
  void initState() {
    super.initState();
    _currentTier = widget.currentTier ?? SubscriptionTier.basic;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));

    try {
      context.read<CoinBloc>().add(LoadCoinBalance(widget.userId));
      context.read<CoinBloc>().add(const LoadAvailablePackages());
    } catch (e) {
      debugPrint('[CoinShop] Failed to dispatch BLoC events: $e');
    }

    // Load actual tier from Firestore
    _loadCurrentTierFromFirestore();

    // Safely initialize IAP and listen to purchase stream
    _initIAP();
  }

  /// Initialize In-App Purchases safely — avoids crash if plugin not available
  void _initIAP() {
    try {
      _inAppPurchase = InAppPurchase.instance;
      _purchaseSubscription = _inAppPurchase!.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          debugPrint('[IAP] Purchase stream error: $error');
        },
      );
      // Restore old purchases on init to consume any unconsumed ones
      // This clears "already owned" state from previous sessions
      _consumeOldPurchases();
    } catch (e) {
      debugPrint('[CoinShop] IAP initialization failed: $e');
      _inAppPurchase = null;
    }
  }

  /// Restore and consume any old unconsumed purchases to clear "already owned" state
  Future<void> _consumeOldPurchases() async {
    if (!Platform.isAndroid || _inAppPurchase == null) return;
    try {
      await _inAppPurchase!.restorePurchases();
    } catch (e) {
      debugPrint('[CoinShop] restorePurchases error (non-critical): $e');
    }
  }

  /// Load user's actual membership tier from Firestore
  Future<void> _loadCurrentTierFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists && mounted) {
        final data = doc.data();
        final tierString = data?['membershipTier'] as String?;
        if (tierString != null) {
          setState(() {
            _currentTier = SubscriptionTierExtension.fromString(tierString);
          });
        }
        // Load base membership state and membership end date
        setState(() {
          _hasBaseMembership = data?['hasBaseMembership'] as bool? ?? false;
          final ts = data?['baseMembershipEndDate'];
          _baseMembershipEndDate = ts != null ? (ts as Timestamp).toDate() : null;
          final endTs = data?['membershipEndDate'];
          _membershipEndDate = endTs != null ? (endTs as Timestamp).toDate() : null;
        });
      }
    } catch (e) {
      debugPrint('[CoinShop] Failed to load tier from Firestore: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purchaseSubscription?.cancel();
    _nicknameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Handle purchase updates from the IAP stream
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('[IAP] Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('[IAP] Purchase pending for ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          debugPrint('[IAP] Purchase error: ${purchaseDetails.error?.message}');
          if (mounted) {
            setState(() {
              _isLoadingCoinPurchase = false;
              _isLoadingSubscription = false;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(purchaseDetails.error?.message ?? 'Purchase failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Always consume to clear "already owned" state
          _completeAndConsume(purchaseDetails);
          break;

        case PurchaseStatus.canceled:
          debugPrint('[IAP] Purchase canceled for ${purchaseDetails.productID}');
          setState(() {
            _isLoadingCoinPurchase = false;
            _isLoadingSubscription = false;
          });
          // Always consume to clear "already owned" state
          _completeAndConsume(purchaseDetails);
          break;
      }
    }
  }

  /// Handle a successful purchase (coins or subscription)
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    final productId = purchaseDetails.productID;

    // Check if this is a base membership purchase
    if (productId == 'greengo_base_membership') {
      debugPrint('[IAP] Base membership purchase successful');
      final now = DateTime.now();
      final firestore = FirebaseFirestore.instance;

      // Compute end date: extend from current end date if active
      DateTime endDate;
      try {
        final profileDoc = await firestore
            .collection('profiles')
            .doc(widget.userId)
            .get();
        final currentEndTs = profileDoc.data()?['baseMembershipEndDate'] as Timestamp?;
        final currentEndDate = currentEndTs?.toDate();
        if (currentEndDate != null && currentEndDate.isAfter(now)) {
          endDate = currentEndDate.add(const Duration(days: 365));
        } else {
          endDate = now.add(const Duration(days: 365));
        }
      } catch (_) {
        endDate = now.add(const Duration(days: 365));
      }

      try {
        // Update base membership status
        await firestore
            .collection('profiles')
            .doc(widget.userId)
            .update({
          'hasBaseMembership': true,
          'baseMembershipEndDate': Timestamp.fromDate(endDate),
        });

        // Track purchase ownership by app userId
        final token = purchaseDetails.purchaseID ?? '';
        final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        if (token.isNotEmpty) {
          await firestore.collection('membership_purchases').doc(token).set({
            'userId': widget.userId,
            'userEmail': userEmail,
            'productId': productId,
            'purchaseId': token,
            'purchasedAt': Timestamp.fromDate(now),
            'endDate': Timestamp.fromDate(endDate),
          });
        }

        // Grant 500 bonus coins (write to coinBatches array field, not subcollection)
        final balanceRef = firestore
            .collection('coinBalances')
            .doc(widget.userId);
        final batchEntry = {
          'batchId': 'membership_${now.millisecondsSinceEpoch}',
          'initialCoins': 500,
          'remainingCoins': 500,
          'source': 'reward',
          'acquiredDate': Timestamp.fromDate(now),
          'expirationDate': Timestamp.fromDate(endDate),
        };
        final balanceDoc = await balanceRef.get();
        if (balanceDoc.exists) {
          await balanceRef.update({
            'totalCoins': FieldValue.increment(500),
            'earnedCoins': FieldValue.increment(500),
            'lastUpdated': Timestamp.fromDate(now),
            'coinBatches': FieldValue.arrayUnion([batchEntry]),
          });
        } else {
          await balanceRef.set({
            'userId': widget.userId,
            'totalCoins': 500,
            'earnedCoins': 500,
            'purchasedCoins': 0,
            'giftedCoins': 0,
            'spentCoins': 0,
            'lastUpdated': Timestamp.fromDate(now),
            'coinBatches': [batchEntry],
          });
        }
      } catch (e) {
        debugPrint('[IAP] Failed to update base membership in Firestore: $e');
      }

      await _completeAndConsume(purchaseDetails);

      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
          _hasBaseMembership = true;
          _baseMembershipEndDate = endDate;
        });
        // Refresh coin balance and profile (so membership gate unlocks)
        context.read<CoinBloc>().add(LoadCoinBalance(widget.userId));
        try {
          context.read<ProfileBloc>().add(ProfileLoadRequested(userId: widget.userId));
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shopMembershipActivated('${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}')),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Check if this is a coin purchase
    final coinPackage = CoinPackages.getByProductId(productId);
    if (coinPackage != null) {
      // Coin purchase — credit via BLoC (Firestore update)
      debugPrint('[IAP] Coin purchase successful: ${coinPackage.coinAmount} coins');
      if (mounted) {
        context.read<CoinBloc>().add(
          PurchaseCoinPackage(
            userId: widget.userId,
            package: coinPackage,
            platform: 'android',
            promotion: _activePromotion,
          ),
        );
      }
      setState(() => _isLoadingCoinPurchase = false);

      // Complete and consume the purchase
      await _completeAndConsume(purchaseDetails);

      // Show success dialog
      if (mounted) {
        PurchaseSuccessDialog.showCoinsPurchased(
          context,
          coinsAdded: coinPackage.coinAmount,
          bonusCoins: coinPackage.bonusCoins,
          onDismiss: () {
            if (context.mounted) {
              // Reload balance
              context.read<CoinBloc>().add(LoadCoinBalance(widget.userId));
            }
          },
        );
      }
      return;
    }

    // Check if this is a subscription purchase
    final subscribedTier = _tierFromProductId(productId);
    if (subscribedTier != null) {
      debugPrint('[IAP] Subscription purchase successful: ${subscribedTier.displayName}');

      // Update Firestore profile with new membership tier and get new end date
      final durationDays = _durationDaysFromProductId(productId);
      final newEndDate = await _updateFirestoreMembership(subscribedTier, durationDays: durationDays);

      // Track purchase ownership by app userId
      try {
        final firestore = FirebaseFirestore.instance;
        final token = purchaseDetails.purchaseID ?? '';
        final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        if (token.isNotEmpty) {
          await firestore.collection('membership_purchases').doc(token).set({
            'userId': widget.userId,
            'userEmail': userEmail,
            'productId': productId,
            'purchaseId': token,
            'tier': subscribedTier.name.toUpperCase(),
            'purchasedAt': Timestamp.fromDate(DateTime.now()),
            'endDate': newEndDate != null ? Timestamp.fromDate(newEndDate) : null,
          });
        }
      } catch (e) {
        debugPrint('[IAP] Failed to track purchase: $e');
      }

      // Update local tier state immediately
      setState(() {
        _currentTier = subscribedTier;
        _selectedTier = null;
        _isLoadingSubscription = false;
        _membershipEndDate = newEndDate;
      });

      // Complete and consume the purchase
      await _completeAndConsume(purchaseDetails);

      // Refresh profile
      try {
        context.read<ProfileBloc>().add(ProfileLoadRequested(userId: widget.userId));
      } catch (_) {}

      // Show celebration screen with tier-specific benefits
      if (mounted) {
        PurchaseSuccessDialog.showSubscriptionActivated(
          context,
          tierName: subscribedTier.displayName,
          tier: subscribedTier,
        );
      }
      return;
    }

    // Unknown product — still complete and consume it
    debugPrint('[IAP] Unknown product purchased: $productId');
    await _completeAndConsume(purchaseDetails);
    setState(() {
      _isLoadingCoinPurchase = false;
      _isLoadingSubscription = false;
    });
  }

  /// Map a product ID back to a SubscriptionTier
  SubscriptionTier? _tierFromProductId(String productId) {
    for (final tier in SubscriptionTier.values) {
      if (tier.monthlyProductId == productId || tier.yearlyProductId == productId) return tier;
    }
    return null;
  }

  /// Get duration in days from product ID
  int _durationDaysFromProductId(String productId) {
    if (productId.contains('1_year') || productId.contains('year')) return 365;
    return 30;
  }

  /// Complete and consume a purchase so it can be bought again
  Future<void> _completeAndConsume(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase!.completePurchase(purchaseDetails);
    }
    if (Platform.isAndroid) {
      try {
        final androidAddition = _inAppPurchase!
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(purchaseDetails);
      } catch (e) {
        debugPrint('[IAP] Consume failed (non-critical): $e');
      }
    }
  }

  /// Buy a product — all products are managed (in-app) products, use buyConsumable
  Future<bool> _buyProduct(ProductDetails product) async {
    debugPrint('[CoinShop] Buying product: ${product.id}, price: ${product.price}');
    final param = PurchaseParam(
      productDetails: product,
      applicationUserName: widget.userId,
    );
    return await _inAppPurchase!.buyConsumable(purchaseParam: param, autoConsume: false);
  }

  /// Update Firestore profile with new membership tier
  /// Handles end-date extension: extends from current end date if active
  /// Returns the new end date
  Future<DateTime?> _updateFirestoreMembership(SubscriptionTier tier, {int durationDays = 30}) async {
    try {
      final now = DateTime.now();
      final firestore = FirebaseFirestore.instance;

      // Read current membership to extend from end date
      final profileDoc = await firestore.collection('profiles').doc(widget.userId).get();
      final currentEndTs = profileDoc.data()?['membershipEndDate'] as Timestamp?;
      final currentEndDate = currentEndTs?.toDate();

      DateTime newEndDate;
      if (currentEndDate != null && currentEndDate.isAfter(now)) {
        // Extend from current end date
        newEndDate = currentEndDate.add(Duration(days: durationDays));
      } else {
        newEndDate = now.add(Duration(days: durationDays));
      }

      final updates = {
        'membershipTier': tier.name.toUpperCase(),
        'membershipStartDate': Timestamp.fromDate(now),
        'membershipEndDate': Timestamp.fromDate(newEndDate),
      };

      await firestore.collection('profiles').doc(widget.userId).update(updates);
      await firestore.collection('users').doc(widget.userId).update(updates);
      debugPrint('[CoinShop] Firestore membership updated to ${tier.name}, ends: $newEndDate');
      return newEndDate;
    } catch (e) {
      debugPrint('[CoinShop] Failed to update Firestore membership: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoinBloc, CoinState>(
      listener: (context, state) {
        // Update coin balance
        if (state is CoinBalanceLoaded) {
          setState(() {
            _currentCoinBalance = state.balance.availableCoins;
          });
        } else if (state is CoinBalanceUpdated) {
          setState(() {
            _currentCoinBalance = state.balance.availableCoins;
          });
        }
        // Update packages cache when BLoC loads them
        else if (state is CoinPackagesLoaded) {
          setState(() {
            _cachedPackages = state.packages.isNotEmpty
                ? state.packages
                : CoinPackages.standardPackages;
            _cachedPromotions = state.activePromotions;
          });
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.shopTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _safeBuild(_buildBuyCoinsTab, 'Coins'),
          _safeBuild(_buildMembershipTab, 'Membership'),
          _safeBuild(_buildVideoCoinsTab, 'Video'),
        ],
      ),
      ),
    );
  }

  String _formatCoinBalance(int coins) {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), AppColors.richGold],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context)!.shopTabCoins),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👑', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context)!.shopTabMembership),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎬', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context)!.shopTabVideo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Safely build a tab — catches any exception and shows a visible error instead of blank white
  Widget _safeBuild(Widget Function() builder, String tabName) {
    try {
      return builder();
    } catch (e, stack) {
      debugPrint('[CoinShop] Error building $tabName tab: $e\n$stack');
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  '$tabName tab error',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.shopRetry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBuyCoinsTab() {
    final safePromotions = _cachedPromotions.whereType<CoinPromotion>().toList();
    return _buildPackageList(_cachedPackages, safePromotions);
  }

  Widget _buildMembershipTab() {
    final currentTier = _currentTier;
    final tiers = [
      SubscriptionTier.silver,
      SubscriptionTier.gold,
      SubscriptionTier.platinum,
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Crown icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.diamond_rounded, size: 42, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.shopUpgradeExperience,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.shopCurrentPlan(currentTier.displayName),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.richGold.withValues(alpha: 0.8),
                ),
              ),
              if (_membershipEndDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _membershipEndDate!.isAfter(DateTime.now())
                      ? AppLocalizations.of(context)!.shopExpires(
                          '${_membershipEndDate!.day.toString().padLeft(2, '0')}/${_membershipEndDate!.month.toString().padLeft(2, '0')}/${_membershipEndDate!.year}',
                          _membershipEndDate!.difference(DateTime.now()).inDays.toString(),
                        )
                      : AppLocalizations.of(context)!.shopExpired(
                          '${_membershipEndDate!.day.toString().padLeft(2, '0')}/${_membershipEndDate!.month.toString().padLeft(2, '0')}/${_membershipEndDate!.year}',
                        ),
                  style: TextStyle(
                    fontSize: 13,
                    color: _membershipEndDate!.isAfter(DateTime.now())
                        ? const Color(0xFF4CAF50)
                        : Colors.red[300],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Monthly / Yearly toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isYearlySelected = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: !_isYearlySelected
                                ? const LinearGradient(colors: [Color(0xFFFFD700), AppColors.richGold])
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.shopMonthly,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isYearlySelected ? Colors.black : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isYearlySelected = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _isYearlySelected
                                ? const LinearGradient(colors: [Color(0xFFFFD700), AppColors.richGold])
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.shopYearly,
                                style: TextStyle(
                                  color: _isYearlySelected ? Colors.black : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.shopSavePercent(SubscriptionTier.platinum.yearlySavingsPercent.toStringAsFixed(0)),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Upgrade discount banner
              if (currentTier != SubscriptionTier.basic && currentTier != SubscriptionTier.platinum)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.shopUpgradeAndSave,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Base membership card + Subscription plans
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBaseMembershipCard(),
              const SizedBox(height: 16),
              ...tiers.map((tier) {
                final isCurrentPlan = currentTier == tier;
                final isUpgrade = tier.index > currentTier.index;
                final isDowngrade = tier.index < currentTier.index;
                return _buildSubscriptionCard(tier, isCurrentPlan, isUpgrade, isDowngrade, currentTier);
              }),
            ],
          ),
        ),

        // Subscribe button
        if (_selectedTier != null)
          _buildSubscribeButton(currentTier),
      ],
    );
  }

  Widget _buildSubscribeButton(SubscriptionTier currentTier) {
    final isUpgrade = _selectedTier!.index > currentTier.index;
    final upgradeDiscount = _isYearlySelected ? 0.0 : _calculateUpgradeDiscount(currentTier, _selectedTier!);
    final displayPrice = _isYearlySelected ? _selectedTier!.yearlyPrice : _selectedTier!.monthlyPrice;
    final finalPrice = displayPrice - upgradeDiscount;
    final periodLabel = _isYearlySelected ? '/year' : '/month';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Show savings if upgrading
            if (isUpgrade && upgradeDiscount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings, color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.shopYouSave(upgradeDiscount.toStringAsFixed(2), currentTier.displayName),
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: _isLoadingSubscription ? null : _handleSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoadingSubscription
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUpgrade
                              ? AppLocalizations.of(context)!.shopUpgradeTo(
                                  _selectedTier!.displayName,
                                  _isYearlySelected ? AppLocalizations.of(context)!.shopOneYear : AppLocalizations.of(context)!.shopOneMonth,
                                )
                              : AppLocalizations.of(context)!.shopBuyTier(
                                  _selectedTier!.displayName,
                                  _isYearlySelected ? AppLocalizations.of(context)!.shopOneYear : AppLocalizations.of(context)!.shopOneMonth,
                                ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (upgradeDiscount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\$${displayPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${finalPrice.toStringAsFixed(2)}$periodLabel  ${AppLocalizations.of(context)!.plusTaxes}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '\$${displayPrice.toStringAsFixed(2)}$periodLabel  ${AppLocalizations.of(context)!.plusTaxes}',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate upgrade discount based on current tier
  /// Users get a discount when upgrading to a higher tier
  double _calculateUpgradeDiscount(SubscriptionTier currentTier, SubscriptionTier newTier) {
    if (newTier.index <= currentTier.index) return 0.0;

    // Discount percentages for upgrades
    // Silver -> Gold: 10% off Gold price
    // Silver -> Platinum: 15% off Platinum price
    // Gold -> Platinum: 20% off Platinum price

    switch (currentTier) {
      case SubscriptionTier.silver:
        if (newTier == SubscriptionTier.gold) {
          return newTier.monthlyPrice * 0.10; // 10% off
        } else if (newTier == SubscriptionTier.platinum) {
          return newTier.monthlyPrice * 0.15; // 15% off
        }
        break;
      case SubscriptionTier.gold:
        if (newTier == SubscriptionTier.platinum) {
          return newTier.monthlyPrice * 0.20; // 20% off
        }
        break;
      case SubscriptionTier.basic:
        // No discount for new subscribers, but could add first-time discount here
        break;
      default:
        break;
    }
    return 0.0;
  }

  Widget _buildBaseMembershipCard() {
    final isActive = _hasBaseMembership &&
        _baseMembershipEndDate != null &&
        _baseMembershipEndDate!.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.basePurple.withValues(alpha: 0.2),
            AppColors.basePurpleDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.basePurple : AppColors.basePurple,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.basePurple,
                        AppColors.basePurple.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_rounded, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.shopBaseMembership,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.shopYearlyPlan,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.basePurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.shopActive,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.shopBaseMembershipDescription,
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
            if (isActive && _baseMembershipEndDate != null) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.shopValidUntil('${_baseMembershipEndDate!.day.toString().padLeft(2, '0')}/${_baseMembershipEndDate!.month.toString().padLeft(2, '0')}/${_baseMembershipEndDate!.year}'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.basePurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingSubscription ? null : _handleBaseMembershipPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.basePurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoadingSubscription
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.subscribeNow,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleBaseMembershipPurchase() async {
    if (_inAppPurchase == null) {
      _showError(AppLocalizations.of(context)!.shopStoreNotAvailable);
      return;
    }
    setState(() => _isLoadingSubscription = true);

    try {
      final available = await _inAppPurchase!.isAvailable();
      if (!available) {
        _showError(AppLocalizations.of(context)!.shopStoreNotAvailable);
        setState(() => _isLoadingSubscription = false);
        return;
      }

      const productId = 'greengo_base_membership';
      final response = await _inAppPurchase!.queryProductDetails({productId});

      if (response.productDetails.isEmpty) {
        final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
        final consoleName = Platform.isIOS ? 'App Store Connect' : 'Google Play Console';
        _showError(
          'Base membership product not found in $storeName.\n\n'
          'Product ID: $productId\n'
          'Make sure the product is configured in $consoleName.',
        );
        setState(() => _isLoadingSubscription = false);
        return;
      }

      final ok = await _buyProduct(response.productDetails.first);

      if (!ok) {
        _showError(AppLocalizations.of(context)!.shopFailedToInitiate);
        setState(() => _isLoadingSubscription = false);
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('ALREADY_OWNED') ||
          errorStr.contains('ITEM_ALREADY_OWNED') ||
          errorStr.contains('itemAlreadyOwned')) {
        debugPrint('[CoinShop] Product already owned — consuming and retrying');
        await _consumeOldPurchases();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _handleBaseMembershipPurchase(); // Retry
      } else {
        _showError('Purchase error: $e');
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  Widget _buildSubscriptionCard(SubscriptionTier tier, bool isCurrentPlan, bool isUpgrade, bool isDowngrade, SubscriptionTier currentTier) {
    final isSelected = _selectedTier == tier;
    final features = tier.features;
    final upgradeDiscount = _calculateUpgradeDiscount(currentTier, tier);

    // Tier colors
    Color tierColor;
    switch (tier) {
      case SubscriptionTier.silver:
        tierColor = const Color(0xFFC0C0C0);
        break;
      case SubscriptionTier.gold:
        tierColor = const Color(0xFFFFD700);
        break;
      case SubscriptionTier.platinum:
        tierColor = AppColors.platinumBlue;
        break;
      default:
        tierColor = Colors.grey;
    }

    return GestureDetector(
      onTap: isDowngrade ? null : () => setState(() => _selectedTier = tier),
      child: Opacity(
        opacity: isDowngrade ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      tierColor.withValues(alpha: 0.3),
                      tierColor.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? tierColor : (isCurrentPlan ? AppColors.richGold : Colors.transparent),
              width: isSelected ? 2 : (isCurrentPlan ? 1 : 0),
            ),
          ),
          child: Stack(
            children: [
              // Current plan badge with end date
              if (isCurrentPlan)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.richGold,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      _membershipEndDate != null
                          ? 'CURRENT • Expires ${_membershipEndDate!.day.toString().padLeft(2, '0')}/${_membershipEndDate!.month.toString().padLeft(2, '0')}/${_membershipEndDate!.year}'
                          : 'CURRENT',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

              // Upgrade discount badge
              if (isUpgrade && upgradeDiscount > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      'SAVE ${(upgradeDiscount / tier.monthlyPrice * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier name and price
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [tierColor, tierColor.withValues(alpha: 0.6)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              tier == SubscriptionTier.platinum ? '💎' :
                              tier == SubscriptionTier.gold ? '⭐' : '🥈',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.displayName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: tierColor,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_isYearlySelected) ...[
                                    Text(
                                      '\$${tier.yearlyPrice.toStringAsFixed(2)}/year  ${AppLocalizations.of(context)!.plusTaxes}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(\$${tier.yearlyMonthlyEquivalent.toStringAsFixed(2)}/mo)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ] else if (upgradeDiscount > 0) ...[
                                    Text(
                                      '\$${tier.monthlyPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white38,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${(tier.monthlyPrice - upgradeDiscount).toStringAsFixed(2)}/mo  ${AppLocalizations.of(context)!.plusTaxes}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '\$${tier.monthlyPrice.toStringAsFixed(2)}/month  ${AppLocalizations.of(context)!.plusTaxes}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isDowngrade)
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? tierColor : Colors.grey,
                            size: 28,
                          ),
                        if (isDowngrade)
                          const Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Features list
                    _buildFeatureRow(AppLocalizations.of(context)!.shopDailyLikes, _formatLimit(features['dailyLikes'] as int)),
                    _buildFeatureRow(AppLocalizations.of(context)!.shopSuperLikes, _formatLimit(features['superLikes'] as int)),
                    _buildFeatureRow('Badge', features['badge'] == true ? '✓' : '✗'),
                    if (features['advancedFilters'] == true)
                      _buildFeatureRow('Advanced Filters', '✓'),
                    if (features['readReceipts'] == true)
                      _buildFeatureRow('Read Receipts', '✓'),
                    if (features['incognitoMode'] == true)
                      _buildFeatureRow('Incognito Mode', features['travelling'] == true ? 'Unlimited' : '✓'),
                    if (features['travelling'] == true)
                      _buildFeatureRow('Travelling', 'Unlimited'),
                    if (tier == SubscriptionTier.platinum) ...[
                      _buildFeatureRow(AppLocalizations.of(context)!.shopVipBadge, '✓'),
                      _buildFeatureRow(AppLocalizations.of(context)!.shopPriorityMatching, '✓'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String value) {
    final isEnabled = value == '✓' || value == 'Unlimited' || (int.tryParse(value) ?? 0) > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check : Icons.close,
            size: 16,
            color: isEnabled ? Colors.green : Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              fontSize: 13,
              color: isEnabled ? Colors.white70 : Colors.white38,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLimit(int limit) {
    if (limit == -1) return 'Unlimited';
    return limit.toString();
  }

  Future<void> _handleSubscribe() async {
    if (_selectedTier == null) return;

    setState(() => _isLoadingSubscription = true);

    try {
      final currentTier = _currentTier;
      final isUpgrade = _selectedTier!.index > currentTier.index;

      // Check if store is available
      final bool available = await _inAppPurchase!.isAvailable();
      debugPrint('[Subscription] Store available: $available');

      if (!available) {
        _showError(AppLocalizations.of(context)!.shopStoreNotAvailable);
        setState(() => _isLoadingSubscription = false);
        return;
      }

      // Query product details from store (monthly or yearly based on toggle)
      final productId = _isYearlySelected
          ? _selectedTier!.yearlyProductId
          : _selectedTier!.monthlyProductId;
      final productIds = {productId};
      debugPrint('[Subscription] Querying product IDs: $productIds');

      final ProductDetailsResponse response =
          await _inAppPurchase!.queryProductDetails(productIds);

      debugPrint('[Subscription] Query response - notFoundIDs: ${response.notFoundIDs}');
      debugPrint('[Subscription] Query response - productDetails count: ${response.productDetails.length}');

      if (response.error != null) {
        debugPrint('[Subscription] Query error: ${response.error!.message}');
        _showError('Failed to load subscription: ${response.error!.message}');
        setState(() => _isLoadingSubscription = false);
        return;
      }

      if (response.productDetails.isEmpty) {
        final notFoundIds = response.notFoundIDs.join(', ');
        final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
        final consoleName = Platform.isIOS ? 'App Store Connect' : 'Google Play Console';
        _showError(
          'Product "$productId" not found in $storeName.\n\n'
          'Requirements:\n'
          '• Upload app to $consoleName\n'
          '• Create in-app product in $consoleName\n'
          '• Add your account as a tester\n\n'
          'Not found: $notFoundIds'
        );
        setState(() => _isLoadingSubscription = false);
        return;
      }

      // Initiate subscription purchase
      final productDetails = response.productDetails.first;
      debugPrint('[Subscription] Found product: ${productDetails.id} - ${productDetails.title} - ${productDetails.price}');

      // Log upgrade info
      if (isUpgrade) {
        final offerId = _selectedTier!.getUpgradeOfferId(currentTier);
        debugPrint('[Subscription] Upgrading with offer: $offerId, discount: ${_selectedTier!.getUpgradeDiscount(currentTier) * 100}%');
      }

      final success = await _buyProduct(productDetails);

      debugPrint('[Subscription] purchase result: $success');

      if (!success) {
        _showError(AppLocalizations.of(context)!.shopFailedToInitiate);
        setState(() => _isLoadingSubscription = false);
      }
      // Do NOT pop navigator or show snackbar here.
      // The purchase stream listener will handle the result.
    } catch (e, stackTrace) {
      debugPrint('[Subscription] Error: $e');
      debugPrint('[Subscription] Stack trace: $stackTrace');
      final errorStr = e.toString();
      if (errorStr.contains('ALREADY_OWNED') ||
          errorStr.contains('ITEM_ALREADY_OWNED') ||
          errorStr.contains('itemAlreadyOwned')) {
        debugPrint('[Subscription] Product already owned — consuming and retrying');
        await _consumeOldPurchases();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _handleSubscribe(); // Retry
      } else {
        _showError('Purchase error: ${e.toString()}');
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildVideoCoinsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Video icon with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.richGold.withValues(alpha: 0.3),
                  AppColors.richGold.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎬',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Coming Soon text with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), AppColors.richGold],
            ).createShader(bounds),
            child: Text(
              AppLocalizations.of(context)!.shopComingSoon,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.shopVideoCoinsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Glass notification card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppColors.richGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.shopGetNotified,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.shopNotifyMessage,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList(
    List<CoinPackage> packages,
    List<CoinPromotion> promotions,
  ) {
    return Column(
      children: [
        // Header with coin icon
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Gold coin icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🪙',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${AppLocalizations.of(context)!.shopYouHave} ',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    TextSpan(
                      text: '$_currentCoinBalance',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    TextSpan(
                      text: ' ${AppLocalizations.of(context)!.shopGreenGoCoins}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.shopUnlockPremium,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Active promotion banner
        if (promotions.isNotEmpty) _buildPromotionBanner(promotions.first),

        // Package list + Send Coins
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...packages.map((package) {
                final isPopular = package.packageId == 'popular_500';
                return _buildPackageCard(package, isPopular);
              }),
              const SizedBox(height: 24),
              _buildSendCoinsSection(),
            ],
          ),
        ),

        // Purchase button
        if (_selectedPackage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isLoadingCoinPurchase ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoadingCoinPurchase
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.shopPurchaseCoinsFor(_selectedPackage!.totalCoins.toString(), _selectedPackage!.displayPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromotionBanner(CoinPromotion promotion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  promotion.displayText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (promotion.daysRemaining > 0)
            Text(
              '${promotion.daysRemaining}d left',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    CoinPackage package,
    bool isPopular,
  ) {
    final isSelected = _selectedPackage?.packageId == package.packageId;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                    const Color(0xFFFFD700).withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            // Popular badge
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.shopPopular,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Package content — vertical layout like membership cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Gold coin icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🪙', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Coin amount + bonus on separate lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${package.coinAmount} ${AppLocalizations.of(context)!.shopCoins}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${package.displayPrice} ${AppLocalizations.of(context)!.plusTaxes}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(package.coinsPerDollar).toStringAsFixed(0)} coins/\$',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (package.bonusCoins != null && package.bonusCoins! > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${package.bonusCoins} bonus coins',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Selection indicator
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFFFFD700) : Colors.grey,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle coin purchase via IAP (Google Play on Android, App Store on iOS)
  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoadingCoinPurchase = true);

    try {
      // Check if store is available
      final bool available = await _inAppPurchase!.isAvailable();
      debugPrint('[CoinPurchase] Store available: $available');

      if (!available) {
        _showError(AppLocalizations.of(context)!.shopStoreNotAvailable);
        setState(() => _isLoadingCoinPurchase = false);
        return;
      }

      // Query product details from store
      final productIds = {_selectedPackage!.productId};
      debugPrint('[CoinPurchase] Querying product IDs: $productIds');

      final ProductDetailsResponse response =
          await _inAppPurchase!.queryProductDetails(productIds);

      debugPrint('[CoinPurchase] Query response - notFoundIDs: ${response.notFoundIDs}');
      debugPrint('[CoinPurchase] Query response - productDetails count: ${response.productDetails.length}');

      if (response.error != null) {
        debugPrint('[CoinPurchase] Query error: ${response.error!.message}');
        _showError('Failed to load product: ${response.error!.message}');
        setState(() => _isLoadingCoinPurchase = false);
        return;
      }

      if (response.productDetails.isEmpty) {
        final notFoundIds = response.notFoundIDs.join(', ');
        final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
        final consoleName = Platform.isIOS ? 'App Store Connect' : 'Google Play Console';
        _showError(
          'Coin package "${_selectedPackage!.productId}" not found in $storeName.\n\n'
          'Requirements:\n'
          '• Upload app to $consoleName\n'
          '• Create in-app products in $consoleName\n'
          '• Add your account as a tester\n\n'
          'Not found: $notFoundIds'
        );
        setState(() => _isLoadingCoinPurchase = false);
        return;
      }

      // Initiate consumable purchase
      final productDetails = response.productDetails.first;
      debugPrint('[CoinPurchase] Found product: ${productDetails.id} - ${productDetails.title} - ${productDetails.price}');

      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: widget.userId,
      );

      // This triggers the store purchase dialog (Google Play on Android, App Store on iOS)
      // Result will be handled by the purchase stream listener
      final bool success = await _inAppPurchase!.buyConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('[CoinPurchase] buyConsumable result: $success');

      if (!success) {
        _showError(AppLocalizations.of(context)!.shopFailedToInitiate);
        setState(() => _isLoadingCoinPurchase = false);
      }
    } catch (e, stackTrace) {
      debugPrint('[CoinPurchase] Error: $e');
      debugPrint('[CoinPurchase] Stack trace: $stackTrace');
      _showError('Purchase error: ${e.toString()}');
      setState(() => _isLoadingCoinPurchase = false);
    }
  }

  Widget _buildSendCoinsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.richGold.withOpacity(0.15),
                ),
                child: const Icon(Icons.card_giftcard, color: AppColors.richGold, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.shopSendCoins,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nickname input
          TextField(
            controller: _nicknameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.shopRecipientNickname,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.richGold, size: 20),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.richGold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.shopEnterAmount,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.monetization_on, color: AppColors.richGold, size: 20),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.richGold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingCoins ? null : _handleSendCoins,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSendingCoins
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.shopSendCoins,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendCoins() async {
    final nickname = _nicknameController.text.trim().toLowerCase();
    final amountText = _amountController.text.trim();

    if (nickname.isEmpty || amountText.isEmpty) {
      _showError(AppLocalizations.of(context)!.shopEnterBothFields);
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError(AppLocalizations.of(context)!.shopEnterValidAmount);
      return;
    }

    if (amount > _currentCoinBalance) {
      _showError(AppLocalizations.of(context)!.shopInsufficientCoins);
      return;
    }

    setState(() => _isSendingCoins = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Find recipient by nickname
      final recipientQuery = await firestore
          .collection('profiles')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        _showError(AppLocalizations.of(context)!.shopUserNotFound);
        setState(() => _isSendingCoins = false);
        return;
      }

      final recipientDoc = recipientQuery.docs.first;
      final recipientId = recipientDoc.id;
      final recipientData = recipientDoc.data();
      final recipientName = recipientData['displayName'] as String? ?? nickname;
      final recipientPhotoUrl = (recipientData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
          ? recipientData['photoUrls'][0] as String
          : null;
      final recipientFamilyName = recipientData['familyName'] as String? ?? '';

      if (recipientId == widget.userId) {
        _showError(AppLocalizations.of(context)!.shopCannotSendToSelf);
        setState(() => _isSendingCoins = false);
        return;
      }

      setState(() => _isSendingCoins = false);

      // Show user preview confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context)!.shopConfirmSend, style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User preview card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.backgroundDark,
                      backgroundImage: recipientPhotoUrl != null
                          ? NetworkImage(recipientPhotoUrl)
                          : null,
                      child: recipientPhotoUrl == null
                          ? const Icon(Icons.person, color: AppColors.textTertiary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$recipientName${recipientFamilyName.isNotEmpty ? ' $recipientFamilyName' : ''}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@$nickname',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amount info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.richGold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$amount coins',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.shopSend, style: const TextStyle(color: AppColors.richGold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isSendingCoins = true);

      // Use proper datasource to debit sender (FIFO batch deduction) and credit recipient
      final coinDataSource = di.sl<CoinRemoteDataSource>();

      // Debit sender — updates totalCoins, spentCoins, and coinBatches (FIFO)
      await coinDataSource.updateBalance(
        userId: widget.userId,
        amount: amount,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.giftSent,
        relatedUserId: recipientId,
        metadata: {
          'recipientNickname': nickname,
          'recipientName': recipientName,
        },
      );

      // Credit recipient — adds a new coin batch
      await coinDataSource.updateBalance(
        userId: recipientId,
        amount: amount,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.giftReceived,
        relatedUserId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _currentCoinBalance -= amount;
          _nicknameController.clear();
          _amountController.clear();
          _isSendingCoins = false;
        });
        // Reload balance from Firestore to sync with batches
        context.read<CoinBloc>().add(LoadCoinBalance(widget.userId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shopCoinsSentTo(amount.toString(), nickname)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.shopFailedToSendCoins);
      setState(() => _isSendingCoins = false);
    }
  }

  /// Build error state with retry button and fallback packages
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.shopUnableToLoadPackages,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Retry button
            ElevatedButton.icon(
              onPressed: () {
                context.read<CoinBloc>().add(const LoadAvailablePackages());
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.shopRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Info text
            Text(
              AppLocalizations.of(context)!.shopCheckInternet,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
