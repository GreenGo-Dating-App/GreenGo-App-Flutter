import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/answer_input.dart';
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';

/// Picture Guess game screen
/// One player describes a word, others try to guess it
/// The describer sees the word, guessers see clues
class PictureGuessScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const PictureGuessScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<PictureGuessScreen> createState() => _PictureGuessScreenState();
}

class _PictureGuessScreenState extends State<PictureGuessScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _roleGlowController;
  late Animation<double> _roleGlowAnimation;

  bool get _isDescriber =>
      widget.room.currentDescriberId == widget.currentUserId;
  bool get _hasGuessed =>
      widget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _roleGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _roleGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _roleGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _roleGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} Picture Guess',
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
          // Guess-themed particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _GuessParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Player avatars with roles
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.room.players.map((player) {
                    final isDescriber =
                        widget.room.currentDescriberId == player.userId;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatarCircle(
                          player: player,
                          isCurrentTurn: isDescriber,
                          isCurrentUser:
                              player.userId == widget.currentUserId,
                          showScore: true,
                          size: 40,
                        ),
                        const SizedBox(height: 2),
                        if (isDescriber)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.richGold
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DESCRIBER',
                              style: TextStyle(
                                color: AppColors.richGold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // Timer
              if (widget.currentRound != null) ...[
                const SizedBox(height: 8),
                GameTimer(
                  remainingSeconds: widget.currentRound!.remainingSeconds,
                  totalSeconds: widget.currentRound!.durationSeconds,
                  size: 52,
                ),
              ],

              const SizedBox(height: 16),

              // Role indicator with animated glow
              AnimatedBuilder(
                animation: _roleGlowAnimation,
                builder: (context, child) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDescriber
                        ? AppColors.richGold.withValues(alpha: 0.15)
                        : AppColors.infoBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_isDescriber
                                ? AppColors.richGold
                                : AppColors.infoBlue)
                            .withValues(
                                alpha: 0.1 * _roleGlowAnimation.value),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    _isDescriber
                        ? 'You are the DESCRIBER!'
                        : 'Guess the word!',
                    style: TextStyle(
                      color: _isDescriber
                          ? AppColors.richGold
                          : AppColors.infoBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isDescriber
                      ? _buildDescriberView(context)
                      : _buildGuesserView(),
                ),
              ),

              // Input area
              if (_isDescriber)
                AnswerInput(
                  hintText: 'Type a clue (no direct translations!)...',
                  enabled: true,
                  onSubmitted: (clue) {
                    context.read<LanguageGamesBloc>().add(SubmitAnswer(
                          roomId: widget.room.id,
                          userId: widget.currentUserId,
                          answer: 'CLUE:$clue',
                        ));
                  },
                )
              else
                AnswerInput(
                  hintText: _hasGuessed
                      ? 'Guess submitted! Waiting...'
                      : 'Type your guess...',
                  enabled: !_hasGuessed,
                  onSubmitted: (guess) {
                    context.read<LanguageGamesBloc>().add(SubmitAnswer(
                          roomId: widget.room.id,
                          userId: widget.currentUserId,
                          answer: guess,
                        ));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriberView(BuildContext context) {
    final wordToDescribe =
        widget.currentRound?.prompt ?? widget.room.currentPrompt ?? '...';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'YOUR WORD',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        // Secret word with pulsing gold glow
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.richGold.withValues(alpha: 0.2),
                  AppColors.richGold.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.richGold.withValues(
                    alpha: 0.7 + 0.3 * _pulseAnimation.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(
                      alpha: 0.1 + 0.15 * _pulseAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Text(
              wordToDescribe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rules reminder
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.textTertiary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Give clues to help others guess. No direct translations or spelling hints!',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildGuessingProgress(),
      ],
    );
  }

  Widget _buildGuesserView() {
    final clues = <String>[];
    if (widget.currentRound != null) {
      for (final answer in widget.currentRound!.playerAnswers.values) {
        if (answer.userId == widget.room.currentDescriberId &&
            answer.answer.startsWith('CLUE:')) {
          clues.add(answer.answer.substring(5));
        }
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'CLUES',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.5),
            ),
          ),
          child: clues.isEmpty
              ? const Center(
                  child: Text(
                    'Waiting for clues...',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: clues.asMap().entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.infoBlue
                              .withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.infoBlue
                                .withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 16),

        if (_hasGuessed) _buildGuessFeedback(),

        const SizedBox(height: 12),
        _buildGuessingProgress(),
      ],
    );
  }

  Widget _buildGuessFeedback() {
    final answer =
        widget.currentRound?.playerAnswers[widget.currentUserId];
    if (answer == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: answer.isCorrect
            ? AppColors.successGreen.withValues(alpha: 0.15)
            : AppColors.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isCorrect
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : AppColors.errorRed.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: (answer.isCorrect
                    ? AppColors.successGreen
                    : AppColors.errorRed)
                .withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            answer.isCorrect ? Icons.check_circle : Icons.cancel,
            color: answer.isCorrect
                ? AppColors.successGreen
                : AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            answer.isCorrect
                ? 'Correct! +${answer.pointsEarned} points'
                : 'Wrong guess: "${answer.answer}"',
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

  Widget _buildGuessingProgress() {
    final guessers = widget.room.players
        .where((p) => p.userId != widget.room.currentDescriberId)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: guessers.map((player) {
        final hasGuessed =
            widget.currentRound?.hasPlayerAnswered(player.userId) ??
                false;
        final isCorrect = widget
                .currentRound?.playerAnswers[player.userId]?.isCorrect ??
            false;
        final isMe = player.userId == widget.currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !hasGuessed
                      ? AppColors.divider
                      : isCorrect
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                  boxShadow: hasGuessed
                      ? [
                          BoxShadow(
                            color: (isCorrect
                                    ? AppColors.successGreen
                                    : AppColors.errorRed)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: hasGuessed
                    ? Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: AppColors.textPrimary,
                        size: 14,
                      )
                    : const Icon(
                        Icons.hourglass_empty,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                isMe ? 'You' : player.displayName,
                style: TextStyle(
                  color: isMe
                      ? AppColors.richGold
                      : AppColors.textTertiary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Mystery/guess-themed floating question mark particles
class _GuessParticlePainter extends CustomPainter {
  final double progress;

  _GuessParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 20;
    const seed = 88;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 51) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 213) % 1000) / 1000.0 * size.height;
      final speed = 0.2 + (hash % 100) / 100.0 * 0.5;
      final phase = (hash % 628) / 100.0;
      final radius = 1.0 + (hash % 150) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 10;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.6 + phase) * 8;
      final opacity =
          (0.04 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      // Alternate between gold and blue particles
      final color = i % 2 == 0 ? AppColors.richGold : AppColors.infoBlue;

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );

      // Glow on every 4th particle
      if (i % 4 == 0) {
        canvas.drawCircle(
          Offset(baseX + dx, baseY + dy),
          radius * 3,
          Paint()..color = color.withValues(alpha: opacity * 0.25),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuessParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
