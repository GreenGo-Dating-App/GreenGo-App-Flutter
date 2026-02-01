import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/user_level.dart';

/// Level-up celebration dialog with Lottie confetti animation
/// Shows when user reaches a new level with multilingual support
class LevelUpCelebrationDialog extends StatefulWidget {
  final int newLevel;
  final int previousLevel;
  final List<LevelReward> rewards;
  final bool isVIP;
  final VoidCallback? onDismiss;

  const LevelUpCelebrationDialog({
    super.key,
    required this.newLevel,
    required this.previousLevel,
    this.rewards = const [],
    this.isVIP = false,
    this.onDismiss,
  });

  /// Show the level-up celebration dialog
  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required int previousLevel,
    List<LevelReward> rewards = const [],
    bool isVIP = false,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => LevelUpCelebrationDialog(
        newLevel: newLevel,
        previousLevel: previousLevel,
        rewards: rewards,
        isVIP: isVIP,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<LevelUpCelebrationDialog> createState() =>
      _LevelUpCelebrationDialogState();
}

class _LevelUpCelebrationDialogState extends State<LevelUpCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVIPUnlock = widget.newLevel >= 50 && widget.previousLevel < 50;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti animation
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                fit: BoxFit.cover,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if Lottie asset not found
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Main dialog content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.isVIP || isVIPUnlock
                      ? [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ]
                      : [
                          AppColors.backgroundCard,
                          AppColors.backgroundDark,
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isVIP || isVIPUnlock
                      ? AppColors.gold
                      : AppColors.gold.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isVIP || isVIPUnlock
                            ? AppColors.gold
                            : Colors.amber)
                        .withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),

                  // Level Up Title
                  Text(
                    l10n.levelUp,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Congratulations message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.levelUpCongratulations,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Level number with pulse animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.gold,
                            AppColors.gold.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.newLevel}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // You reached level X message
                  Text(
                    l10n.levelUpYouReachedLevel(widget.newLevel),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  // VIP Unlock message (at level 50)
                  if (isVIPUnlock) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.3),
                            AppColors.gold.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.diamond,
                            color: AppColors.gold,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.levelUpVIPUnlocked,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rewards section
                  if (widget.rewards.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.levelUpRewards,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: widget.rewards.map((reward) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRewardIcon(reward.type),
                                  size: 18,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reward.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.levelUpContinue,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'coins':
        return Icons.monetization_on;
      case 'frame':
        return Icons.crop_square;
      case 'badge':
        return Icons.military_tech;
      case 'theme':
        return Icons.palette;
      case 'feature':
        return Icons.star;
      case 'boost':
        return Icons.rocket_launch;
      case 'superlike':
        return Icons.favorite;
      default:
        return Icons.card_giftcard;
    }
  }
}
