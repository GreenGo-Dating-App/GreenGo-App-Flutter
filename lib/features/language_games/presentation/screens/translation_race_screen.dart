import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/player_avatar_circle.dart';

/// Translation Race game screen (tap-based)
/// Players race to correctly translate words by tapping one of 12 options.
/// First to 30 correct answers wins.
class TranslationRaceScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const TranslationRaceScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<TranslationRaceScreen> createState() => _TranslationRaceScreenState();
}

class _TranslationRaceScreenState extends State<TranslationRaceScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _selectedAnswer;
  bool _showFeedback = false;

  bool get _hasAnswered =>
      widget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;

  GameAnswer? get _myAnswer =>
      widget.currentRound?.playerAnswers[widget.currentUserId];

  int get _myScore => widget.room.scores[widget.currentUserId] ?? 0;

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
  }

  @override
  void didUpdateWidget(TranslationRaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection when round changes
    if (oldWidget.currentRound?.roundNumber != widget.currentRound?.roundNumber) {
      setState(() {
        _selectedAnswer = null;
        _showFeedback = false;
      });
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onOptionTapped(String answer) {
    if (_hasAnswered || _selectedAnswer != null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
    });
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: answer,
        ));
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Abandon Game?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You will lose this game if you leave now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LanguageGamesBloc>().add(
                    LeaveRoom(roomId: widget.room.id, userId: widget.currentUserId),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get options from room metadata or round
    final options = widget.currentRound?.options ?? [];
    final prompt = widget.currentRound?.prompt ?? widget.room.currentPrompt ?? '...';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} Translation Race',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed, size: 20),
            tooltip: 'Abandon Game',
            onPressed: _showAbandonDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _RaceParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Progress bars for each player (score out of 30)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: widget.room.players.map((player) {
                    final score = widget.room.scores[player.userId] ?? 0;
                    final isMe = player.userId == widget.currentUserId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              isMe ? 'You' : player.displayName,
                              style: TextStyle(
                                color: isMe ? AppColors.richGold : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (score / 30).clamp(0.0, 1.0),
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMe ? AppColors.richGold : AppColors.textTertiary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$score/30',
                            style: TextStyle(
                              color: isMe ? AppColors.richGold : AppColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Word to translate (large styled card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.richGold.withValues(
                            alpha: 0.3 + 0.3 * _pulseAnimation.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withValues(
                              alpha: 0.08 + 0.1 * _pulseAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Translate to ${widget.room.targetLanguage.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4x3 grid of 12 tappable answer buttons
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: options.length.clamp(0, 12),
                    itemBuilder: (context, index) {
                      if (index >= options.length) return const SizedBox.shrink();
                      final option = options[index];
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = _showFeedback &&
                          widget.currentRound?.correctAnswer == option;
                      final isWrongSelection = isSelected &&
                          _showFeedback &&
                          widget.currentRound?.correctAnswer != option;

                      Color bgColor = AppColors.backgroundCard;
                      Color borderColor = AppColors.divider;
                      Color textColor = AppColors.textPrimary;

                      if (isCorrect) {
                        bgColor = AppColors.successGreen.withValues(alpha: 0.2);
                        borderColor = AppColors.successGreen;
                        textColor = AppColors.successGreen;
                      } else if (isWrongSelection) {
                        bgColor = AppColors.errorRed.withValues(alpha: 0.2);
                        borderColor = AppColors.errorRed;
                        textColor = AppColors.errorRed;
                      } else if (_hasAnswered) {
                        bgColor = AppColors.backgroundCard.withValues(alpha: 0.5);
                        textColor = AppColors.textTertiary;
                      }

                      return GestureDetector(
                        onTap: () => _onOptionTapped(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // First to 30 label
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'First to 30 wins!',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Speed-themed particles (horizontal streaks) for Translation Race
class _RaceParticlePainter extends CustomPainter {
  final double progress;

  _RaceParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 18;
    const seed = 77;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 59) & 0xFFFF;
      final baseY = (hash % 1000) / 1000.0 * size.height;
      final speed = 0.3 + (hash % 100) / 100.0 * 0.7;
      final phase = (hash % 628) / 100.0;
      final length = 20.0 + (hash % 60);

      final xOffset = ((progress * speed + phase / 6.28) % 1.0) * (size.width + length);
      final dy = math.sin(progress * math.pi * 2 * speed * 0.3 + phase) * 4;
      final opacity = (0.04 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
          .clamp(0.0, 1.0);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0),
            AppColors.richGold.withValues(alpha: opacity),
          ],
        ).createShader(Rect.fromLTWH(xOffset - length, baseY + dy, length, 2));

      canvas.drawRect(
        Rect.fromLTWH(xOffset - length, baseY + dy, length, 1.5),
        paint,
      );
    }

    for (int i = 0; i < 10; i++) {
      final hash = (seed * 17 + i * 43) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 123) % 1000) / 1000.0 * size.height;
      final speed = 0.3 + (hash % 100) / 100.0 * 0.4;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 6;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.5 + phase) * 4;
      final opacity = (0.03 + 0.03 * math.sin(progress * math.pi * 2 * speed + phase))
          .clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        1.2,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaceParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
