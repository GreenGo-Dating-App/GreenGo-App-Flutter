import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../constants/app_colors.dart';
import '../../features/coins/presentation/bloc/coin_bloc.dart';
import '../../features/coins/presentation/bloc/coin_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';

/// Dialog shown when a non-member tries to perform a gated action.
/// Offers a yearly "greengo_base_membership" IAP subscription.
///
/// Purchase ownership is tracked in Firestore `membership_purchases/{purchaseToken}`
/// to prevent a Google Play account's subscription from being applied to the wrong app user.
class BaseMembershipDialog extends StatefulWidget {
  final String userId;

  const BaseMembershipDialog({super.key, required this.userId});

  /// Convenience method – returns `true` when the user successfully purchases.
  static Future<bool> show({
    required BuildContext context,
    required String userId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BaseMembershipDialog(userId: userId),
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

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated);
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
          // Restored purchase — verify it belongs to this user before granting
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
          if (p.pendingCompletePurchase) _iap.completePurchase(p);
          break;
        case PurchaseStatus.canceled:
          if (mounted) setState(() => _loading = false);
          if (p.pendingCompletePurchase) _iap.completePurchase(p);
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  /// Handle a restored purchase — only grant membership if it belongs to this user
  Future<void> _handleRestore(PurchaseDetails p) async {
    final firestore = FirebaseFirestore.instance;
    final token = p.purchaseID ?? '';

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
            if (p.pendingCompletePurchase) _iap.completePurchase(p);
            if (mounted) setState(() => _loading = false);
            return;
          }
        }
        // Purchase belongs to this user or not tracked yet — grant membership
        _handleSuccess(p);
      } catch (e) {
        debugPrint('[BaseMembership] Error checking purchase ownership: $e');
        // On error, don't grant — safer to not auto-grant
        if (p.pendingCompletePurchase) _iap.completePurchase(p);
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // No purchase ID — can't verify ownership, don't auto-grant
      if (p.pendingCompletePurchase) _iap.completePurchase(p);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSuccess(PurchaseDetails p) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 365));

    try {
      final firestore = FirebaseFirestore.instance;
      final profileRef = firestore.collection('profiles').doc(widget.userId);

      // Update base membership status
      await profileRef.update({
        'hasBaseMembership': true,
        'baseMembershipEndDate': Timestamp.fromDate(endDate),
      });

      // Track purchase ownership — ties this Google Play purchase to this app user
      final token = p.purchaseID ?? '';
      if (token.isNotEmpty) {
        await firestore.collection('membership_purchases').doc(token).set({
          'userId': widget.userId,
          'productId': p.productID,
          'purchaseId': token,
          'purchasedAt': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(endDate),
        });
      }

      // Grant 500 bonus coins
      final balanceRef = firestore
          .collection('coin_balances')
          .doc(widget.userId);

      final balanceDoc = await balanceRef.get();
      if (balanceDoc.exists) {
        final currentTotal = balanceDoc.data()?['totalCoins'] as int? ?? 0;
        await balanceRef.update({
          'totalCoins': currentTotal + 500,
        });
      } else {
        await balanceRef.set({
          'userId': widget.userId,
          'totalCoins': 500,
          'spentCoins': 0,
          'lastUpdated': Timestamp.fromDate(now),
        });
      }

      // Add a coin batch for the bonus
      await firestore
          .collection('coin_balances')
          .doc(widget.userId)
          .collection('coinBatches')
          .add({
        'amount': 500,
        'remainingCoins': 500,
        'source': 'membership_bonus',
        'reason': 'Base membership welcome bonus',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(endDate),
      });
    } catch (e) {
      debugPrint('[BaseMembership] Firestore update failed: $e');
    }

    // Complete and consume the purchase so it can be bought again by other users
    if (p.pendingCompletePurchase) {
      await _iap.completePurchase(p);
    }
    // Explicitly consume on Android to allow re-purchase
    if (Platform.isAndroid) {
      try {
        final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(p);
      } catch (e) {
        debugPrint('[BaseMembership] Consume failed (non-critical): $e');
      }
    }

    if (mounted) {
      // Refresh coin balance and profile in the UI
      try {
        context.read<CoinBloc>().add(LoadCoinBalance(widget.userId));
      } catch (_) {}
      try {
        context.read<ProfileBloc>().add(ProfileLoadRequested(userId: widget.userId));
      } catch (_) {}
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

      final product = response.productDetails.first;
      final param = PurchaseParam(
        productDetails: product,
        applicationUserName: widget.userId,
      );

      final ok = await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
      if (!ok && mounted) {
        _showError('Failed to initiate purchase');
        setState(() => _loading = false);
      }
    } catch (e) {
      _showError('Purchase error: $e');
      if (mounted) setState(() => _loading = false);
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
              const Text(
                'Membership Required',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to be a member of GreenGo to perform this action.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppColors.richGold, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Yearly Membership',
                      style: TextStyle(
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
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
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
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
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
