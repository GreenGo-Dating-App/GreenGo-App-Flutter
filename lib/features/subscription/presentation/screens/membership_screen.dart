import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../domain/entities/subscription.dart';
import '../bloc/subscription_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;

/// Membership Selection Screen
/// One-time purchases for membership periods (1 month or 1 year)
class MembershipScreen extends StatefulWidget {
  final String? currentUserId;

  const MembershipScreen({Key? key, this.currentUserId}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  ProductDetails? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Load available products
    context.read<SubscriptionBloc>().add(const LoadAvailableProducts());
  }

  /// Get subscription tier from product ID
  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('platinum')) return SubscriptionTier.platinum;
    if (productId.contains('gold')) return SubscriptionTier.gold;
    if (productId.contains('silver')) return SubscriptionTier.silver;
    return SubscriptionTier.basic;
  }

  /// Get tier-specific accent color based on product ID
  Color _getTierColor(String productId) {
    if (productId.contains('platinum')) return AppColors.platinumBlue;
    if (productId.contains('gold')) return AppColors.richGold;
    if (productId.contains('silver')) return const Color(0xFFC0C0C0);
    return AppColors.basePurple; // Base membership
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Buy Membership'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SubscriptionLoading;
          final products = state is ProductsLoaded ? state.products : [];

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const Text(
                        'Extend Your Membership',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.richGold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Buy once, enjoy premium features for 1 month or 1 year',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Product List
                      if (products.isNotEmpty)
                        ...products.map((product) => _buildProductCard(
                          product: product,
                          isSelected: _selectedProduct?.id == product.id,
                          onSelect: () => setState(() => _selectedProduct = product),
                        )),

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
                            'Buy ${_selectedProduct!.title} - ${_selectedProduct!.price}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Terms
                      Text(
                        'One-time purchase. Membership will be extended from your current end date.',
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

  Widget _buildProductCard({
    required ProductDetails product,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final isYearly = product.id.contains('1_year');
    final isBase = product.id.contains('base');
    final tierColor = _getTierColor(product.id);

    String tierName = 'GreenGo Base';
    if (product.id.contains('platinum')) tierName = 'Platinum';
    else if (product.id.contains('gold')) tierName = 'Gold';
    else if (product.id.contains('silver')) tierName = 'Silver';

    String duration = '1 month';
    if (isYearly) duration = '1 year';
    if (isBase) duration = 'Base';

    return GestureDetector(
      onTap: onSelect,
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
                      '$tierName Membership',
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
                if (isYearly)
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
                      'SAVE ${_getTierFromProductId(product.id).yearlySavingsPercent.toStringAsFixed(0)}%',
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
            Text(
              product.price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tierColor,
              ),
            ),
            const SizedBox(height: 8),
            if (isYearly)
              Text(
                'Equivalent to ${_calculateMonthlyPrice(product)}/month',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _calculateMonthlyPrice(ProductDetails product) {
    try {
      // Extract price from string like "\$119.99"
      final priceStr = product.price.replaceAll(r'$', '').replaceAll(',', '');
      final price = double.tryParse(priceStr) ?? 0;
      final monthlyPrice = price / 12;
      return '\$${monthlyPrice.toStringAsFixed(2)}';
    } catch (e) {
      return product.price;
    }
  }

  void _handlePurchase(BuildContext context, ProductDetails product) {
    // Determine tier from product ID
    SubscriptionTier tier;
    if (product.id.contains('platinum')) {
      tier = SubscriptionTier.platinum;
    } else if (product.id.contains('gold')) {
      tier = SubscriptionTier.gold;
    } else if (product.id.contains('silver')) {
      tier = SubscriptionTier.silver;
    } else {
      tier = SubscriptionTier.basic;
    }

    context.read<SubscriptionBloc>().add(
      PurchaseSubscription(
        product: product,
        tier: tier,
      ),
    );
  }
}
