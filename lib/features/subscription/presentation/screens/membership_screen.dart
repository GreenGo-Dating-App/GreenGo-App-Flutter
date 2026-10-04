import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/product_catalog.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/membership_product_mapping.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/subscription_bloc.dart';

/// Membership Selection Screen
/// One-time purchases for membership periods (1 month or 1 year)
///
/// Supplies its own [SubscriptionBloc]. The view reads the bloc from context in
/// initState, so every caller had to remember to wrap this screen in a
/// BlocProvider — and most did not. BaseMembershipGate pushes it raw when a
/// user without a valid membership taps a conversation, which threw
/// ProviderNotFoundException and left a blank screen where the chat should be.
/// Owning the bloc here makes every call site correct by construction.
class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key, this.currentUserId});
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (_) => di.sl<SubscriptionBloc>(),
      child: _MembershipScreenView(currentUserId: currentUserId),
    );
  }
}

class _MembershipScreenView extends StatefulWidget {
  const _MembershipScreenView({this.currentUserId});
  final String? currentUserId;

  @override
  State<_MembershipScreenView> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<_MembershipScreenView> {
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
          final endDate = data['membershipEndDate'] as cloud_firestore.Timestamp?;
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

  bool _isProductLocked(String productId) {
    if (ProductCatalog.classify(productId).isBase) return _hasActiveBaseMembership;
    if (_currentTierName == null || _currentEndDate == null) return false;
    final isActive = _currentEndDate!.isAfter(DateTime.now());
    if (!isActive) return false;
    final currentRank = _tierRankFromName(_currentTierName!);
    final productRank = _tierRankFromProductId(productId);
    return productRank <= currentRank;
  }

  int _tierRankFromName(String tierName) {
    switch (tierName.toUpperCase()) {
      case 'PLATINUM': return 3;
      case 'GOLD': return 2;
      case 'SILVER': return 1;
      default: return 0;
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

  /// Get tier-specific accent color based on product ID
  Color _getTierColor(String productId) {
    switch (ProductCatalog.classify(productId).tier) {
      case MembershipProductTier.platinum:
        return AppColors.platinumBlue;
      case MembershipProductTier.gold:
        return AppColors.richGold;
      case MembershipProductTier.silver:
        return const Color(0xFFC0C0C0);
      case MembershipProductTier.base:
        return AppColors.basePurple; // Base membership
    }
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
    showUserError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.membershipBuyTitle),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.richGold,
        elevation: 0,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPurchased) {
            // Show success dialog with real end date
            final endDate = state.endDate ?? DateTime.now().add(const Duration(days: 30));
            PurchaseSuccessDialog.showMembershipActivated(
              context,
              tierName: state.tier.displayName,
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

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        AppLocalizations.of(context)!.membershipExtendTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.richGold,
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

                      // Product List
                      if (productsLoading) _buildProductsPlaceholder(),
                      if (products.isNotEmpty)
                        ...products.map((product) {
                          final isLocked = _isProductLocked(product.id);
                          return _buildProductCard(
                            product: product,
                            isSelected: _selectedProduct?.id == product.id,
                            isLocked: isLocked,
                            onSelect: isLocked ? () {} : () => setState(() => _selectedProduct = product),
                          );
                        }),

                      const SizedBox(height: 32),

                      // Purchase Button
                      if (_selectedProduct != null)
                        ElevatedButton(
                          onPressed: state is! SubscriptionLoading
                              ? () => _handlePurchase(context, _selectedProduct!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getTierColor(_selectedProduct!.id),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Buy ${_selectedProduct!.title} - ${_displayPrice(_selectedProduct!)}  ${AppLocalizations.of(context)!.plusTaxes}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Terms
                      Text(
                        AppLocalizations.of(context)!.membershipTerms,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
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

  Widget _buildProductCard({
    required ProductDetails product,
    required bool isSelected,
    required VoidCallback onSelect,
    bool isLocked = false,
  }) {
    // Shared classifier: Play IDs (e.g. `greengo_silver_yearly`) don't
    // contain `1_year`, so substring checks mislabelled them as monthly.
    final info = ProductCatalog.classify(product.id);
    final isBase = info.isBase;
    final isYearly = info.isYearly && !isBase;
    final tierColor = _getTierColor(product.id);

    final l10n = AppLocalizations.of(context)!;
    final String tierName;
    switch (info.tier) {
      case MembershipProductTier.platinum:
        tierName = l10n.membershipPlatinum;
      case MembershipProductTier.gold:
        tierName = l10n.membershipGold;
      case MembershipProductTier.silver:
        tierName = l10n.membershipSilver;
      case MembershipProductTier.base:
        tierName = l10n.membershipGreenGoBase;
    }

    var duration = l10n.membershipOneMonth;
    if (isYearly) duration = l10n.membershipOneYear;
    if (isBase) duration = l10n.membershipBase;

    return GestureDetector(
      onTap: isLocked ? null : onSelect,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[900] : Colors.grey[850],
          border: Border.all(
            color: isSelected ? tierColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.membershipTierName(tierName),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? tierColor : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.membershipActive,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isYearly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.membershipSavePercent(_getTierFromProductId(product.id).yearlySavingsPercent.toStringAsFixed(0)),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isBase)
              // Highlighted price for the entry-level Base membership.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor, width: 2),
                ),
                child: Text(
                  '${_displayPrice(product)}  ${l10n.plusTaxes} / ${l10n.membershipOneYear}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                  ),
                ),
              )
            else
              Text(
                '${_displayPrice(product)}  ${AppLocalizations.of(context)!.plusTaxes}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
            if (ProductCatalog.hasSevenDayFreeTrial(product)) ...[
              const SizedBox(height: 6),
              Text(
                l10n.subscriptionFreeTrialInfo,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
            const SizedBox(height: 8),
            if (isYearly && _calculateMonthlyPrice(product) != null)
              Text(
                l10n.membershipEquivalentMonthly(_calculateMonthlyPrice(product)!),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  /// Monthly equivalent of a yearly product in the store's own currency, or
  /// null when the store gave no usable amount (the line is then hidden).
  /// Uses [ProductCatalog.recurringPrice] — parsing the formatted string broke on
  /// non-USD locales ("R$ 24,99" became "$0.00").
  String? _calculateMonthlyPrice(ProductDetails product) {
    // Recurring phase, not the first (possibly free-trial) phase.
    final recurring = ProductCatalog.recurringPrice(product);
    if (recurring == null) return null;
    return '${recurring.currencySymbol}'
        '${(recurring.amount / 12).toStringAsFixed(2)}';
  }

  /// Plan price to display: the store's RECURRING price. On Android
  /// `ProductDetails.price` is the first pricing phase, i.e. "Free" or an
  /// intro price for a trial offer. Display only — purchases still use the
  /// selected [ProductDetails] untouched.
  String _displayPrice(ProductDetails product) =>
      ProductCatalog.recurringPriceLabel(product) ?? product.price;

  SubscriptionTier _getTierFromProductId(String productId) =>
      subscriptionTierForProduct(productId);

  void _handlePurchase(BuildContext context, ProductDetails product) {
    // Determine tier from product ID (same result as before for every real
    // ID; see test/unit/subscription/product_catalog_classify_test.dart).
    final SubscriptionTier tier = subscriptionTierForProduct(product.id);

    context.read<SubscriptionBloc>().add(
      PurchaseSubscription(
        product: product,
        tier: tier,
      ),
    );
  }
}
