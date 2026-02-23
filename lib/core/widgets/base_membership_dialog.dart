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

  const BaseMembershipDialog({
    super.key,
    required this.userId,
    this.coinBloc,
    this.profileBloc,
  });

  /// Convenience method – returns `true` when the user successfully purchases.
  static Future<bool> show({
    required BuildContext context,
    required String userId,
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
      ),
    );
    return result ?? false;
  }

  @override
  State<BaseMembershipDialog> createState() => _BaseMembershipDialogState();
}

class _BaseMembershipDialogState extends State<BaseMembershipDialog> {
  static const String _productId = 'greengo_base_membership';
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _loading = false;
  bool _retryAfterConsume = false;

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated);
    // Restore old purchases on init to consume any unconsumed ones
    // This clears "already owned" state from previous sessions
    _consumeOldPurchases();
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
                content: Text(p.error?.message ?? 'Purchase failed'),
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
        _showError('Store not available. Make sure Google Play is installed.');
        setState(() => _loading = false);
        return;
      }

      final response = await _iap.queryProductDetails({_productId});
      if (response.productDetails.isEmpty) {
        _showError(
          'Membership product not found in Google Play.\n\n'
          'Product ID: $_productId\n'
          'Make sure the product is configured in Google Play Console.',
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
        _showError('Failed to initiate purchase');
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

  // ── UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon with gold gradient
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.richGold.withValues(alpha: 0.2),
                      AppColors.richGold.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.richGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.membershipRequired,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.membershipRequiredDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Yearly price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppColors.richGold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.yearlyMembership,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Subscribe button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
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
              const SizedBox(height: 12),
              // Dismiss button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  AppLocalizations.of(context)!.maybeLater,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
