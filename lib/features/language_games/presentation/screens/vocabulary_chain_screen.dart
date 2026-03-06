import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../widgets/answer_input.dart';
import '../widgets/chain_bubble.dart';
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';

/// Vocabulary Chain game screen
/// Players chain words together where each word must start with the last letter
/// of the previous word, within a given theme/category
class VocabularyChainScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const VocabularyChainScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<VocabularyChainScreen> createState() => _VocabularyChainScreenState();
}

class _VocabularyChainScreenState extends State<VocabularyChainScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _turnGlowController;
  late Animation<double> _turnGlowAnimation;

  bool get _isMyTurn => widget.room.currentTurnUserId == widget.currentUserId;

  String get _lastLetter {
    if (widget.room.usedWords.isEmpty) return '';
    final lastWord = widget.room.usedWords.last;
    return lastWord.isNotEmpty
        ? lastWord[lastWord.length - 1].toUpperCase()
        : '';
  }

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

    _turnGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _turnGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _turnGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _turnGlowController.dispose();
    super.dispose();
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Abandon Game?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will lose your progress and return to the lobby.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LanguageGamesBloc>().add(LeaveRoom(
                    roomId: widget.room.id,
                    userId: widget.currentUserId,
                  ));
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Abandon',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} Vocabulary Chain',
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
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                'Round ${widget.room.currentRound}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
            tooltip: 'Abandon Game',
            onPressed: _showAbandonDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chain-themed particle background (linked dots)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ChainParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Player avatars with lives
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.room.players.map((player) {
                    return PlayerAvatarCircle(
                      player: player,
                      isCurrentTurn:
                          widget.room.currentTurnUserId == player.userId,
                      isCurrentUser:
                          player.userId == widget.currentUserId,
                      showLives: true,
                      showScore: true,
                      size: 40,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Theme badge and turn indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.room.roundTheme != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.infoBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category,
                              color: AppColors.infoBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.room.roundTheme!,
                            style: const TextStyle(
                              color: AppColors.infoBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 10),

                  // Turn indicator with glow
                  AnimatedBuilder(
                    animation: _turnGlowAnimation,
                    builder: (context, child) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isMyTurn
                            ? AppColors.richGold.withValues(alpha: 0.15)
                            : AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isMyTurn
                            ? [
                                BoxShadow(
                                  color: AppColors.richGold.withValues(
                                      alpha: 0.15 *
                                          _turnGlowAnimation.value),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _isMyTurn
                            ? 'YOUR TURN!'
                            : "${widget.room.currentTurnPlayer?.displayName ?? 'Waiting'}'s turn",
                        style: TextStyle(
                          color: _isMyTurn
                              ? AppColors.richGold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Timer
              GameTimer(
                remainingSeconds: widget.room.turnDurationSeconds,
                totalSeconds: widget.room.turnDurationSeconds,
                size: 48,
              ),

              const SizedBox(height: 8),

              // Next letter prompt with animated glow
              if (_lastLetter.isNotEmpty)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Next word must start with: ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.richGold,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                    alpha: 0.3 +
                                        0.3 * _pulseAnimation.value),
                                blurRadius:
                                    8 + 6 * _pulseAnimation.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            _lastLetter,
                            style: const TextStyle(
                              color: AppColors.backgroundDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Chain of words
              Expanded(child: _buildWordChain()),

              // Chain stats
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link,
                          color: AppColors.textTertiary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.room.usedWords.length} words chained',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Answer input
              AnswerInput(
                hintText: _isMyTurn
                    ? _lastLetter.isNotEmpty
                        ? 'Type a word starting with "$_lastLetter"...'
                        : 'Type a word to start the chain...'
                    : 'Wait for your turn...',
                enabled: _isMyTurn,
                onSubmitted: (answer) {
                  context.read<LanguageGamesBloc>().add(SubmitAnswer(
                        roomId: widget.room.id,
                        userId: widget.currentUserId,
                        answer: answer,
                      ));
                },
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildWordChain() {
    if (widget.room.usedWords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, color: AppColors.textTertiary, size: 48),
            SizedBox(height: 12),
            Text(
              'No words yet!',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Start the chain with any word',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final displayWords = widget.room.usedWords;

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: displayWords.length,
      itemBuilder: (context, index) {
        final wordIndex = displayWords.length - 1 - index;
        final word = displayWords[wordIndex];
        final isLatest = wordIndex == displayWords.length - 1;

        String? playerName;
        if (widget.currentRound != null) {
          for (final entry
              in widget.currentRound!.playerAnswers.entries) {
            if (entry.value.answer.toLowerCase() ==
                word.toLowerCase()) {
              final player = widget.room.getPlayer(entry.key);
              if (player != null) {
                playerName = player.userId == widget.currentUserId
                    ? 'You'
                    : player.displayName;
              }
              break;
            }
          }
        }

        return Align(
          alignment: Alignment.center,
          child: ChainBubble(
            word: word,
            isLatest: isLatest,
            showConnector: wordIndex > 0,
            playerName: playerName,
          ),
        );
      },
    );
  }
}

/// Chain-themed particles — connected dots floating
class _ChainParticlePainter extends CustomPainter {
  final double progress;

  _ChainParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 20;
    const seed = 33;
    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 47) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 321) % 1000) / 1000.0 * size.height;
      final speed = 0.2 + (hash % 100) / 100.0 * 0.5;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 10;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.6 + phase) * 8;
      final opacity =
          (0.04 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      final pos = Offset(baseX + dx, baseY + dy);
      points.add(pos);

      canvas.drawCircle(
        pos,
        1.2,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }

    // Draw subtle connecting lines between nearby particles
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < 80) {
          final alpha = (0.03 * (1.0 - dist / 80)).clamp(0.0, 1.0);
          linePaint.color = AppColors.richGold.withValues(alpha: alpha);
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
