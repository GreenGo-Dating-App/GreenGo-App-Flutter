import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../domain/entities/subscription.dart';
import '../bloc/subscription_bloc.dart';

/// Subscription Selection Screen
/// Point 149: Build subscription selection with gold-highlighted premium features
class SubscriptionSelectionScreen extends StatefulWidget {
  const SubscriptionSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.gold;

  @override
  void initState() {
    super.initState();
    // Load available products
    context.read<SubscriptionBloc>().add(const LoadAvailableProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD4AF37),
        elevation: 0,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPurchased) {
            // Show success dialog before closing
            PurchaseSuccessDialog.showSubscriptionActivated(
              context,
              tierName: state.tier.displayName,
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
                    'Unlock Premium Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find your perfect match faster with premium',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Subscription Cards
                  _buildTierCard(
                    tier: SubscriptionTier.basic,
                    isSelected: _selectedTier == SubscriptionTier.basic,
                    state: state,
                  ),
                  const SizedBox(height: 16),
                  _buildTierCard(
                    tier: SubscriptionTier.silver,
                    isSelected: _selectedTier == SubscriptionTier.silver,
                    state: state,
                    badge: 'POPULAR',
                  ),
                  const SizedBox(height: 16),
                  _buildTierCard(
                    tier: SubscriptionTier.gold,
                    isSelected: _selectedTier == SubscriptionTier.gold,
                    state: state,
                    badge: 'BEST VALUE',
                    isGoldHighlighted: true,
                  ),
                  const SizedBox(height: 32),

                  // Feature Comparison
                  _buildFeatureComparison(),
                  const SizedBox(height: 32),

                  // Subscribe Button
                  if (_selectedTier != SubscriptionTier.basic)
                    ElevatedButton(
                      onPressed: state is! SubscriptionLoading
                          ? () => _handlePurchase(context, state)
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
                        'Subscribe to ${_selectedTier.displayName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Terms
                  Text(
                    'Subscriptions automatically renew unless cancelled 24 hours before the end of the current period. Manage in your account settings.',
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTierCard({
    required SubscriptionTier tier,
    required bool isSelected,
    required SubscriptionState state,
    String? badge,
    bool isGoldHighlighted = false,
  }) {
    final features = tier.features;
    final color = isGoldHighlighted ? const Color(0xFFD4AF37) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isGoldHighlighted ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.grey[900])
              : Colors.grey[850],
          border: Border.all(
            color: isSelected
                ? (isGoldHighlighted ? const Color(0xFFD4AF37) : Colors.white)
                : Colors.transparent,
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
                      tier.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier == SubscriptionTier.basic
                          ? 'Free Forever'
                          : '\$${tier.monthlyPrice.toStringAsFixed(2)}/month',
                      style: TextStyle(
                        fontSize: 18,
                        color: isGoldHighlighted
                            ? const Color(0xFFD4AF37)
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
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
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            ...tier.features.entries.where((e) => e.value is bool && e.value == true || e.value is int && e.value > 0).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isGoldHighlighted
                          ? const Color(0xFFD4AF37)
                          : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFeatureDescription(entry.key, entry.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
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

  String _getFeatureDescription(String key, dynamic value) {
    switch (key) {
      case 'dailyLikes':
        return value == -1 ? 'Unlimited Daily Likes' : '$value Daily Likes';
      case 'superLikes':
        return '$value Super Likes per day';
      case 'rewinds':
        return value == -1 ? 'Unlimited Rewinds' : '$value Rewinds per day';
      case 'boosts':
        return '$value Profile Boost per month';
      case 'seeWhoLikesYou':
        return 'See Who Likes You';
      case 'unlimitedLikes':
        return 'Unlimited Likes';
      case 'advancedFilters':
        return 'Advanced Search Filters';
      case 'readReceipts':
        return 'Read Receipts';
      case 'prioritySupport':
        return 'Priority Customer Support';
      case 'profileBoost':
        return 'Profile Visibility Boost';
      case 'incognitoMode':
        return 'Incognito Browsing Mode';
      default:
        return key;
    }
  }

  void _handlePurchase(BuildContext context, SubscriptionState state) {
    if (state is ProductsLoaded) {
      final product = state.products.firstWhere(
        (p) => p.id == _selectedTier.productId,
        orElse: () => throw Exception('Product not found'),
      );

      context.read<SubscriptionBloc>().add(
            PurchaseSubscription(
              product: product,
              tier: _selectedTier,
            ),
          );
    }
  }
}
