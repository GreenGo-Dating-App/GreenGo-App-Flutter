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
import '../widgets/game_timer.dart';

/// Translation Race game screen (tap-based)
/// Players race to correctly translate words by tapping one of 12 options.
/// First to 30 points wins.
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

  // Round timer
  Timer? _roundTimer;
  int _remainingSeconds = 15;
  bool _advanceDispatched = false;

  // Answer state
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _revealCorrect = false;

  // Streak
  int _correctStreak = 0;

  // Feedback animations
  late AnimationController _feedbackController;
  late AnimationController _scorePopController;
  late Animation<double> _scorePopOffset;
  late Animation<double> _scorePopOpacity;
  String _scorePopText = '';
  bool _showScorePop = false;

  // Streak animation
  late AnimationController _streakController;
  late Animation<double> _streakScale;

  // Round transition
  late AnimationController _roundTransitionController;
  late Animation<double> _roundSlideOut;
  late Animation<double> _roundSlideIn;
  late Animation<double> _roundFadeOut;
  late Animation<double> _roundFadeIn;
  int _displayedRoundNumber = 0;
  bool _showRoundLabel = false;
  late AnimationController _roundLabelController;
  late Animation<double> _roundLabelScale;

  // Score animation tracking
  Map<String, int> _previousScores = {};

  bool get _hasAnswered =>
      widget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;

  GameAnswer? get _myAnswer =>
      widget.currentRound?.playerAnswers[widget.currentUserId];

  bool get _isHost => widget.room.hostUserId == widget.currentUserId;

  int get _answeredCount =>
      widget.currentRound?.playerAnswers.length ?? 0;

  int get _totalPlayers => widget.room.players.length;

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

    // Feedback
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Score pop
    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scorePopOffset = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _scorePopController, curve: Curves.easeOut),
    );
    _scorePopOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_scorePopController);

    // Streak
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _streakScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.elasticOut),
    );

    // Round transition
    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _roundSlideOut = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _roundFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.0, 0.4),
      ),
    );
    _roundSlideIn = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _roundFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.5, 1.0),
      ),
    );

    // Round label
    _roundLabelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _roundLabelScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_roundLabelController);

    _displayedRoundNumber = widget.currentRound?.roundNumber ?? widget.room.currentRound;
    _previousScores = Map.from(widget.room.scores);
    _startRoundTimer();
  }

  @override
  void didUpdateWidget(TranslationRaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldRound = oldWidget.currentRound?.roundNumber;
    final newRound = widget.currentRound?.roundNumber;

    // New round detected
    if (oldRound != null && newRound != null && oldRound != newRound) {
      _onNewRound(newRound);
    }

    // Check if answer result came back
    final oldHasAnswered =
        oldWidget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;
    if (!oldHasAnswered && _hasAnswered && _myAnswer != null) {
      _onAnswerResult(_myAnswer!);
    }

    // Detect score changes for animation
    for (final player in widget.room.players) {
      final oldScore = _previousScores[player.userId] ?? 0;
      final newScore = widget.room.scores[player.userId] ?? 0;
      if (newScore > oldScore && player.userId == widget.currentUserId) {
        final delta = newScore - oldScore;
        _showPointsPop('+$delta pts');
      }
    }
    _previousScores = Map.from(widget.room.scores);

    // Auto-advance: all players answered
    if (_isHost &&
        !_advanceDispatched &&
        _answeredCount >= _totalPlayers &&
        _totalPlayers > 0) {
      _scheduleAdvanceRound();
    }
  }

  void _onNewRound(int roundNumber) {
    // Animate round transition
    _roundTransitionController.forward(from: 0);

    // Show round label
    setState(() {
      _showRoundLabel = true;
      _displayedRoundNumber = roundNumber;
      _selectedAnswer = null;
      _showFeedback = false;
      _revealCorrect = false;
      _advanceDispatched = false;
    });
    _roundLabelController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showRoundLabel = false);
    });

    _startRoundTimer();
  }

  void _onAnswerResult(GameAnswer answer) {
    setState(() => _showFeedback = true);
    _feedbackController.forward(from: 0);

    if (answer.isCorrect) {
      HapticFeedback.mediumImpact();
      setState(() => _correctStreak++);
      _streakController.forward(from: 0);

      // Check for speed bonus
      if (widget.currentRound != null) {
        final elapsed = answer.answeredAt
            .difference(widget.currentRound!.startedAt)
            .inMilliseconds;
        final durationMs = widget.room.turnDurationSeconds * 1000;
        if (elapsed < durationMs ~/ 4) {
          _showPointsPop('+${answer.pointsEarned} pts ⚡');
        }
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _correctStreak = 0);

      // Reveal correct answer after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _revealCorrect = true);
      });
    }
  }

  void _showPointsPop(String text) {
    setState(() {
      _showScorePop = true;
      _scorePopText = text;
    });
    _scorePopController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showScorePop = false);
    });
  }

  // ── Timer ──

  void _startRoundTimer() {
    _roundTimer?.cancel();
    _advanceDispatched = false;

    final round = widget.currentRound;
    if (round == null) {
      setState(() => _remainingSeconds = widget.room.turnDurationSeconds);
      return;
    }

    _computeRemaining();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    final round = widget.currentRound;
    if (round == null) return;

    final elapsed = DateTime.now().difference(round.startedAt).inSeconds;
    final remaining = (round.durationSeconds - elapsed)
        .clamp(0, round.durationSeconds);

    if (mounted) setState(() => _remainingSeconds = remaining);

    if (remaining <= 0 && _isHost && !_advanceDispatched) {
      _scheduleAdvanceRound();
    }
  }

  void _scheduleAdvanceRound() {
    _advanceDispatched = true;
    _roundTimer?.cancel();
    // Delay to let answer reveal show
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.read<LanguageGamesBloc>().add(
              AdvanceRound(roomId: widget.room.id),
            );
      }
    });
  }

  // ── Actions ──

  void _onOptionTapped(String answer) {
    if (_hasAnswered || _selectedAnswer != null) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = answer);
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: answer,
        ));
  }

  void _showAbandonDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.gameAbandonTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.gameAbandonLoseMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LanguageGamesBloc>().add(
                    LeaveRoom(
                        roomId: widget.room.id,
                        userId: widget.currentUserId),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.gameLeave,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _particleController.dispose();
    _pulseController.dispose();
    _feedbackController.dispose();
    _scorePopController.dispose();
    _streakController.dispose();
    _roundTransitionController.dispose();
    _roundLabelController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  String _languageDisplayName(String code, AppLocalizations l10n) {
    final names = {
      'it': l10n.gameLanguageItalian,
      'en': l10n.gameLanguageEnglish,
      'fr': l10n.gameLanguageFrench,
      'de': l10n.gameLanguageGerman,
      'pt': l10n.gameLanguagePortuguese,
      'pt-BR': l10n.gameLanguageBrazilianPortuguese,
      'es': l10n.gameLanguageSpanish,
      'ja': l10n.gameLanguageJapanese,
    };
    return names[code] ?? code.toUpperCase();
  }

  List<MapEntry<String, int>> get _sortedScores {
    final entries = widget.room.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int _playerPosition(String userId) {
    final sorted = _sortedScores;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].key == userId) return i + 1;
    }
    return sorted.length + 1;
  }

  String _positionBadge(int pos, AppLocalizations l10n) {
    switch (pos) {
      case 1:
        return l10n.gamePositionFirst;
      case 2:
        return l10n.gamePositionSecond;
      case 3:
        return l10n.gamePositionThird;
      default:
        return l10n.gamePositionNth(pos);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = widget.currentRound?.options ?? [];
    final prompt =
        widget.currentRound?.prompt ?? widget.room.currentPrompt ?? '...';
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} ${l10n.gameTranslationRaceTitle}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          // Round counter
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                l10n.gameTranslationRaceRoundShort(widget.room.currentRound, widget.room.totalRounds),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Timer
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: GameTimer(
                remainingSeconds: _remainingSeconds,
                totalSeconds: widget.room.turnDurationSeconds,
                size: 36,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app,
                color: AppColors.errorRed, size: 20),
            tooltip: l10n.gameAbandonTooltip,
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

          // Main content
          Column(
            children: [
              // Player score bars
              _buildScoreBars(l10n),

              const SizedBox(height: 8),

              // Streak badge
              if (_correctStreak >= 2) _buildStreakBadge(),

              // Word card + options (animated on round change)
              Expanded(
                child: AnimatedBuilder(
                  animation: _roundTransitionController,
                  builder: (context, child) {
                    final phase = _roundTransitionController.value;
                    final slide = phase < 0.5
                        ? _roundSlideOut.value
                        : _roundSlideIn.value;
                    final fade = phase < 0.5
                        ? _roundFadeOut.value
                        : _roundFadeIn.value;

                    return Transform.translate(
                      offset: Offset(slide * screenWidth, 0),
                      child: Opacity(
                        opacity: fade.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Prompt card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildPromptCard(prompt, l10n),
                      ),

                      const SizedBox(height: 16),

                      // 4x3 option grid
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildOptionsGrid(options, l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Waiting state OR goal label
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: _hasAnswered
                    ? _buildWaitingState(l10n)
                    : Text(
                        l10n.gameTranslationRaceFirstTo30,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),

          // Score pop overlay
          if (_showScorePop) _buildScorePopOverlay(),

          // Round label overlay
          if (_showRoundLabel) _buildRoundLabelOverlay(l10n),
        ],
      ),
    );
  }

  // ── Score bars ──

  Widget _buildScoreBars(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: widget.room.players.map((player) {
          final score = widget.room.scores[player.userId] ?? 0;
          final isMe = player.userId == widget.currentUserId;
          final position = _playerPosition(player.userId);
          final isLeader = position == 1 && score > 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // Position badge
                SizedBox(
                  width: 28,
                  child: score > 0
                      ? Text(
                          _positionBadge(position, l10n),
                          style: TextStyle(
                            color: isLeader
                                ? AppColors.richGold
                                : AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight:
                                isLeader ? FontWeight.bold : FontWeight.normal,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Name
                SizedBox(
                  width: 52,
                  child: Text(
                    isMe ? l10n.gameYou : player.displayName,
                    style: TextStyle(
                      color: isMe ? AppColors.richGold : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Animated progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: (score / 30).clamp(0.0, 1.0),
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isMe
                                        ? [
                                            AppColors.richGold
                                                .withValues(alpha: 0.7),
                                            AppColors.richGold,
                                          ]
                                        : [
                                            AppColors.textTertiary
                                                .withValues(alpha: 0.5),
                                            AppColors.textTertiary,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isLeader
                                      ? [
                                          BoxShadow(
                                            color: AppColors.richGold
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Animated score text
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score.toDouble()),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, _) {
                    return Text(
                      '${value.round()}/30',
                      style: TextStyle(
                        color: isMe ? AppColors.richGold : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Streak badge ──

  Widget _buildStreakBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedBuilder(
        animation: _streakScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _streakScale.value.clamp(0.0, 1.5),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.warningAmber.withValues(alpha: 0.5),
            ),
            boxShadow: _correctStreak >= 5
                ? [
                    BoxShadow(
                      color: AppColors.warningAmber.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            '\u{1F525} x$_correctStreak',
            style: const TextStyle(
              color: AppColors.warningAmber,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ── Prompt card ──

  Widget _buildPromptCard(String prompt, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.richGold
                .withValues(alpha: 0.3 + 0.3 * _pulseAnimation.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.richGold
                  .withValues(alpha: 0.08 + 0.1 * _pulseAnimation.value),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.gameTranslationRaceTranslateTo(_languageDisplayName(widget.room.targetLanguage, l10n)),
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
    );
  }

  // ── Options grid ──

  Widget _buildOptionsGrid(List<String> options, AppLocalizations l10n) {
    return GridView.builder(
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
        final correctAnswer = widget.currentRound?.correctAnswer;
        final isSelected = _selectedAnswer == option;
        final isCorrectOption = option == correctAnswer;
        final isWrongSelection = isSelected && _showFeedback && !isCorrectOption;
        final shouldRevealCorrect = _revealCorrect && isCorrectOption;

        Color bgColor = AppColors.backgroundCard;
        Color borderColor = AppColors.divider;
        Color textColor = AppColors.textPrimary;

        if (_showFeedback && isSelected && isCorrectOption) {
          // Selected and correct
          bgColor = AppColors.successGreen.withValues(alpha: 0.2);
          borderColor = AppColors.successGreen;
          textColor = AppColors.successGreen;
        } else if (isWrongSelection) {
          // Selected and wrong
          bgColor = AppColors.errorRed.withValues(alpha: 0.2);
          borderColor = AppColors.errorRed;
          textColor = AppColors.errorRed;
        } else if (shouldRevealCorrect) {
          // Reveal correct after wrong answer
          bgColor = AppColors.successGreen.withValues(alpha: 0.15);
          borderColor = AppColors.successGreen;
          textColor = AppColors.successGreen;
        } else if (_hasAnswered) {
          bgColor = AppColors.backgroundCard.withValues(alpha: 0.5);
          textColor = AppColors.textTertiary;
        }

        return GestureDetector(
          onTap: () => _onOptionTapped(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
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
                if (shouldRevealCorrect)
                  Text(
                    l10n.gameTranslationRaceCheckCorrect,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Waiting state ──

  Widget _buildWaitingState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.gameTranslationRaceWaitingForOthers(_answeredCount, _totalPlayers),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Score pop overlay ──

  Widget _buildScorePopOverlay() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scorePopOffset, _scorePopOpacity]),
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, _scorePopOffset.value),
            child: Opacity(
              opacity: _scorePopOpacity.value.clamp(0.0, 1.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _scorePopText,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Round label overlay ──

  Widget _buildRoundLabelOverlay(AppLocalizations l10n) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _roundLabelScale,
            builder: (context, _) {
              return Transform.scale(
                scale: _roundLabelScale.value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    l10n.gameRoundNumber(_displayedRoundNumber),
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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

      final xOffset =
          ((progress * speed + phase / 6.28) % 1.0) * (size.width + length);
      final dy =
          math.sin(progress * math.pi * 2 * speed * 0.3 + phase) * 4;
      final opacity =
          (0.04 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0),
            AppColors.richGold.withValues(alpha: opacity),
          ],
        ).createShader(
            Rect.fromLTWH(xOffset - length, baseY + dy, length, 2));

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
      final dy =
          math.cos(progress * math.pi * 2 * speed * 0.5 + phase) * 4;
      final opacity =
          (0.03 + 0.03 * math.sin(progress * math.pi * 2 * speed + phase))
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
