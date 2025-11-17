import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/coin_balance.dart';
import '../bloc/coin_bloc.dart';
import '../bloc/coin_event.dart';
import '../bloc/coin_state.dart';
import '../screens/coin_shop_screen.dart';

/// Coin Balance Widget
/// Point 158: Animated gold coin icon in navigation bar
class CoinBalanceWidget extends StatefulWidget {
  final String userId;
  final bool compact;

  const CoinBalanceWidget({
    Key? key,
    required this.userId,
    this.compact = false,
  }) : super(key: key);

  @override
  State<CoinBalanceWidget> createState() => _CoinBalanceWidgetState();
}

class _CoinBalanceWidgetState extends State<CoinBalanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  int _previousBalance = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Subscribe to balance updates
    context.read<CoinBloc>().add(SubscribeToCoinBalance(widget.userId));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBalanceUpdated(int newBalance) {
    if (newBalance != _previousBalance && _previousBalance > 0) {
      _animationController.forward(from: 0.0);
    }
    _previousBalance = newBalance;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinBloc, CoinState>(
      builder: (context, state) {
        if (state is CoinBalanceLoaded) {
          _onBalanceUpdated(state.balance.availableCoins);
          return _buildBalance(state.balance);
        }

        if (state is CoinBalanceUpdated) {
          _onBalanceUpdated(state.balance.availableCoins);
          return _buildBalance(state.balance);
        }

        // Default/loading state
        return _buildBalance(null);
      },
    );
  }

  Widget _buildBalance(CoinBalance? balance) {
    if (widget.compact) {
      return _buildCompactBalance(balance);
    }
    return _buildFullBalance(balance);
  }

  Widget _buildCompactBalance(CoinBalance? balance) {
    return GestureDetector(
      onTap: () => _navigateToShop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159,
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              balance != null
                  ? _formatBalance(balance.availableCoins)
                  : '---',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullBalance(CoinBalance? balance) {
    return GestureDetector(
      onTap: () => _navigateToShop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated gold coin
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Balance info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GreenGoCoins',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      balance != null
                          ? _formatBalance(balance.availableCoins)
                          : '---',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ],
            ),

            // Expiration warning (if applicable)
            if (balance != null && balance.getCoinsExpiringSoon() > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balance.getCoinsExpiringSoon()} expiring',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBalance(int balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return balance.toString();
  }

  void _navigateToShop() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CoinBloc>(),
          child: CoinShopScreen(userId: widget.userId),
        ),
      ),
    );
  }
}

/// Floating Coin Animation
/// Shows animated coins when balance increases
class FloatingCoinAnimation extends StatefulWidget {
  final int coinsAdded;
  final VoidCallback onComplete;

  const FloatingCoinAnimation({
    Key? key,
    required this.coinsAdded,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FloatingCoinAnimation> createState() => _FloatingCoinAnimationState();
}

class _FloatingCoinAnimationState extends State<FloatingCoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.coinsAdded}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
