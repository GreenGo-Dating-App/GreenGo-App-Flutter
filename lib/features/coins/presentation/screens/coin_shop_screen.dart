import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
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
    super.key,
    required this.userId,
  });

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CoinPackage? _selectedPackage;
  CoinPromotion? _activePromotion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CoinBloc>().add(const LoadAvailablePackages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), AppColors.richGold],
          ).createShader(bounds),
          child: const Text(
            'Shop',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyCoinsTab(),
          _buildVideoCoinsTab(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), AppColors.richGold],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🪙', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('Buy Coins'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎬', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('Video-Coins'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyCoinsTab() {
    return BlocConsumer<CoinBloc, CoinState>(
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

        return const Center(
          child: Text(
            'Failed to load packages',
            style: TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }

  Widget _buildVideoCoinsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Video icon with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.richGold.withValues(alpha: 0.3),
                  AppColors.richGold.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎬',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Coming Soon text with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), AppColors.richGold],
            ).createShader(bounds),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Watch short videos to earn free coins!\nStay tuned for this exciting feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Glass notification card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppColors.richGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Notified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'We\'ll let you know when Video-Coins is available',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🪙',
                    style: TextStyle(fontSize: 40),
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
                  color: Colors.black.withValues(alpha: 0.3),
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
      orElse: () =>
          promotions.isNotEmpty ? promotions.first : CoinPromotions.firstPurchase,
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
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🪙',
                        style: TextStyle(fontSize: 28),
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
