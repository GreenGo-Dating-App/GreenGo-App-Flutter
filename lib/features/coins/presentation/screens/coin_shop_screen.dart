import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../bloc/coin_bloc.dart';
import '../bloc/coin_event.dart';
import '../bloc/coin_state.dart';

/// Coin Shop Screen
/// Point 157: Coin purchase interface with packages
class CoinShopScreen extends StatefulWidget {
  final String userId;

  const CoinShopScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  CoinPackage? _selectedPackage;
  CoinPromotion? _activePromotion;

  @override
  void initState() {
    super.initState();
    context.read<CoinBloc>().add(const LoadAvailablePackages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('GreenGoCoins Shop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<CoinBloc, CoinState>(
        listener: (context, state) {
          if (state is CoinPackagePurchased) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.coinsAdded} coins added to your account!',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is CoinError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CoinLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CoinPackagesLoaded) {
            return _buildPackageList(state.packages, state.activePromotions);
          }

          return const Center(child: Text('Failed to load packages'));
        },
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
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GreenGoCoins',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock premium features and enhance your dating experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Active promotion banner
        if (promotions.isNotEmpty) _buildPromotionBanner(promotions.first),

        // Package list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              final isPopular = package.packageId == 'popular_500';
              return _buildPackageCard(package, isPopular, promotions);
            },
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
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Purchase ${_selectedPackage!.totalCoins} Coins for ${_selectedPackage!.displayPrice}',
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
    List<CoinPromotion> promotions,
  ) {
    final isSelected = _selectedPackage?.packageId == package.packageId;
    final promotion = promotions.firstWhere(
      (p) => p.isPackageApplicable(package.packageId),
      orElse: () => promotions.isNotEmpty ? promotions.first : CoinPromotions.firstPurchase,
    );

    final bonusCoins = promotion.calculateBonus(
      package.coinAmount,
      package.price,
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.transparent,
            width: 2,
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
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Package content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Gold coin icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Coin amount and bonus
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${package.coinAmount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (bonusCoins > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '+$bonusCoins',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            const Text(
                              'Coins',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (bonusCoins > 0)
                          Text(
                            '${promotion.displayText}!',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        package.displayPrice,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(package.coinsPerDollar).toStringAsFixed(0)} coins/\$',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase() {
    if (_selectedPackage == null) return;

    context.read<CoinBloc>().add(
          PurchaseCoinPackage(
            userId: widget.userId,
            package: _selectedPackage!,
            platform: Theme.of(context).platform == TargetPlatform.android
                ? 'android'
                : 'ios',
            promotion: _activePromotion,
          ),
        );
  }
}
