import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';

/// Grammar Duel game screen
/// Two players face off answering grammar questions with 4 options
/// VS layout with player avatars on each side
class GrammarDuelScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const GrammarDuelScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<GrammarDuelScreen> createState() => _GrammarDuelScreenState();
}

class _GrammarDuelScreenState extends State<GrammarDuelScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _vsGlowController;
  late Animation<double> _vsGlowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _hasAnswered =>
      widget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;

  GameAnswer? get _myAnswer =>
      widget.currentRound?.playerAnswers[widget.currentUserId];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _vsGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _vsGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vsGlowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _vsGlowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} Grammar Duel',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Round ${widget.room.currentRound}/${widget.room.totalRounds}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Duel-themed particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _DuelParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          Column(
            children: [
              // VS Layout with two players
              _buildVsLayout(),

              const SizedBox(height: 12),

              // Timer
              if (widget.currentRound != null)
                GameTimer(
                  remainingSeconds: widget.currentRound!.remainingSeconds,
                  totalSeconds: widget.currentRound!.durationSeconds,
                  size: 52,
                ),

              const SizedBox(height: 16),

              // Question
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Question text with pulsing border
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.divider.withValues(
                                  alpha: 0.5 + 0.3 * _pulseAnimation.value),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                    alpha: 0.04 * _pulseAnimation.value),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.currentRound?.prompt ??
                                widget.room.currentPrompt ??
                                '...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4 Answer options in a 2x2 grid
                      if (widget.currentRound != null &&
                          widget.currentRound!.options.isNotEmpty)
                        _buildOptionsGrid(context),

                      // Answer status
                      if (_hasAnswered) ...[
                        const SizedBox(height: 16),
                        _buildAnswerStatus(),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom padding
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVsLayout() {
    final player1 =
        widget.room.players.isNotEmpty ? widget.room.players[0] : null;
    final player2 =
        widget.room.players.length > 1 ? widget.room.players[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Player 1
          if (player1 != null)
            Expanded(
              child: _buildPlayerSide(player1, isLeft: true),
            ),

          // VS badge with animated glow
          AnimatedBuilder(
            animation: _vsGlowAnimation,
            builder: (context, child) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.richGold.withValues(alpha: 0.3),
                    AppColors.richGold.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.richGold.withValues(
                      alpha: 0.7 + 0.3 * _vsGlowAnimation.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(
                        alpha: 0.15 + 0.2 * _vsGlowAnimation.value),
                    blurRadius: 12 + 8 * _vsGlowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Player 2
          if (player2 != null)
            Expanded(
              child: _buildPlayerSide(player2, isLeft: false),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerSide(dynamic player, {required bool isLeft}) {
    final hasAnswered =
        widget.currentRound?.hasPlayerAnswered(player.userId) ?? false;
    final isMe = player.userId == widget.currentUserId;

    return Column(
      children: [
        PlayerAvatarCircle(
          player: player,
          isCurrentUser: isMe,
          showScore: true,
          size: 36,
        ),
        const SizedBox(height: 4),
        // Answer indicator with glow
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: hasAnswered
                ? AppColors.successGreen.withValues(alpha: 0.2)
                : AppColors.divider.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: hasAnswered
                ? [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Text(
            hasAnswered ? 'Answered' : 'Thinking...',
            style: TextStyle(
              color: hasAnswered
                  ? AppColors.successGreen
                  : AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    final options = widget.currentRound!.options;
    final correctAnswer = widget.currentRound?.correctAnswer;

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _myAnswer?.answer == option;
          final isCorrectOption =
              _hasAnswered && correctAnswer != null && option == correctAnswer;
          final isWrongSelection =
              isSelected && !(_myAnswer?.isCorrect ?? false);

          final label = String.fromCharCode(65 + index);

          Color bgColor;
          Color borderColor;
          Color textColor;

          if (_hasAnswered) {
            if (isCorrectOption) {
              bgColor = AppColors.successGreen.withValues(alpha: 0.2);
              borderColor = AppColors.successGreen;
              textColor = AppColors.successGreen;
            } else if (isWrongSelection) {
              bgColor = AppColors.errorRed.withValues(alpha: 0.2);
              borderColor = AppColors.errorRed;
              textColor = AppColors.errorRed;
            } else {
              bgColor = AppColors.backgroundCard;
              borderColor = AppColors.divider;
              textColor = AppColors.textTertiary;
            }
          } else {
            bgColor = AppColors.backgroundCard;
            borderColor = AppColors.divider;
            textColor = AppColors.textPrimary;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasAnswered
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.read<LanguageGamesBloc>().add(SubmitAnswer(
                            roomId: widget.room.id,
                            userId: widget.currentUserId,
                            answer: option,
                          ));
                    },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: (isCorrectOption || isWrongSelection)
                      ? [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: isSelected || isCorrectOption
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_hasAnswered &&
                        (isCorrectOption || isWrongSelection))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          isCorrectOption
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isCorrectOption
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnswerStatus() {
    final answer = _myAnswer;
    if (answer == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: answer.isCorrect
            ? AppColors.successGreen.withValues(alpha: 0.15)
            : AppColors.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (answer.isCorrect
                    ? AppColors.successGreen
                    : AppColors.errorRed)
                .withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            answer.isCorrect ? Icons.emoji_events : Icons.close,
            color: answer.isCorrect
                ? AppColors.successGreen
                : AppColors.errorRed,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            answer.isCorrect
                ? '+${answer.pointsEarned} points!'
                : 'Wrong answer!',
            style: TextStyle(
              color: answer.isCorrect
                  ? AppColors.successGreen
                  : AppColors.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Duel-themed particles — sparks flying from center
class _DuelParticlePainter extends CustomPainter {
  final double progress;

  _DuelParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.15;
    const count = 16;
    const seed = 55;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 67) & 0xFFFF;
      final angle = (hash % 628) / 100.0;
      final speed = 0.3 + (hash % 100) / 100.0 * 0.7;
      final maxDist = 40.0 + (hash % 80);
      final radius = 1.0 + (hash % 150) / 100.0;

      final dist = ((progress * speed + angle / 6.28) % 1.0) * maxDist;
      final dx = math.cos(angle) * dist;
      final dy = math.sin(angle) * dist;
      final opacity = (0.06 * (1.0 - dist / maxDist)).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(centerX + dx, centerY + dy),
        radius,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }

    // Additional ambient floating particles
    for (int i = 0; i < 12; i++) {
      final hash = (seed * 13 + i * 39) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 321) % 1000) / 1000.0 * size.height;
      final speed = 0.2 + (hash % 100) / 100.0 * 0.4;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 6;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.5 + phase) * 4;
      final opacity = (0.03 + 0.03 * math.sin(progress * math.pi * 2 * speed + phase))
          .clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        1.0,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DuelParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
