import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated purchase success dialog
/// Shown after successful coin or subscription purchase
class PurchaseSuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onDismiss;
  final Duration autoDismissDelay;

  const PurchaseSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle,
    this.iconColor = AppColors.successGreen,
    this.onDismiss,
    this.autoDismissDelay = const Duration(seconds: 3),
  });

  /// Show dialog for coin purchase success
  static Future<void> showCoinsPurchased(
    BuildContext context, {
    required int coinsAdded,
    int? bonusCoins,
    VoidCallback? onDismiss,
  }) {
    final totalCoins = coinsAdded + (bonusCoins ?? 0);
    final bonusText = bonusCoins != null && bonusCoins > 0
        ? ' (+$bonusCoins bonus!)'
        : '';

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PurchaseSuccessDialog(
        title: 'Purchase Successful!',
        message: '$totalCoins coins added to your account$bonusText',
        icon: Icons.monetization_on,
        iconColor: AppColors.richGold,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Show dialog for subscription purchase success
  static Future<void> showSubscriptionActivated(
    BuildContext context, {
    required String tierName,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PurchaseSuccessDialog(
        title: 'Welcome to $tierName!',
        message: 'Your premium membership is now active. Enjoy all your new features!',
        icon: Icons.workspace_premium,
        iconColor: AppColors.richGold,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<PurchaseSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeIn,
    );

    _scaleController.forward();
    _confettiController.forward();

    // Auto-dismiss after delay
    Future.delayed(widget.autoDismissDelay, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.iconColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.iconColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated confetti/sparkle effect
                AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sparkles
                        ..._buildSparkles(),
                        // Main icon with glow
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.iconColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: widget.iconColor.withOpacity(0.3),
                                blurRadius: 20 * _confettiController.value,
                                spreadRadius: 5 * _confettiController.value,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: 50,
                            color: widget.iconColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final sparkles = <Widget>[];
    const sparklePositions = [
      Offset(-40, -30),
      Offset(40, -25),
      Offset(-35, 25),
      Offset(45, 30),
      Offset(0, -45),
      Offset(-50, 0),
      Offset(50, 0),
      Offset(0, 45),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final delay = i * 0.1;
      final value = (_confettiController.value - delay).clamp(0.0, 1.0);
      final opacity = value > 0.5 ? (1 - value) * 2 : value * 2;

      sparkles.add(
        Transform.translate(
          offset: sparklePositions[i] * value,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Icon(
              Icons.star,
              size: 12 + (value * 8),
              color: widget.iconColor,
            ),
          ),
        ),
      );
    }

    return sparkles;
  }
}
