import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/answer_input.dart';
import '../widgets/bomb_widget.dart';
import '../widgets/player_avatar_circle.dart';

/// Word Bomb game screen
/// Players type words containing a given letter/syllable before the bomb explodes
class WordBombScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const WordBombScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<WordBombScreen> createState() => _WordBombScreenState();
}

class _WordBombScreenState extends State<WordBombScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _turnGlowController;
  late Animation<double> _turnGlowAnimation;

  // ── Turn timer ──
  Timer? _turnTimer;
  int _remainingSeconds = 0;
  DateTime? _lastTurnStartedAt;
  bool _timeoutDispatched = false;

  // ── Answer feedback ──
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;
  late AnimationController _feedbackFadeController;
  late Animation<double> _feedbackFade;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool? _lastAnswerCorrect; // null = no feedback, true = correct, false = incorrect
  int _previousUsedWordsCount = 0;

  bool get _isMyTurn => widget.room.currentTurnUserId == widget.currentUserId;

  void _showAbandonDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.gameAbandonTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.gameAbandonLoseMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LanguageGamesBloc>().add(
                    LeaveRoom(roomId: widget.room.id, userId: widget.currentUserId),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.gameLeave, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showUsedWordsSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameWordBombUsedWords,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.room.usedWords.length,
                itemBuilder: (_, i) {
                  final word = widget.room.usedWords[widget.room.usedWords.length - 1 - i];
                  return ListTile(
                    dense: true,
                    title: Text(word, style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: IconButton(
                      icon: const Icon(Icons.flag_outlined, color: AppColors.textTertiary, size: 18),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReportDialog(word);
                      },
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

  void _showReportDialog(String word) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.gameWordBombReportTitle(word), style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.gameWordBombReportContent,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              context.read<LanguageGamesBloc>().add(ReportWord(
                    word: word,
                    reportedBy: widget.currentUserId,
                    roomId: widget.room.id,
                    reason: 'invalid_word',
                  ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.gameWordBombWordReported),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(l10n.gameWordBombReport, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  // ── Timer Management ──

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _timeoutDispatched = false;

    final turnStart = widget.room.turnStartedAt;
    if (turnStart == null) {
      setState(() => _remainingSeconds = widget.room.turnDurationSeconds);
      return;
    }

    _lastTurnStartedAt = turnStart;
    _computeRemaining();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    final turnStart = widget.room.turnStartedAt;
    if (turnStart == null) return;

    final elapsed = DateTime.now().difference(turnStart).inSeconds;
    final remaining = (widget.room.turnDurationSeconds - elapsed).clamp(0, widget.room.turnDurationSeconds);

    if (mounted) {
      setState(() => _remainingSeconds = remaining);
    }

    // Time's up — dispatch timeout if it's our turn
    if (remaining <= 0 && _isMyTurn && !_timeoutDispatched) {
      _timeoutDispatched = true;
      _turnTimer?.cancel();
      context.read<LanguageGamesBloc>().add(
            WordBombTimeout(
              roomId: widget.room.id,
              userId: widget.currentUserId,
            ),
          );
    }
  }

  // ── Answer Feedback ──

  void _showFeedback(bool correct) {
    setState(() => _lastAnswerCorrect = correct);

    _feedbackController.reset();
    _feedbackFadeController.value = 1.0;
    _feedbackController.forward();

    if (correct) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.reset();
      _shakeController.forward();
    }

    // Auto-dismiss after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _feedbackFadeController.reverse().then((_) {
          if (mounted) setState(() => _lastAnswerCorrect = null);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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

    // Answer feedback animations
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    _feedbackFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
    _feedbackFade = Tween<double>(begin: 0.0, end: 1.0).animate(_feedbackFadeController);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _previousUsedWordsCount = widget.room.usedWords.length;
    _startTurnTimer();
  }

  @override
  void didUpdateWidget(WordBombScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect new turn (turnStartedAt changed)
    if (widget.room.turnStartedAt != _lastTurnStartedAt) {
      _startTurnTimer();
    }

    // Detect answer feedback: usedWords count increased = correct answer accepted
    final newCount = widget.room.usedWords.length;
    if (newCount > _previousUsedWordsCount) {
      _showFeedback(true);
    }
    _previousUsedWordsCount = newCount;
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _particleController.dispose();
    _pulseController.dispose();
    _turnGlowController.dispose();
    _feedbackController.dispose();
    _feedbackFadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} ${l10n.gameWordBombTitle}',
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
                l10n.gameRoundCounter(widget.room.currentRound, widget.room.totalRounds),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed, size: 20),
            tooltip: l10n.gameAbandonTooltip,
            onPressed: () => _showAbandonDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated fire-themed particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _BombParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),

          // Main content (wrapped in shake for wrong answer)
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final offset = _shakeController.isAnimating ? _shakeAnimation.value : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Column(
              children: [
                // Player avatars with lives
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.room.players.map((player) {
                      return PlayerAvatarCircle(
                        player: player,
                        isCurrentTurn: widget.room.currentTurnUserId == player.userId,
                        isCurrentUser: player.userId == widget.currentUserId,
                        showLives: true,
                        showScore: true,
                        size: 44,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Turn indicator with glow pulse
                AnimatedBuilder(
                  animation: _turnGlowAnimation,
                  builder: (context, child) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isMyTurn
                          ? AppColors.richGold.withValues(alpha: 0.15)
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isMyTurn
                          ? [
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                    alpha: 0.2 * _turnGlowAnimation.value),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                      border: _isMyTurn
                          ? Border.all(
                              color: AppColors.richGold.withValues(
                                  alpha: 0.4 + 0.3 * _turnGlowAnimation.value),
                            )
                          : null,
                    ),
                    child: Text(
                      _isMyTurn
                          ? l10n.gameYourTurn
                          : l10n.gamePlayersTurn(widget.room.currentTurnPlayer?.displayName ?? l10n.gameWaiting),
                      style: TextStyle(
                        color: _isMyTurn ? AppColors.richGold : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Bomb widget with enhanced glow
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warningAmber.withValues(
                                  alpha: 0.08 + 0.08 * _pulseAnimation.value),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: AppColors.errorRed.withValues(
                                  alpha: 0.05 + 0.05 * _pulseAnimation.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: BombWidget(
                        remainingSeconds: _remainingSeconds,
                        totalSeconds: widget.room.turnDurationSeconds,
                        prompt: widget.room.currentPrompt ?? '',
                        hasExploded: _remainingSeconds <= 0 && _isMyTurn,
                      ),
                    ),
                  ),
                ),

                // Last 5 words scrollable display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => _showUsedWordsSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.gameWordBombWordsUsedCount(widget.room.usedWords.length),
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.expand_more, color: AppColors.textTertiary, size: 16),
                            ],
                          ),
                          if (widget.room.usedWords.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 24,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: widget.room.usedWords
                                    .reversed
                                    .take(5)
                                    .map((word) => Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.richGold.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              word,
                                              style: const TextStyle(
                                                color: AppColors.richGold,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Answer input (only active on your turn)
                AnswerInput(
                  hintText: _isMyTurn
                      ? l10n.gameWordBombTypeContainingHint(widget.room.currentPrompt ?? '')
                      : l10n.gameWaitForYourTurn,
                  enabled: _isMyTurn,
                  onSubmitted: (answer) {
                    final prompt = widget.room.currentPrompt ?? '';

                    // Client-side: check word contains the prompt
                    if (!answer.toLowerCase().contains(prompt.toLowerCase())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.gameWordBombMustContain(prompt)),
                          backgroundColor: AppColors.errorRed,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      _showFeedback(false);
                      return;
                    }

                    // Client-side: check word not already used
                    if (widget.room.usedWords
                        .map((w) => w.toLowerCase())
                        .contains(answer.toLowerCase())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.gameWordAlreadyUsed),
                          backgroundColor: AppColors.errorRed,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      _showFeedback(false);
                      return;
                    }

                    context.read<LanguageGamesBloc>().add(SubmitAnswer(
                          roomId: widget.room.id,
                          userId: widget.currentUserId,
                          answer: answer,
                        ));
                  },
                ),
              ],
            ),
          ),

          // ── Answer Feedback Overlay ──
          if (_lastAnswerCorrect != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_feedbackScale, _feedbackFade]),
                  builder: (context, _) {
                    return Opacity(
                      opacity: _feedbackFade.value,
                      child: Center(
                        child: Transform.scale(
                          scale: _feedbackScale.value,
                          child: _lastAnswerCorrect!
                              ? _buildCorrectFeedback()
                              : _buildIncorrectFeedback(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorrectFeedback() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.successGreen,
            size: 48,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.gamePlusPts(10),
          style: const TextStyle(
            color: AppColors.successGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIncorrectFeedback() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.errorRed.withValues(alpha: 0.2),
      ),
      child: const Icon(
        Icons.close_rounded,
        color: AppColors.errorRed,
        size: 48,
      ),
    );
  }
}

/// Fire-themed floating particles for Word Bomb background
class _BombParticlePainter extends CustomPainter {
  final double progress;

  _BombParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 20;
    const seed = 42;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 53) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final speed = 0.4 + (hash % 100) / 100.0 * 0.6;
      final phase = (hash % 628) / 100.0;
      final radius = 1.5 + (hash % 200) / 100.0;

      // Particles float upward (like embers)
      final yOffset = (progress * speed + phase / 6.28) % 1.0;
      final y = size.height * (1.0 - yOffset);
      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 15;
      final opacity = (0.05 + 0.06 * math.sin(progress * math.pi * 2 * speed + phase))
          .clamp(0.0, 1.0);

      // Warm colors: mix of amber, orange, red
      final colorMix = (i % 3);
      final color = colorMix == 0
          ? AppColors.warningAmber
          : colorMix == 1
              ? AppColors.errorRed
              : AppColors.richGold;

      canvas.drawCircle(
        Offset(baseX + dx, y),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );

      // Glow halo on every 3rd particle
      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(baseX + dx, y),
          radius * 3,
          Paint()..color = color.withValues(alpha: opacity * 0.25),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BombParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
