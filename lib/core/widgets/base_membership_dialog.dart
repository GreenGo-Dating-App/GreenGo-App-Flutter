import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../constants/app_colors.dart';
import '../../features/coins/presentation/bloc/coin_bloc.dart';
import '../../features/coins/presentation/bloc/coin_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../generated/app_localizations.dart';

/// Dialog shown when a non-member tries to perform a gated action.
/// Offers a yearly "greengo_base_membership" IAP subscription.
///
/// Purchase ownership is tracked in Firestore `membership_purchases/{purchaseToken}`
/// to prevent a Google Play account's subscription from being applied to the wrong app user.
class BaseMembershipDialog extends StatefulWidget {
  final String userId;
  final CoinBloc? coinBloc;
  final ProfileBloc? profileBloc;
  final bool isExtending;

  const BaseMembershipDialog({
    super.key,
    required this.userId,
    this.coinBloc,
    this.profileBloc,
    this.isExtending = false,
  });

  /// Convenience method – returns `true` when the user successfully purchases.
  static Future<bool> show({
    required BuildContext context,
    required String userId,
    bool isExtending = false,
  }) async {
    // Capture blocs from the parent context before opening the dialog,
    // since the dialog's own context won't have access to them.
    CoinBloc? coinBloc;
    ProfileBloc? profileBloc;
    try { coinBloc = context.read<CoinBloc>(); } catch (_) {}
    try { profileBloc = context.read<ProfileBloc>(); } catch (_) {}

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BaseMembershipDialog(
        userId: userId,
        coinBloc: coinBloc,
        profileBloc: profileBloc,
        isExtending: isExtending,
      ),
    );
    return result ?? false;
  }

  @override
  State<BaseMembershipDialog> createState() => _BaseMembershipDialogState();
}

class _BaseMembershipDialogState extends State<BaseMembershipDialog>
    with TickerProviderStateMixin {
  static const String _productId = 'greengo_base_membership';
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _loading = false;
  bool _retryAfterConsume = false;

  // Animation controllers
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated);
    // Restore old purchases on init to consume any unconsumed ones
    // This clears "already owned" state from previous sessions
    _consumeOldPurchases();

    // Shimmer effect — continuous sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse glow on the CTA button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale-in entrance
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();
  }

  /// Restore and consume any old unconsumed purchases to clear "already owned" state
  Future<void> _consumeOldPurchases() async {
    if (!Platform.isAndroid) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[BaseMembership] restorePurchases error (non-critical): $e');
    }
  }

  /// Complete and consume a purchase (works for managed products to allow re-purchase)
  Future<void> _completeAndConsume(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
    if (Platform.isAndroid) {
      try {
        final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(p);
        debugPrint('[BaseMembership] Consumed purchase ${p.productID}');
      } catch (e) {
        debugPrint('[BaseMembership] Consume failed (non-critical): $e');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shimmerController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ── Purchase stream handler ──────────────────────────────────────────
  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID != _productId) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
          // New purchase — always belongs to the current user
          _handleSuccess(p);
          break;
        case PurchaseStatus.restored:
          // Restored purchase — always consume to clear "already owned" state,
          // then check ownership before granting membership
          _handleRestore(p);
          break;
        case PurchaseStatus.error:
          if (mounted) setState(() => _loading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(p.error?.message ?? AppLocalizations.of(context)!.coinsPurchaseFailed),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Always consume to clear "already owned" state
          _completeAndConsume(p);
          break;
        case PurchaseStatus.canceled:
          if (mounted) setState(() => _loading = false);
          // Always consume to clear "already owned" state
          _completeAndConsume(p);
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  /// Handle a restored purchase — always consume to clear "already owned",
  /// then check ownership before granting membership
  Future<void> _handleRestore(PurchaseDetails p) async {
    final firestore = FirebaseFirestore.instance;
    final token = p.purchaseID ?? '';

    // Always consume restored purchases to clear "already owned" state
    // This allows the product to be purchased again by any user
    await _completeAndConsume(p);

    if (token.isNotEmpty) {
      try {
        final purchaseDoc = await firestore
            .collection('membership_purchases')
            .doc(token)
            .get(const GetOptions(source: Source.server));

        if (purchaseDoc.exists) {
          final ownerUserId = purchaseDoc.data()?['userId'] as String?;
          if (ownerUserId != null && ownerUserId != widget.userId) {
            // This purchase belongs to a different app user — don't grant
            debugPrint('[BaseMembership] Restored purchase belongs to $ownerUserId, '
                'not current user ${widget.userId}. Skipping.');
            if (mounted) setState(() => _loading = false);
            return;
          }
        }
        // Purchase belongs to this user or not tracked yet
        // Don't re-grant (already granted on original purchase)
        debugPrint('[BaseMembership] Restored purchase consumed. Owner: ${widget.userId}');
        if (mounted) setState(() => _loading = false);
      } catch (e) {
        debugPrint('[BaseMembership] Error checking purchase ownership: $e');
        if (mounted) setState(() => _loading = false);
      }
    } else {
      debugPrint('[BaseMembership] Restored purchase consumed (no token).');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSuccess(PurchaseDetails p) async {
    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;

    // Compute end date: extend from current end date if active
    // Force server read to avoid stale cache on repeat purchases
    DateTime endDate;
    try {
      final profileDoc = await firestore
          .collection('profiles')
          .doc(widget.userId)
          .get(const GetOptions(source: Source.server));
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
      final profileRef = firestore.collection('profiles').doc(widget.userId);

      // Update base membership status
      await profileRef.update({
        'hasBaseMembership': true,
        'baseMembershipEndDate': Timestamp.fromDate(endDate),
      });

      // Track purchase ownership — ties this purchase to the APP user (not Google Play email)
      final token = p.purchaseID ?? '';
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (token.isNotEmpty) {
        await firestore.collection('membership_purchases').doc(token).set({
          'userId': widget.userId,
          'userEmail': userEmail,
          'productId': p.productID,
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
      debugPrint('[BaseMembership] Firestore update failed: $e');
    }

    // Complete and consume the purchase so it can be bought again
    await _completeAndConsume(p);

    if (mounted) {
      // Refresh coin balance and profile in the UI using the captured blocs
      widget.coinBloc?.add(LoadCoinBalance(widget.userId));
      widget.profileBloc?.add(ProfileLoadRequested(userId: widget.userId));
      setState(() => _loading = false);
      Navigator.of(context).pop(true);
    }
  }

  // ── Trigger IAP ──────────────────────────────────────────────────────
  Future<void> _subscribe() async {
    setState(() => _loading = true);

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _showError(AppLocalizations.of(context)!.shopStoreNotAvailable);
        setState(() => _loading = false);
        return;
      }

      final response = await _iap.queryProductDetails({_productId});
      if (response.productDetails.isEmpty) {
        final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
        final consoleName = Platform.isIOS ? 'App Store Connect' : 'Google Play Console';
        _showError(
          'Membership product not found in $storeName.\n\n'
          'Product ID: $_productId\n'
          'Make sure the product is configured in $consoleName.',
        );
        setState(() => _loading = false);
        return;
      }

      // All products are managed (in-app) products — use buyConsumable
      final product = response.productDetails.first;
      debugPrint('[BaseMembership] Product: ${product.id}, title: ${product.title}, '
          'price: ${product.price}, rawPrice: ${product.rawPrice}');

      final param = PurchaseParam(
        productDetails: product,
        applicationUserName: widget.userId,
      );
      final bool ok = await _iap.buyConsumable(purchaseParam: param, autoConsume: false);

      if (!ok && mounted) {
        _showError(AppLocalizations.of(context)!.shopFailedToInitiate);
        setState(() => _loading = false);
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('ALREADY_OWNED') ||
          errorStr.contains('ITEM_ALREADY_OWNED') ||
          errorStr.contains('itemAlreadyOwned')) {
        debugPrint('[BaseMembership] Product already owned — consuming and retrying');
        if (!_retryAfterConsume) {
          _retryAfterConsume = true;
          await _consumeOldPurchases();
          await Future.delayed(const Duration(seconds: 2));
          if (_retryAfterConsume && mounted) {
            _retryAfterConsume = false;
            _subscribe(); // Retry after consuming
          }
        } else {
          _showError('Product already owned. Please restart the app and try again.');
          if (mounted) setState(() => _loading = false);
        }
      } else {
        _showError('Purchase error: $e');
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── Helper: feature row ──────────────────────────────────────────────
  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGold.withValues(alpha: 0.3),
                  AppColors.richGold.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Icon(icon, color: AppColors.accentGold, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.08),
                    blurRadius: 60,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Animated shimmer overlay
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(-1.0 + 2.0 * _shimmerController.value, -0.3),
                            end: Alignment(0.0 + 2.0 * _shimmerController.value, 0.3),
                            colors: [
                              Colors.transparent,
                              AppColors.richGold.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: AppColors.backgroundCard),
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trial badge with glow
                          if (!widget.isExtending) ...[
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accentGold,
                                        AppColors.richGold,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGold.withValues(
                                          alpha: 0.3 + 0.3 * _pulseAnimation.value,
                                        ),
                                        blurRadius: 12 + 8 * _pulseAnimation.value,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    l10n.membershipTrialBadge,
                                    style: const TextStyle(
                                      color: AppColors.deepBlack,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Animated icon with glow ring
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.accentGold.withValues(alpha: 0.25),
                                      AppColors.richGold.withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.richGold.withValues(
                                        alpha: 0.15 + 0.15 * _pulseAnimation.value,
                                      ),
                                      blurRadius: 20 + 10 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.isExtending ? Icons.autorenew : Icons.diamond_outlined,
                                  color: AppColors.accentGold,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            widget.isExtending
                                ? l10n.membershipExtendTitle
                                : l10n.membershipTrialTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Subtitle
                          Text(
                            widget.isExtending
                                ? l10n.membershipExtendDescription
                                : l10n.membershipTrialSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.richGold.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Feature list
                          if (!widget.isExtending) ...[
                            _featureRow(Icons.all_inclusive, l10n.membershipTrialFeature1),
                            _featureRow(Icons.monetization_on_outlined, l10n.membershipTrialFeature2),
                            _featureRow(Icons.verified_outlined, l10n.membershipTrialFeature3),
                            const SizedBox(height: 20),
                          ],
                          // Yearly price badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.richGold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.yearlyMembership,
                                  style: const TextStyle(
                                    color: AppColors.richGold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // CTA button with animated glow
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentGold.withValues(
                                        alpha: 0.2 + 0.2 * _pulseAnimation.value,
                                      ),
                                      blurRadius: 16 + 8 * _pulseAnimation.value,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: _loading ? null : _subscribe,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.accentGold, AppColors.richGold],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.deepBlack,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.rocket_launch, color: AppColors.deepBlack, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                widget.isExtending
                                                    ? l10n.subscribeNow
                                                    : l10n.membershipTrialCta,
                                                style: const TextStyle(
                                                  color: AppColors.deepBlack,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Trial footer text
                          if (!widget.isExtending)
                            Text(
                              l10n.membershipTrialFooter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textTertiary.withValues(alpha: 0.7),
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Dismiss button
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              l10n.maybeLater,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
