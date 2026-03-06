import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_room.dart';

/// End-of-game results screen with rankings, XP breakdown, and learned words
class GameResultsScreen extends StatefulWidget {
  /// The current player's user ID, resolved from either [userId] or [currentUserId].
  final String playerId;
  final GameRoom room;
  final Map<String, int> finalScores;
  final String? winnerId;
  final int xpEarned;
  final int coinsEarned;

  const GameResultsScreen({
    super.key,
    required this.room,
    required this.finalScores,
    String? userId,
    String? currentUserId,
    this.winnerId,
    this.xpEarned = 0,
    this.coinsEarned = 0,
  }) : playerId = userId ?? currentUserId ?? '';

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _trophyController;
  late Animation<double> _trophyScaleAnimation;
  late AnimationController _confettiController;
  late AnimationController _staggerController;
  late AnimationController _glowPulseController;
  late Animation<double> _glowPulseAnimation;
  late AnimationController _scoreCountController;

  bool _isWinner = false;

  @override
  void initState() {
    super.initState();
    _isWinner = widget.winnerId == widget.playerId;

    // Play victory or defeat sound
    AppSoundService().play(
      _isWinner ? AppSound.gameVictory : AppSound.gameDefeat,
    );

    // Trophy bounce animation
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trophyScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_trophyController);

    // Confetti loop animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Stagger animation for rows sliding in
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Glow pulse for winner
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    // Score count-up animation
    _scoreCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Trigger animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _trophyController.forward();
      _staggerController.forward();
      _scoreCountController.forward();
      if (_isWinner) {
        _confettiController.repeat();
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _confettiController.dispose();
    _staggerController.dispose();
    _glowPulseController.dispose();
    _scoreCountController.dispose();
    super.dispose();
  }

  Future<void> _onPlayAgain() async {
    HapticFeedback.mediumImpact();
    // Play Again costs 10 coins
    try {
      final coinDoc = await FirebaseFirestore.instance
          .collection('coin_balances')
          .doc(widget.playerId)
          .get();
      final available = (coinDoc.data()?['availableCoins'] as int?) ?? 0;
      if (available < 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins (10 required)')),
          );
        }
        return;
      }
      await FirebaseFirestore.instance
          .collection('coin_balances')
          .doc(widget.playerId)
          .update({'availableCoins': FieldValue.increment(-10)});
    } catch (_) {
      // Allow play even if coin check fails
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _onBackToLobby() {
    HapticFeedback.lightImpact();
    context.read<LanguageGamesBloc>().add(
          LeaveRoom(roomId: widget.room.id, userId: widget.playerId),
        );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  List<MapEntry<String, int>> get _sortedScores {
    final entries = widget.finalScores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                // Trophy header
                SliverToBoxAdapter(child: _buildTrophyHeader()),

                // Winner announcement
                SliverToBoxAdapter(child: _buildWinnerAnnouncement()),

                // Leaderboard
                SliverToBoxAdapter(child: _buildLeaderboard()),

                // XP breakdown
                SliverToBoxAdapter(child: _buildXpBreakdown()),

                // What you learned
                SliverToBoxAdapter(child: _buildLearningSection()),

                // Action buttons
                SliverToBoxAdapter(child: _buildActionButtons()),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),

            // Confetti overlay (winner only)
            if (_isWinner)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: MediaQuery.of(context).size,
                      painter: _ConfettiPainter(
                        progress: _confettiController.value,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyHeader() {
    return AnimatedBuilder(
      animation: _glowPulseAnimation,
      builder: (context, _) {
        final glow = _glowPulseAnimation.value;
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: ScaleTransition(
              scale: _trophyScaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy/emoji with animated glow halo
                  Container(
                    decoration: _isWinner
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.richGold.withValues(alpha: 0.15 + 0.15 * glow),
                                blurRadius: 30 + 20 * glow,
                                spreadRadius: 10 + 10 * glow,
                              ),
                            ],
                          )
                        : null,
                    child: Text(
                      _isWinner ? '\u{1F3C6}' : '\u{1F3AE}',
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _isWinner ? AppColors.goldGradient : null,
                      color: _isWinner ? null : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isWinner
                          ? [
                              BoxShadow(
                                color: AppColors.richGold.withValues(alpha: 0.3 * glow),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _isWinner ? 'VICTORY!' : 'GAME OVER',
                      style: TextStyle(
                        color: _isWinner
                            ? AppColors.backgroundDark
                            : AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerAnnouncement() {
    final winner = widget.room.getPlayer(widget.winnerId ?? '');
    if (winner == null) return const SizedBox.shrink();

    final isMe = winner.userId == widget.playerId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.richGold.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Crown icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.backgroundDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Winner',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMe ? 'You won!' : winner.displayName,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${widget.finalScores[winner.userId] ?? 0} pts',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINAL STANDINGS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: AnimatedBuilder(
              animation: _staggerController,
              builder: (context, _) {
                return Column(
                  children: _sortedScores.asMap().entries.map((entry) {
                    final rank = entry.key;
                    final scoreEntry = entry.value;
                    final player =
                        widget.room.getPlayer(scoreEntry.key);
                    final isMe = scoreEntry.key == widget.playerId;

                    // Stagger: each row slides in with delay
                    final delay = rank * 0.15;
                    final rowProgress = ((_staggerController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
                    final slideOffset = 30.0 * (1.0 - Curves.easeOut.transform(rowProgress));
                    final rowOpacity = rowProgress;

                    return Transform.translate(
                      offset: Offset(slideOffset, 0),
                      child: Opacity(
                        opacity: rowOpacity,
                        child: _buildLeaderboardRow(
                          rank: rank + 1,
                          player: player,
                          score: scoreEntry.value,
                          isMe: isMe,
                          isLast: rank == _sortedScores.length - 1,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required int rank,
    required GamePlayer? player,
    required int score,
    required bool isMe,
    required bool isLast,
  }) {
    final String rankText;
    final Color rankColor;
    switch (rank) {
      case 1:
        rankText = '\u{1F947}';
        rankColor = AppColors.richGold;
      case 2:
        rankText = '\u{1F948}';
        rankColor = AppColors.textSecondary;
      case 3:
        rankText = '\u{1F949}';
        rankColor = AppColors.warningAmber;
      default:
        rankText = '$rank';
        rankColor = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.richGold.withValues(alpha: 0.08)
            : Colors.transparent,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : (rank == 1
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : null),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rank <= 3
                ? Text(rankText, style: const TextStyle(fontSize: 22))
                : Text(
                    rankText,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Player name
          Expanded(
            child: Text(
              isMe ? 'You' : (player?.displayName ?? 'Player'),
              style: TextStyle(
                color: isMe ? AppColors.richGold : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // Score
          Text(
            '$score pts',
            style: TextStyle(
              color: rank == 1 ? AppColors.richGold : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBreakdown() {
    final baseXp = 25;
    final difficultyBonus = widget.room.difficulty * 5;
    final winnerBonus = _isWinner ? 50 : 0;
    final totalXp = widget.xpEarned > 0
        ? widget.xpEarned
        : baseXp + difficultyBonus + winnerBonus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REWARDS EARNED',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildXpRow('Base XP', '+$baseXp'),
                _buildXpRow(
                    'Difficulty Bonus (Lv.${widget.room.difficulty})',
                    '+$difficultyBonus'),
                if (_isWinner) _buildXpRow('Winner Bonus', '+$winnerBonus'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.divider, height: 1),
                ),
                AnimatedBuilder(
                  animation: _scoreCountController,
                  builder: (context, _) {
                    final countUp = (_scoreCountController.value * totalXp).round();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total XP',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '+$countUp XP',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (widget.coinsEarned > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Coins Earned',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.accentGold,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.coinsEarned}',
                            style: const TextStyle(
                              color: AppColors.accentGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSection() {
    // Words learned come from the game rounds (usedWords on the room)
    final words = widget.room.usedWords;
    if (words.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_rounded, color: AppColors.richGold, size: 18),
              SizedBox(width: 6),
              Text(
                'WHAT YOU LEARNED',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.take(20).map((word) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // Play Again
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onPlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Back to Lobby
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _onBackToLobby,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Back to Lobby',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich confetti painter with rotating particles, varied shapes
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _random = math.Random(42);
  static final List<_ConfettiParticle> _particles = List.generate(
    80,
    (i) => _ConfettiParticle(
      x: _random.nextDouble(),
      speed: 0.2 + _random.nextDouble() * 0.8,
      size: 3 + _random.nextDouble() * 8,
      color: [
        AppColors.richGold,
        AppColors.accentGold,
        AppColors.successGreen,
        AppColors.infoBlue,
        AppColors.errorRed,
        AppColors.warningAmber,
        const Color(0xFFFF69B4), // pink
        const Color(0xFF7B68EE), // purple
      ][_random.nextInt(8)],
      wobble: _random.nextDouble() * math.pi * 2,
      rotationSpeed: 1.0 + _random.nextDouble() * 3.0,
      shape: _random.nextInt(3), // 0=rect, 1=circle, 2=diamond
    ),
  );

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final y = (progress * particle.speed * 1.5) % 1.0;
      final x = particle.x +
          math.sin(y * math.pi * 4 + particle.wobble) * 0.08;
      final opacity = (1.0 - y * 0.7).clamp(0.0, 1.0);
      final rotation = progress * particle.rotationSpeed * math.pi * 2;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final center = Offset(x * size.width, y * size.height);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case 0: // Rectangle
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: particle.size,
                height: particle.size * 1.5,
              ),
              Radius.circular(particle.size * 0.15),
            ),
            paint,
          );
        case 1: // Circle
          canvas.drawCircle(Offset.zero, particle.size * 0.5, paint);
        default: // Diamond
          final path = Path()
            ..moveTo(0, -particle.size * 0.6)
            ..lineTo(particle.size * 0.4, 0)
            ..lineTo(0, particle.size * 0.6)
            ..lineTo(-particle.size * 0.4, 0)
            ..close();
          canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiParticle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double wobble;
  final double rotationSpeed;
  final int shape;

  const _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.wobble,
    required this.rotationSpeed,
    required this.shape,
  });
}

