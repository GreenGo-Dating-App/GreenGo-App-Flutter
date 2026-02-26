import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../domain/entities/subscription.dart';
import '../bloc/subscription_bloc.dart';

/// Membership Selection Screen
/// One-time purchases for membership periods (1 month or 1 year)
class MembershipSelectionScreen extends StatefulWidget {
  final String? currentUserId;

  const MembershipSelectionScreen({Key? key, this.currentUserId})
      : super(key: key);

  @override
  State<MembershipSelectionScreen> createState() =>
      _MembershipSelectionScreenState();
}

class _MembershipSelectionScreenState extends State<MembershipSelectionScreen> {
  ProductDetails? _selectedProduct;
  String? _currentTierName;
  DateTime? _currentEndDate;

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
          setState(() {
            _currentTierName = tier;
            _currentEndDate = endDate?.toDate();
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
    if (productId.contains('platinum')) return 3;
    if (productId.contains('gold')) return 2;
    if (productId.contains('silver')) return 1;
    return 0;
  }

  /// Returns true if the product's tier is lower than the user's current active tier.
  bool _isLowerThanCurrentTier(String productId) {
    if (productId == 'greengo_base_membership') return false; // Base is always purchasable
    final currentRank = _currentTierRank();
    if (currentRank <= 0) return false; // No active premium tier, everything allowed
    final productRank = _tierRankFromProductId(productId);
    return productRank < currentRank;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Buy Membership'),
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
          final products =
              state is ProductsLoaded ? state.products : <ProductDetails>[];

          // Group products by tier
          final monthlyProducts =
              products.where((p) => p.id.contains('1_month')).toList();
          final yearlyProducts =
              products.where((p) => p.id.contains('1_year')).toList();
          final baseProducts =
              products.where((p) => p.id == 'greengo_base_membership').toList();
          final baseProduct = baseProducts.isNotEmpty ? baseProducts.first : null;

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
                      const Text(
                        'Extend Your Membership',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
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

                      // Base Membership
                      if (baseProduct != null)
                        _buildProductCard(
                          product: baseProduct,
                          duration: 'Permanent',
                          isSelected: _selectedProduct?.id == baseProduct.id,
                          onSelect: () =>
                              setState(() => _selectedProduct = baseProduct),
                        ),

                      const SizedBox(height: 24),

                      // Monthly Memberships
                      if (monthlyProducts.isNotEmpty) ...[
                        const Text(
                          'Monthly Memberships',
                          style: TextStyle(
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
                                duration: '1 month',
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
                          'Yearly Memberships (Save up to ${SubscriptionTier.platinum.yearlySavingsPercent.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const Text(
                          'Best value for long-term commitment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...yearlyProducts.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProductCard(
                                product: product,
                                duration: '1 year',
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
                            'Buy ${_selectedProduct!.title} - ${_selectedProduct!.price}  ${AppLocalizations.of(context)!.plusTaxes}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Terms
                      Text(
                        'One-time purchase. Membership will be extended from your current end date. Higher tier purchases override lower tiers.',
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
          const Text(
            'Current Membership',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTierName ?? 'BASIC',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(
              '$daysRemaining days remaining',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            Text(
              'Expires: ${_currentEndDate!.day}/${_currentEndDate!.month}/${_currentEndDate!.year}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ] else
            const Text(
              'No active membership',
              style: TextStyle(
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
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'You have ${_currentTierName!}',
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
                              'SAVE ${_getTierFromProductId(product.id).yearlySavingsPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        if (product.id == 'greengo_base_membership') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '+500 COINS',
                              style: TextStyle(
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
                      isLocked ? 'Lower than your current tier' : duration,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLocked ? Colors.red[300] : Colors.white54,
                      ),
                    ),
                    if (!isLocked && isYearly) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_getTierFromProductId(product.id).yearlyMonthlyEquivalent.toStringAsFixed(2)}/month',
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ],
                  Text(
                    '${product.price}  ${AppLocalizations.of(context)!.plusTaxes}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
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
          const Text(
            'Feature Comparison',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Daily Likes', '10', '100', 'Unlimited'),
          _buildComparisonRow('Super Likes', '1', '5', '10'),
          _buildComparisonRow('Rewinds', '0', '5', 'Unlimited'),
          _buildComparisonRow('Boosts/month', '0', '1', '3'),
          _buildComparisonRow('See Who Likes You', '✗', '✓', '✓'),
          _buildComparisonRow('Advanced Filters', '✗', '✓', '✓'),
          _buildComparisonRow('Read Receipts', '✗', '✓', '✓'),
          _buildComparisonRow('Incognito Mode', '✗', '✗', '✓'),
          _buildComparisonRow('Priority Support', '✗', '✗', '✓'),
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
    if (productId.contains('platinum')) return 'Platinum';
    if (productId.contains('gold')) return 'Gold';
    if (productId.contains('silver')) return 'Silver';
    if (productId == 'greengo_base_membership') return 'Base Membership';
    return 'Membership';
  }

  Color _getTierColor(String productId) {
    if (productId.contains('platinum')) return AppColors.platinumBlue;
    if (productId.contains('gold')) return const Color(0xFFD4AF37);
    if (productId.contains('silver')) return Colors.grey[400]!;
    if (productId.contains('base')) return AppColors.basePurple;
    return AppColors.basePurple;
  }

  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('platinum')) return SubscriptionTier.platinum;
    if (productId.contains('gold')) return SubscriptionTier.gold;
    if (productId.contains('silver')) return SubscriptionTier.silver;
    return SubscriptionTier.basic;
  }
}
