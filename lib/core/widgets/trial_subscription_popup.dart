import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../constants/app_colors.dart';

/// Popup asking users to start a 7-day free trial of Base Membership
/// via Google Play / Apple Pay store purchase.
///
/// The trial period is configured in the store (App Store Connect / Google Play Console).
/// "Start Free Trial" triggers `buyNonConsumable()` for `greengo_base_membership`.
/// The membership is activated ONLY after a successful store purchase.
///
/// `barrierDismissible: false` — user cannot dismiss without completing the purchase.
class TrialSubscriptionPopup extends StatefulWidget {
  final String userId;
  final VoidCallback? onTrialStarted;

  const TrialSubscriptionPopup({
    super.key,
    required this.userId,
    this.onTrialStarted,
  });

  /// Show the trial popup. Returns true if purchase was successful.
  static Future<bool> show({
    required BuildContext context,
    required String userId,
    VoidCallback? onTrialStarted,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return TrialSubscriptionPopup(
          userId: userId,
          onTrialStarted: onTrialStarted,
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  State<TrialSubscriptionPopup> createState() => _TrialSubscriptionPopupState();
}

class _TrialSubscriptionPopupState extends State<TrialSubscriptionPopup>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _checkController;
  bool _loading = false;
  String? _priceLabel;
  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  static const String _productId = 'greengo_base_membership';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _loadProduct();
    _listenToPurchases();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _checkController.dispose();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  /// Query the store for product details to show the price.
  Future<void> _loadProduct() async {
    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) {
        debugPrint('[TrialPopup] Store not available');
        return;
      }

      final response = await iap.queryProductDetails({_productId});
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.first;
        if (mounted) {
          setState(() {
            _product = product;
            _priceLabel = product.price;
          });
        }
        debugPrint('[TrialPopup] Product loaded: ${product.id}, price: ${product.price}');
      } else {
        debugPrint('[TrialPopup] Product not found: $_productId');
      }
    } catch (e) {
      debugPrint('[TrialPopup] Error loading product: $e');
    }
  }

  /// Listen to the IAP purchase stream to detect successful purchase.
  void _listenToPurchases() {
    final iap = InAppPurchase.instance;
    _purchaseSubscription = iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.productID != _productId) continue;

        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _onPurchaseSuccess(purchase);
            break;
          case PurchaseStatus.error:
            debugPrint('[TrialPopup] Purchase error: ${purchase.error}');
            if (mounted) {
              setState(() => _loading = false);
              _showError('Purchase failed. Please try again.');
            }
            break;
          case PurchaseStatus.canceled:
            debugPrint('[TrialPopup] Purchase canceled');
            if (mounted) setState(() => _loading = false);
            break;
          case PurchaseStatus.pending:
            debugPrint('[TrialPopup] Purchase pending...');
            break;
        }
      }
    });
  }

  /// Handle successful purchase — complete the transaction and mark trial as started.
  Future<void> _onPurchaseSuccess(PurchaseDetails purchase) async {
    try {
      // Complete the purchase (do NOT consume — it's a subscription)
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }

      // Mark trial offer as shown and accepted in Firestore
      final nowTs = Timestamp.fromDate(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'trialOfferShown': true,
        'trialAccepted': true,
        'trialPurchaseDate': nowTs,
        'updatedAt': nowTs,
      }, SetOptions(merge: true));

      // Record email in trialHistory to prevent abuse (delete account + recreate)
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('trialHistory')
            .doc(email.toLowerCase())
            .set({
          'email': email.toLowerCase(),
          'userId': widget.userId,
          'purchaseDate': nowTs,
          'productId': _productId,
        });
      }

      debugPrint('[TrialPopup] Purchase successful for ${widget.userId}');

      widget.onTrialStarted?.call();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[TrialPopup] Error completing purchase: $e');
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  /// Trigger the store purchase flow.
  Future<void> _startFreeTrial() async {
    if (_product == null) {
      _showError('Store not available. Please try again later.');
      return;
    }

    setState(() => _loading = true);

    try {
      final iap = InAppPurchase.instance;
      ProductDetails selectedProduct = _product!;

      // On Android, ensure we have the offer token for subscription
      if (Platform.isAndroid && selectedProduct is GooglePlayProductDetails) {
        if (selectedProduct.offerToken == null) {
          // Re-query to get offer token
          final response = await iap.queryProductDetails({_productId});
          final subProduct = response.productDetails
              .whereType<GooglePlayProductDetails>()
              .where((p) => p.offerToken != null)
              .firstOrNull;
          if (subProduct != null) {
            selectedProduct = subProduct;
          }
        }
      }

      late PurchaseParam purchaseParam;
      if (Platform.isAndroid && selectedProduct is GooglePlayProductDetails) {
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: selectedProduct,
          applicationUserName: widget.userId,
        );
      } else {
        purchaseParam = PurchaseParam(
          productDetails: selectedProduct,
          applicationUserName: widget.userId,
        );
      }

      final success = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        debugPrint('[TrialPopup] buyNonConsumable returned false');
        if (mounted) {
          setState(() => _loading = false);
          _showError('Could not initiate purchase. Please try again.');
        }
      }
      // If success, the purchase stream listener will handle the result
    } catch (e) {
      debugPrint('[TrialPopup] Error starting purchase: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showError('Purchase error. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated gold glow icon
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.richGold.withValues(alpha: _glowAnimation.value),
                            AppColors.richGold.withValues(alpha: 0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: _glowAnimation.value * 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: AppColors.richGold,
                        size: 44,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Welcome to GreenGo!',
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Get your Base Membership',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                // Explanation
                Text(
                  'A Base Membership is required to access GreenGo. '
                  'Subscribe via ${Platform.isIOS ? "Apple Pay" : "Google Pay"} to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Feature highlights
                _buildFeatureItem(
                  icon: Icons.chat_bubble_outline,
                  text: 'Unlimited chat & translation',
                  delay: 0,
                ),
                _buildFeatureItem(
                  icon: Icons.monetization_on_outlined,
                  text: '500 free coins to get started',
                  delay: 1,
                ),
                _buildFeatureItem(
                  icon: Icons.tune,
                  text: 'All advanced features & filters',
                  delay: 2,
                ),
                _buildFeatureItem(
                  icon: Icons.swap_horiz,
                  text: 'Unlimited swipes & connects',
                  delay: 3,
                ),

                const SizedBox(height: 28),

                // Start Free Trial button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _startFreeTrial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.richGold.withValues(alpha: 0.4),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _priceLabel != null
                                ? 'Subscribe • $_priceLabel/year'
                                : 'Subscribe Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                // Trial info
                Text(
                  'Auto-renews yearly. Cancel anytime.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Mandatory notice
                Text(
                  'Base Membership is required to access GreenGo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required int delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _checkController,
        curve: Interval(
          delay * 0.15,
          0.6 + delay * 0.1,
          curve: Curves.easeOut,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _checkController,
          curve: Interval(
            delay * 0.15,
            0.6 + delay * 0.1,
            curve: Curves.easeOut,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.richGold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: AppColors.richGold.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
