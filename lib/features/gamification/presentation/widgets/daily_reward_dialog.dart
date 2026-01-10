import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../domain/entities/login_streak.dart';

/// Daily Reward Dialog
/// Shows celebratory animation when user earns daily login rewards
class DailyRewardDialog extends StatefulWidget {
  final DailyLoginReward reward;
  final int currentStreak;
  final StreakMilestone? nextMilestone;
  final int? daysUntilNextMilestone;
  final VoidCallback? onClose;

  const DailyRewardDialog({
    super.key,
    required this.reward,
    required this.currentStreak,
    this.nextMilestone,
    this.daysUntilNextMilestone,
    this.onClose,
  });

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    required DailyLoginReward reward,
    required int currentStreak,
    StreakMilestone? nextMilestone,
    int? daysUntilNextMilestone,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardDialog(
        reward: reward,
        currentStreak: currentStreak,
        nextMilestone: nextMilestone,
        daysUntilNextMilestone: daysUntilNextMilestone,
      ),
    );
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _coinController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _coinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOutBack),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _coinController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade800,
                Colors.green.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with streak fire animation
              _buildHeader(),
              // Rewards section
              _buildRewardsSection(),
              // Streak progress
              _buildStreakProgress(),
              // Close button
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Fire animation placeholder (use Lottie if available)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 50,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Day ${widget.currentStreak}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Daily Login Reward!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return AnimatedBuilder(
      animation: _coinAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _coinAnimation.value,
          child: Transform.scale(
            scale: _coinAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Coins reward
            _buildRewardItem(
              icon: Icons.monetization_on,
              iconColor: Colors.amber,
              value: '+${widget.reward.totalCoins}',
              label: 'Coins',
            ),
            // Divider
            Container(
              width: 1,
              height: 50,
              color: Colors.white24,
            ),
            // XP reward
            _buildRewardItem(
              icon: Icons.star,
              iconColor: Colors.purple,
              value: '+${widget.reward.xp}',
              label: 'XP',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 36),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakProgress() {
    if (widget.nextMilestone == null) {
      return const SizedBox(height: 20);
    }

    final progress = widget.currentStreak / widget.nextMilestone!.daysRequired;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next: ${widget.nextMilestone!.name}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '${widget.daysUntilNextMilestone} days left',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade400),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // Milestone reward preview
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.nextMilestone!.coinReward}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, color: Colors.purple, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.nextMilestone!.xpReward}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onClose?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Claim Reward',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Milestone Claimed Dialog
/// Shows when user claims a streak milestone
class MilestoneClaimedDialog extends StatelessWidget {
  final StreakMilestone milestone;
  final VoidCallback? onClose;

  const MilestoneClaimedDialog({
    super.key,
    required this.milestone,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required StreakMilestone milestone,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneClaimedDialog(milestone: milestone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade800,
              Colors.purple.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withAlpha(100),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Trophy icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Milestone Achieved!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Rewards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _rewardBadge(
                          Icons.monetization_on,
                          Colors.amber,
                          '+${milestone.coinReward}',
                        ),
                        _rewardBadge(
                          Icons.star,
                          Colors.purple.shade200,
                          '+${milestone.xpReward}',
                        ),
                        if (milestone.badgeId != null)
                          _rewardBadge(
                            Icons.military_tech,
                            Colors.orange,
                            'Badge',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Claim button
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardBadge(IconData icon, Color color, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
