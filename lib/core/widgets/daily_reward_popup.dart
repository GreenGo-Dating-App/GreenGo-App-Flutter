import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #11: Daily Login Reward Popup
/// Shows daily reward on first login
class DailyRewardPopup extends StatefulWidget {
  final int day;
  final int coins;
  final int xp;
  final bool isStreakBonus;
  final int streakDays;
  final VoidCallback? onClaim;

  const DailyRewardPopup({
    super.key,
    required this.day,
    required this.coins,
    required this.xp,
    this.isStreakBonus = false,
    this.streakDays = 1,
    this.onClaim,
  });

  @override
  State<DailyRewardPopup> createState() => _DailyRewardPopupState();
}

class _DailyRewardPopupState extends State<DailyRewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isStreakBonus
                ? AppColors.richGold
                : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.isStreakBonus ? '🔥 Streak Bonus!' : '🎁 Daily Reward',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Day ${widget.day}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Animated gift box
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 50,
                      color: AppColors.deepBlack,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Streak indicator
            if (widget.streakDays > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.streakDays} Day Streak!',
                      style: const TextStyle(
                        color: AppColors.warningAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Rewards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardItem(
                  icon: Icons.monetization_on,
                  value: widget.coins,
                  label: 'Coins',
                  color: AppColors.richGold,
                ),
                const SizedBox(width: 24),
                _RewardItem(
                  icon: Icons.star,
                  value: widget.xp,
                  label: 'XP',
                  color: AppColors.infoBlue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Weekly progress
            _WeeklyProgress(currentDay: widget.day),
            const SizedBox(height: 24),
            // Claim button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onClaim?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Claim Reward',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _RewardItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          '+$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final int currentDay;

  const _WeeklyProgress({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isCompleted = day <= currentDay;
            final isCurrent = day == currentDay;
            return Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.richGold
                    : AppColors.backgroundInput,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColors.richGold, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.deepBlack,
                      )
                    : Text(
                        '$day',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Show daily reward popup
void showDailyRewardPopup(
  BuildContext context, {
  required int day,
  required int coins,
  required int xp,
  bool isStreakBonus = false,
  int streakDays = 1,
  VoidCallback? onClaim,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DailyRewardPopup(
      day: day,
      coins: coins,
      xp: xp,
      isStreakBonus: isStreakBonus,
      streakDays: streakDays,
      onClaim: onClaim,
    ),
  );
}
