import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/product_catalog.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/subscription.dart';
import '../tier_l10n.dart';
import '../../domain/membership_product_mapping.dart';
import '../bloc/subscription_bloc.dart';

/// Membership Selection Screen
/// One-time purchases for membership periods (1 month or 1 year)
class MembershipSelectionScreen extends StatefulWidget {

  const MembershipSelectionScreen({super.key, this.currentUserId});
  final String? currentUserId;

  @override
  State<MembershipSelectionScreen> createState() =>
      _MembershipSelectionScreenState();
}

class _MembershipSelectionScreenState extends State<MembershipSelectionScreen> {
  ProductDetails? _selectedProduct;
  /// Last store products shown. Survives non-product states (purchase
  /// errors, cancellations) that used to blank the list.
  List<ProductDetails> _products =
      SubscriptionBloc.sessionProducts ?? const <ProductDetails>[];
  String? _currentTierName;
  DateTime? _currentEndDate;
  bool _hasActiveBaseMembership = false;

  @override
  void initState() {
    super.initState();
    // Load available products
    context.read<SubscriptionBloc>().add(const LoadAvailableProducts());
    // Load current membership info
    _loadCurrentMembership();
  }

  Future<void> _loadCurrentMembership() async {
    if (widget.currentUserId != null) {
      try {
        final doc = await cloud_firestore.FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.currentUserId)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          final endDate =
              data['membershipEndDate'] as cloud_firestore.Timestamp?;
          final tier = data['membershipTier'] as String? ?? 'BASIC';
          final hasBase = data['hasBaseMembership'] as bool? ?? false;
          final baseEndTs = data['baseMembershipEndDate'] as cloud_firestore.Timestamp?;
          final baseEndDate = baseEndTs?.toDate();
          final baseActive = hasBase && baseEndDate != null && baseEndDate.isAfter(DateTime.now());
          setState(() {
            _currentTierName = tier;
            _currentEndDate = endDate?.toDate();
            _hasActiveBaseMembership = baseActive;
          });
        }
      } catch (e) {
        debugPrint('Error loading membership: $e');
      }
    }
  }

  /// Returns the tier rank for the user's current active membership.
  /// Returns -1 if no active membership (expired or none).
  int _currentTierRank() {
    if (_currentTierName == null) return -1;
    // Only count as active if end date is in the future
    final isActive = _currentEndDate != null && _currentEndDate!.isAfter(DateTime.now());
    if (!isActive) return -1;
    return _tierRankFromName(_currentTierName!);
  }

  int _tierRankFromName(String tierName) {
    switch (tierName.toUpperCase()) {
      case 'PLATINUM':
        return 3;
      case 'GOLD':
        return 2;
      case 'SILVER':
        return 1;
      case 'BASIC':
        return 0;
      default:
        return -1;
    }
  }

  int _tierRankFromProductId(String productId) {
    switch (ProductCatalog.classify(productId).tier) {
      case MembershipProductTier.platinum:
        return 3;
      case MembershipProductTier.gold:
        return 2;
      case MembershipProductTier.silver:
        return 1;
      case MembershipProductTier.base:
        return 0;
    }
  }

  bool _isBaseProduct(String productId) =>
      ProductCatalog.classify(productId).isBase;

  /// Returns true if the product should be locked (not selectable).
  /// Locked when: active base membership being re-purchased, or tier <= current active tier.
  bool _isLowerThanCurrentTier(String productId) {
    // Block re-purchasing active base membership
    if (_isBaseProduct(productId)) return _hasActiveBaseMembership;
    final currentRank = _currentTierRank();
    if (currentRank <= 0) return false; // No active premium tier, everything allowed
    final productRank = _tierRankFromProductId(productId);
    // Block same tier AND lower tiers (can only upgrade)
    return productRank <= currentRank;
  }

  /// SubscriptionBloc errors carry developer text; show it as a friendly
  /// popup. A user cancellation stays a quiet info snackbar.
  void _showSubscriptionError(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    if (message == 'Purchase cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentCancelledMessage)),
      );
      return;
    }
    if (message.startsWith('You already have a')) {
      showUserErrorMessage(context, l10n.userErrorNotAllowed);
      return;
    }
    // Known SubscriptionBloc codes (developer English) -> localized text.
    final known = switch (message) {
      'Store not available' => l10n.shopStoreNotAvailable,
      'No products available' => l10n.shopTemporarilyUnavailable,
      'Purchase failed to initiate' => l10n.shopFailedToInitiate,
      _ => null,
    };
    if (known != null) {
      showUserErrorMessage(context, known);
      return;
    }
    showUserError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.membershipBuyTitle),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD4AF37),
        elevation: 0,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPurchased) {
            // Show success dialog with new end date
            final endDate =
                state.endDate ?? DateTime.now().add(const Duration(days: 30));
            // Update local state to show new end date immediately
            setState(() {
              _currentTierName = state.tier.name.toUpperCase();
              _currentEndDate = endDate;
            });
            PurchaseSuccessDialog.showMembershipActivated(
              context,
              tierName: localizedSubscriptionTierName(
                  AppLocalizations.of(context)!, state.tier),
              endDate: endDate,
              coinsGranted: state.coinsGranted,
              onDismiss: () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          } else if (state is SubscriptionError) {
            _showSubscriptionError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is SubscriptionLoading;
          if (state is ProductsLoaded) _products = state.products;
          // One card per product id: Play returns one entry per offer.
          final products = ProductCatalog.onePerProduct(_products);
          final productsLoading = state is ProductsLoading && products.isEmpty;

          // Group products by period via the shared ProductCatalog
          // classifier (store IDs differ per platform: iOS
          // `subscription_1_month_silver`, Play `silver_premium_monthly`).
          // Only the known base product gets the base slot; every other
          // product (including unknown IDs) lands in a period group, so
          // nothing the store returns silently disappears.
          ProductDetails? baseProduct;
          final monthlyProducts = <ProductDetails>[];
          final yearlyProducts = <ProductDetails>[];
          for (final p in products) {
            final info = ProductCatalog.classify(p.id);
            if (info.isBase && info.isKnown && baseProduct == null) {
              baseProduct = p;
            } else if (info.isYearly) {
              yearlyProducts.add(p);
            } else {
              monthlyProducts.add(p);
            }
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Current Membership Status
                      if (_currentTierName != null)
                        _buildCurrentMembershipStatus(),

                      const SizedBox(height: 24),

                      // Header
                      Text(
                        AppLocalizations.of(context)!.membershipExtendTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.membershipSubtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      if (productsLoading) _buildProductsPlaceholder(),

                      // Base Membership
                      if (baseProduct != null)
                        _buildProductCard(
                          product: baseProduct,
                          duration: AppLocalizations.of(context)!.membershipPermanent,
                          isSelected: _selectedProduct?.id == baseProduct.id,
                          onSelect: () =>
                              setState(() => _selectedProduct = baseProduct),
                        ),

                      const SizedBox(height: 24),

                      // Monthly Memberships
                      if (monthlyProducts.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context)!.membershipMonthly,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...monthlyProducts.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProductCard(
                                product: product,
                                duration: AppLocalizations.of(context)!.membershipOneMonth,
                                isSelected:
                                    _selectedProduct?.id == product.id,
                                onSelect: () =>
                                    setState(() => _selectedProduct = product),
                              ),
                            )),
                      ],

                      const SizedBox(height: 24),

                      // Yearly Memberships (Save XX%)
                      if (yearlyProducts.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context)!.membershipYearly(SubscriptionTier.platinum.yearlySavingsPercent.toStringAsFixed(0)),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.membershipBestValue,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...yearlyProducts.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProductCard(
                                product: product,
                                duration: AppLocalizations.of(context)!.membershipOneYear,
                                isSelected:
                                    _selectedProduct?.id == product.id,
                                onSelect: () =>
                                    setState(() => _selectedProduct = product),
                                isYearly: true,
                              ),
                            )),
                      ],

                      const SizedBox(height: 32),

                      // Purchase Button
                      if (_selectedProduct != null)
                        ElevatedButton(
                          onPressed: state is! SubscriptionLoading
                              ? () =>
                                  _handlePurchase(context, _selectedProduct!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '${AppLocalizations.of(context)!.membershipBuyProductPrice(_selectedProduct!.title, _displayPrice(_selectedProduct!))}  ${AppLocalizations.of(context)!.plusTaxes}', // i18n-ignore: composed of localized parts
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Terms
                      Text(
                        AppLocalizations.of(context)!.membershipTermsExtended,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Feature Comparison
                      _buildFeatureComparison(),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Placeholder cards while the store is queried: the page renders at once
  /// (no full-screen overlay) and no price is shown until the store's own.
  Widget _buildProductsPlaceholder() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 92,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMembershipStatus() {
    final isActive =
        _currentEndDate != null && _currentEndDate!.isAfter(DateTime.now());
    final daysRemaining = isActive
        ? _currentEndDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.membershipCurrent,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedStoredTierName(AppLocalizations.of(context)!, _currentTierName),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.membershipDaysRemaining(daysRemaining.toString()),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.membershipExpires('${_currentEndDate!.day}/${_currentEndDate!.month}/${_currentEndDate!.year}'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ] else
            Text(
              AppLocalizations.of(context)!.membershipNoActive,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required ProductDetails product,
    required String duration,
    required bool isSelected,
    required VoidCallback onSelect,
    bool isYearly = false,
  }) {
    final tierName = _getTierDisplayName(product.id);
    final color = _getTierColor(product.id);
    final isLocked = _isLowerThanCurrentTier(product.id);

    return GestureDetector(
      onTap: isLocked ? null : onSelect,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected && !isLocked ? color.withOpacity(0.1) : Colors.grey[900],
            border: Border.all(
              color: isSelected && !isLocked ? color : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tierName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _isBaseProduct(product.id)
                                  ? AppLocalizations.of(context)!.membershipActive
                                  : (_tierRankFromProductId(product.id) == _currentTierRank()
                                      ? AppLocalizations.of(context)!.membershipActive
                                      : AppLocalizations.of(context)!.membershipYouHaveTier(
                                          localizedStoredTierName(AppLocalizations.of(context)!, _currentTierName))),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (!isLocked && isYearly) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.membershipSavePercent(_getTierFromProductId(product.id).yearlySavingsPercent.toStringAsFixed(0)),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        if (_isBaseProduct(product.id)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.membershipPlus500Coins,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked ? AppLocalizations.of(context)!.membershipLowerThanCurrent : duration,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLocked ? Colors.red[300] : Colors.white54,
                      ),
                    ),
                    if (!isLocked && isYearly) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_getTierFromProductId(product.id).yearlyMonthlyEquivalent.toStringAsFixed(2)}${AppLocalizations.of(context)!.perMonth}', // i18n-ignore: price + localized suffix
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isLocked && isYearly) ...[
                    Text(
                      '\$${(_getTierFromProductId(product.id).monthlyPrice * 12).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ],
                  Text(
                    '${_displayPrice(product)}  ${AppLocalizations.of(context)!.plusTaxes}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (ProductCatalog.hasSevenDayFreeTrial(product)) ...[
                    const SizedBox(height: 4),
                    // Bounded: this Column is a non-flex Row child.
                    SizedBox(
                      width: 150,
                      child: Text(
                        AppLocalizations.of(context)!.subscriptionFreeTrialInfo,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                isLocked
                    ? Icons.lock
                    : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
                color: isLocked ? Colors.red[300] : (isSelected ? color : Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.membershipFeatureComparison,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 16),
          // Phase 3.2: real per-tier entitlements (Free / Silver / Gold columns).
          _buildComparisonRow(AppLocalizations.of(context)!.shopEventsCreate, '1', '3', '5'),
          _buildComparisonRow(AppLocalizations.of(context)!.shopGroupsCreate, '1', AppLocalizations.of(context)!.shopUnlimited, AppLocalizations.of(context)!.shopUnlimited),
          _buildComparisonRow(AppLocalizations.of(context)!.shopDailyConnects, '10', '50', '200'),
          _buildComparisonRow(AppLocalizations.of(context)!.shopMonthlyBoosts, '0', '1', '4'),
          _buildComparisonRow(
            AppLocalizations.of(context)!.shopMonthlyCoins,
            '${TierEntitlements.monthlyCoins(MembershipTier.free)}',
            '${TierEntitlements.monthlyCoins(MembershipTier.silver)}',
            '${TierEntitlements.monthlyCoins(MembershipTier.gold)}',
          ),
          _buildComparisonRow(AppLocalizations.of(context)!.shopSeeWhoConnected, '✗', '✗', '✓'),
          _buildComparisonRow(AppLocalizations.of(context)!.shopTravelMode, '✗', '✓', '✓'),
          _buildComparisonRow(AppLocalizations.of(context)!.membershipPrioritySupport, '✗', '✗', '✓'),
          _buildComparisonRow(AppLocalizations.of(context)!.shopNoAds, '✗', '✓', '✓'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String basic,
    String silver,
    String gold,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              basic,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              silver,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              gold,
              style: const TextStyle(color: Color(0xFFD4AF37)),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context, ProductDetails product) {
    final tier = _getTierFromProductId(product.id);
    context.read<SubscriptionBloc>().add(
          PurchaseSubscription(
            product: product,
            tier: tier,
          ),
        );
  }

  String _getTierDisplayName(String productId) {
    final l10n = AppLocalizations.of(context)!;
    final info = ProductCatalog.classify(productId);
    switch (info.tier) {
      case MembershipProductTier.platinum:
        return l10n.membershipPlatinum;
      case MembershipProductTier.gold:
        return l10n.membershipGold;
      case MembershipProductTier.silver:
        return l10n.membershipSilver;
      case MembershipProductTier.base:
        return info.isKnown
            ? l10n.membershipBaseMembership
            : l10n.membershipGeneric;
    }
  }

  Color _getTierColor(String productId) {
    switch (ProductCatalog.classify(productId).tier) {
      case MembershipProductTier.platinum:
        return AppColors.platinumBlue;
      case MembershipProductTier.gold:
        return const Color(0xFFD4AF37);
      case MembershipProductTier.silver:
        return Colors.grey[400]!;
      case MembershipProductTier.base:
        return AppColors.basePurple;
    }
  }

  /// Plan price to display: the store's RECURRING price. On Android
  /// `ProductDetails.price` is the first pricing phase, i.e. "Free" or an
  /// intro price for a trial offer. Display only — purchases still use the
  /// selected [ProductDetails] untouched.
  String _displayPrice(ProductDetails product) =>
      ProductCatalog.recurringPriceLabel(product) ?? product.price;

  SubscriptionTier _getTierFromProductId(String productId) =>
      subscriptionTierForProduct(productId);
}
