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
import '../widgets/player_avatar_circle.dart';

/// Grammar Duel game screen — fully enhanced 1v1 grammar battle
/// Two players race to answer grammar questions with 4 multiple-choice options.
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
  // ── Animation controllers ──
  late AnimationController _particleController;
  late AnimationController _vsGlowController;
  late Animation<double> _vsGlowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _roundTransitionController;
  late AnimationController _scorePopController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  // ── Timer ──
  Timer? _timer;
  int _remainingSeconds = 15;

  // ── Local state ──
  int _lastRoundNumber = -1;
  bool _showRoundTransition = false;
  bool _roundAdvanceDispatched = false;
  int _correctStreak = 0;
  bool _showScorePop = false;
  String _scorePopText = '';
  Map<String, int> _previousScores = {};
  String? _selectedOption;
  bool _showFeedback = false;

  bool get _hasAnswered =>
      widget.currentRound?.hasPlayerAnswered(widget.currentUserId) ?? false;
  bool get _isHost => widget.room.hostUserId == widget.currentUserId;

  GameAnswer? get _myAnswer =>
      widget.currentRound?.playerAnswers[widget.currentUserId];

  String? get _opponentId {
    for (final p in widget.room.players) {
      if (p.userId != widget.currentUserId) return p.userId;
    }
    return null;
  }

  bool get _opponentAnswered =>
      _opponentId != null &&
      (widget.currentRound?.hasPlayerAnswered(_opponentId!) ?? false);

  bool get _bothAnswered => _hasAnswered && _opponentAnswered;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimer();
    _lastRoundNumber = widget.room.currentRound;
    _previousScores = Map.from(widget.room.scores);
  }

  void _initAnimations() {
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

    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _particleController.dispose();
    _vsGlowController.dispose();
    _pulseController.dispose();
    _roundTransitionController.dispose();
    _scorePopController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrammarDuelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── New round detected ──
    if (widget.room.currentRound != _lastRoundNumber) {
      _lastRoundNumber = widget.room.currentRound;
      _roundAdvanceDispatched = false;
      _selectedOption = null;
      _showFeedback = false;
      _restartTimer();
      _triggerRoundTransition();
    }

    // ── Answer result arrived (for streak tracking) ──
    final myAnswer = _myAnswer;
    if (myAnswer != null && !_showFeedback) {
      setState(() => _showFeedback = true);
      _feedbackController.forward(from: 0);
      if (myAnswer.isCorrect) {
        _correctStreak++;
        HapticFeedback.mediumImpact();
      } else {
        _correctStreak = 0;
        HapticFeedback.heavyImpact();
      }
    }

    // ── Score change ──
    _checkScoreChanges();

    // ── Both answered → auto-advance ──
    _checkAutoAdvance();
  }

  // ── Timer ──

  void _startTimer() {
    _timer?.cancel();
    _updateRemainingSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingSeconds();
      if (_remainingSeconds <= 0 && !_roundAdvanceDispatched) {
        _onRoundTimeUp();
      }
    });
  }

  void _restartTimer() => _startTimer();

  void _updateRemainingSeconds() {
    if (widget.currentRound == null) return;
    final elapsed =
        DateTime.now().difference(widget.currentRound!.startedAt).inSeconds;
    final remaining =
        (widget.currentRound!.durationSeconds - elapsed).clamp(0, 9999);
    if (remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  void _onRoundTimeUp() {
    if (_roundAdvanceDispatched) return;
    setState(() => _roundAdvanceDispatched = true);
    HapticFeedback.heavyImpact();

    if (_isHost) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          context
              .read<LanguageGamesBloc>()
              .add(AdvanceRound(roomId: widget.room.id));
        }
      });
    }
  }

  void _checkAutoAdvance() {
    if (_roundAdvanceDispatched) return;
    if (_bothAnswered) {
      setState(() => _roundAdvanceDispatched = true);

      if (_isHost) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context
                .read<LanguageGamesBloc>()
                .add(AdvanceRound(roomId: widget.room.id));
          }
        });
      }
    }
  }

  void _checkScoreChanges() {
    for (final entry in widget.room.scores.entries) {
      final prev = _previousScores[entry.key] ?? 0;
      if (entry.value > prev && entry.key == widget.currentUserId) {
        final diff = entry.value - prev;
        // Check if speed bonus was awarded
        final wasfast = diff > 10;
        _triggerScorePop(wasfast ? '⚡ +$diff' : '+$diff pts');
      }
    }
    _previousScores = Map.from(widget.room.scores);
  }

  void _triggerScorePop(String text) {
    setState(() {
      _showScorePop = true;
      _scorePopText = text;
    });
    _scorePopController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showScorePop = false);
    });
  }

  void _triggerRoundTransition() {
    setState(() => _showRoundTransition = true);
    _roundTransitionController.forward(from: 0);
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showRoundTransition = false);
    });
  }

  void _submitAnswer(String option) {
    if (_hasAnswered) return;
    setState(() => _selectedOption = option);
    HapticFeedback.lightImpact();
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: option,
        ));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} ${l10n.gameGrammarDuelTitle}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (widget.currentRound != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GameTimer(
                remainingSeconds: _remainingSeconds,
                totalSeconds: widget.currentRound!.durationSeconds,
                size: 38,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
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

          // Main content
          Column(
            children: [
              // VS Layout
              _buildVsLayout(),

              // Score comparison bars
              _buildScoreBars(),

              const SizedBox(height: 8),

              // Streak badge
              if (_correctStreak >= 2) _buildStreakBadge(),

              const SizedBox(height: 8),

              // Question + options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Question text
                      _buildQuestionCard(),
                      const SizedBox(height: 16),
                      // Options grid
                      if (widget.currentRound != null &&
                          widget.currentRound!.options.isNotEmpty)
                        _buildOptionsGrid(),
                      // Answer status
                      if (_hasAnswered) ...[
                        const SizedBox(height: 12),
                        _buildAnswerStatus(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),

          // Round transition overlay
          if (_showRoundTransition) _buildRoundOverlay(),

          // Score pop
          if (_showScorePop) _buildScorePop(),
        ],
      ),
    );
  }

  // ── VS Layout ──

  Widget _buildVsLayout() {
    final l10n = AppLocalizations.of(context)!;
    final player1 =
        widget.room.players.isNotEmpty ? widget.room.players[0] : null;
    final player2 =
        widget.room.players.length > 1 ? widget.room.players[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (player1 != null)
            Expanded(child: _buildPlayerSide(player1)),
          // VS badge
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
              child: Text(
                l10n.gameGrammarDuelVersus,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (player2 != null)
            Expanded(child: _buildPlayerSide(player2)),
        ],
      ),
    );
  }

  Widget _buildPlayerSide(dynamic player) {
    final l10n = AppLocalizations.of(context)!;
    final hasAnswered =
        widget.currentRound?.hasPlayerAnswered(player.userId) ?? false;
    final isMe = player.userId == widget.currentUserId;
    final answer = widget.currentRound?.playerAnswers[player.userId];
    final showResult = _bothAnswered || _remainingSeconds <= 0;

    return Column(
      children: [
        PlayerAvatarCircle(
          player: player,
          isCurrentUser: isMe,
          showScore: false,
          size: 36,
        ),
        const SizedBox(height: 4),
        // Status indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: !hasAnswered
                ? AppColors.divider.withValues(alpha: 0.3)
                : showResult
                    ? (answer?.isCorrect ?? false)
                        ? AppColors.successGreen.withValues(alpha: 0.2)
                        : AppColors.errorRed.withValues(alpha: 0.2)
                    : AppColors.successGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: hasAnswered
                ? [
                    BoxShadow(
                      color: (showResult
                              ? (answer?.isCorrect ?? false)
                                  ? AppColors.successGreen
                                  : AppColors.errorRed
                              : AppColors.successGreen)
                          .withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasAnswered && showResult)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    (answer?.isCorrect ?? false)
                        ? Icons.check
                        : Icons.close,
                    size: 10,
                    color: (answer?.isCorrect ?? false)
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              Text(
                !hasAnswered
                    ? l10n.gameGrammarDuelThinking
                    : showResult
                        ? (answer?.isCorrect ?? false)
                            ? l10n.gameCorrect
                            : l10n.gameWrong
                        : l10n.gameGrammarDuelAnswered,
                style: TextStyle(
                  color: !hasAnswered
                      ? AppColors.textTertiary
                      : showResult
                          ? (answer?.isCorrect ?? false)
                              ? AppColors.successGreen
                              : AppColors.errorRed
                          : AppColors.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Score comparison bars ──

  Widget _buildScoreBars() {
    final l10n = AppLocalizations.of(context)!;
    final player1 =
        widget.room.players.isNotEmpty ? widget.room.players[0] : null;
    final player2 =
        widget.room.players.length > 1 ? widget.room.players[1] : null;
    if (player1 == null || player2 == null) return const SizedBox.shrink();

    final score1 = widget.room.scores[player1.userId] ?? 0;
    final score2 = widget.room.scores[player2.userId] ?? 0;
    final maxScore = math.max(score1, score2).clamp(1, 99999);
    final isMe1 = player1.userId == widget.currentUserId;
    final diff = isMe1 ? score1 - score2 : score2 - score1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Player 1 bar
          _buildSingleScoreBar(
            name: isMe1 ? l10n.gameYou : player1.displayName,
            score: score1,
            maxScore: maxScore,
            isLeader: score1 >= score2,
            isMe: isMe1,
          ),
          const SizedBox(height: 4),
          // Player 2 bar
          _buildSingleScoreBar(
            name: !isMe1 ? l10n.gameYou : player2.displayName,
            score: score2,
            maxScore: maxScore,
            isLeader: score2 > score1,
            isMe: !isMe1,
          ),
          // Difference indicator
          if (diff != 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                diff > 0 ? l10n.gameGrammarDuelAheadBy(diff) : l10n.gameGrammarDuelBehindBy(diff.abs()),
                style: TextStyle(
                  color: diff > 0
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleScoreBar({
    required String name,
    required int score,
    required int maxScore,
    required bool isLeader,
    required bool isMe,
  }) {
    final ratio = score / maxScore;
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            name,
            style: TextStyle(
              color: isMe ? AppColors.richGold : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, _) => Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.02, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLeader
                          ? [
                              AppColors.richGold,
                              AppColors.richGold.withValues(alpha: 0.7),
                            ]
                          : [
                              AppColors.infoBlue,
                              AppColors.infoBlue.withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isLeader
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.richGold.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Text(
            '$score',
            style: TextStyle(
              color: isMe ? AppColors.richGold : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Streak badge ──

  Widget _buildStreakBadge() {
    final l10n = AppLocalizations.of(context)!;
    final isHot = _correctStreak >= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.4),
        ),
        boxShadow: isHot
            ? [
                BoxShadow(
                  color: AppColors.warningAmber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            l10n.gameGrammarDuelStreakCount(_correctStreak),
            style: TextStyle(
              color: AppColors.warningAmber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: isHot
                  ? [
                      Shadow(
                        color: AppColors.warningAmber.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ──

  Widget _buildQuestionCard() {
    return AnimatedBuilder(
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Options grid ──

  Widget _buildOptionsGrid() {
    final options = widget.currentRound!.options;
    final correctAnswer = widget.currentRound?.correctAnswer;
    final showCorrect = _hasAnswered;

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
          final isSelected = _selectedOption == option ||
              _myAnswer?.answer == option;
          final isCorrectOption =
              showCorrect && correctAnswer != null && option == correctAnswer;
          final isWrongSelection =
              isSelected && !(_myAnswer?.isCorrect ?? false);
          final label = String.fromCharCode(65 + index);

          Color bgColor;
          Color borderColor;
          Color textColor;

          if (showCorrect) {
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
              borderColor = AppColors.divider.withValues(alpha: 0.3);
              textColor = AppColors.textTertiary;
            }
          } else if (isSelected) {
            bgColor = AppColors.infoBlue.withValues(alpha: 0.15);
            borderColor = AppColors.infoBlue;
            textColor = AppColors.infoBlue;
          } else {
            bgColor = AppColors.backgroundCard;
            borderColor = AppColors.divider;
            textColor = AppColors.textPrimary;
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasAnswered ? null : () => _submitAnswer(option),
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
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
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
                          fontSize: 13,
                          fontWeight: isSelected || isCorrectOption
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showCorrect &&
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
                          size: 16,
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

  // ── Answer status ──

  Widget _buildAnswerStatus() {
    final l10n = AppLocalizations.of(context)!;
    final answer = _myAnswer;
    if (answer == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _feedbackScale,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  ? l10n.gameGrammarDuelPlusPoints(answer.pointsEarned)
                  : l10n.gameGrammarDuelWrongAnswer,
              style: TextStyle(
                color: answer.isCorrect
                    ? AppColors.successGreen
                    : AppColors.errorRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Speed bonus badge
            if (answer.isCorrect && answer.pointsEarned > 10) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      AppColors.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(
                      l10n.gameGrammarDuelFast,
                      style: const TextStyle(
                        color: AppColors.warningAmber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Round transition overlay ──

  Widget _buildRoundOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _roundTransitionController,
      builder: (context, _) {
        final scale = Curves.elasticOut
            .transform(_roundTransitionController.value.clamp(0, 1));
        final opacity = (_roundTransitionController.value < 0.75)
            ? 1.0
            : (1.0 -
                    ((_roundTransitionController.value - 0.75) / 0.25))
                .clamp(0.0, 1.0);

        return IgnorePointer(
          child: Container(
            color: AppColors.backgroundDark
                .withValues(alpha: 0.85 * opacity),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.gameRoundNumber(widget.room.currentRound),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '⚔️',
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Score pop ──

  Widget _buildScorePop() {
    return AnimatedBuilder(
      animation: _scorePopController,
      builder: (context, _) {
        final progress = _scorePopController.value;
        final opacity =
            progress < 0.7 ? 1.0 : (1.0 - ((progress - 0.7) / 0.3));
        final yOffset = -60 * progress;

        return Positioned(
          top: MediaQuery.of(context).size.height * 0.4 + yOffset,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  _scorePopText,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppColors.richGold,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

    for (int i = 0; i < 12; i++) {
      final hash = (seed * 13 + i * 39) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 321) % 1000) / 1000.0 * size.height;
      final speed = 0.2 + (hash % 100) / 100.0 * 0.4;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 6;
      final dy =
          math.cos(progress * math.pi * 2 * speed * 0.5 + phase) * 4;
      final opacity = (0.03 +
              0.03 *
                  math.sin(progress * math.pi * 2 * speed + phase))
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
