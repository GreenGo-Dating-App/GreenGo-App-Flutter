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
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';

/// Picture Guess game screen — fully enhanced
/// One player describes a word, others try to guess it.
/// Describer submits clues via SubmitClue; guessers submit guesses via SubmitAnswer.
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
  // ── Animation controllers ──
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _roleGlowController;
  late Animation<double> _roleGlowAnimation;
  late AnimationController _roundTransitionController;
  late Animation<double> _roundSlideOut;
  late Animation<double> _roundSlideIn;
  late AnimationController _scorePopController;

  // ── Timer ──
  Timer? _timer;
  int _remainingSeconds = 60;

  // ── Local state ──
  int _guessAttempts = 0;
  static const int _maxAttempts = 3;
  int _previousClueCount = 0;
  int _lastRoundNumber = -1;
  bool _showRoundTransition = false;
  bool _showAnswerReveal = false;
  bool _roundAdvanceDispatched = false;
  bool _showScorePop = false;
  String _scorePopText = '';
  Map<String, int> _previousScores = {};

  bool get _isDescriber =>
      widget.room.currentDescriberId == widget.currentUserId;
  bool get _isHost => widget.room.hostUserId == widget.currentUserId;

  bool get _hasGuessedCorrectly {
    final answer =
        widget.currentRound?.playerAnswers[widget.currentUserId];
    return answer != null && answer.isCorrect;
  }

  bool get _isGuessLocked =>
      _hasGuessedCorrectly || _guessAttempts >= _maxAttempts;

  List<String> get _clues => widget.currentRound?.clues ?? [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimer();
    _lastRoundNumber = widget.room.currentRound;
    _previousScores = Map.from(widget.room.scores);
    _previousClueCount = _clues.length;
  }

  void _initAnimations() {
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

    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _roundSlideOut = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _roundSlideIn = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _particleController.dispose();
    _pulseController.dispose();
    _roleGlowController.dispose();
    _roundTransitionController.dispose();
    _scorePopController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PictureGuessScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── New round detected ──
    if (widget.room.currentRound != _lastRoundNumber) {
      _lastRoundNumber = widget.room.currentRound;
      _guessAttempts = 0;
      _showAnswerReveal = false;
      _roundAdvanceDispatched = false;
      _previousClueCount = 0;
      _restartTimer();
      _triggerRoundTransition();
    }

    // ── New clue arrived ──
    final currentClueCount = _clues.length;
    if (currentClueCount > _previousClueCount && !_isDescriber) {
      HapticFeedback.lightImpact();
    }
    _previousClueCount = currentClueCount;

    // ── Score change detected → pop animation ──
    _checkScoreChanges();

    // ── Check if all guessers answered correctly → auto-advance ──
    _checkAutoAdvance();
  }

  // ── Timer logic ──

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

  void _restartTimer() {
    _startTimer();
  }

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
    setState(() {
      _showAnswerReveal = true;
      _roundAdvanceDispatched = true;
    });
    HapticFeedback.heavyImpact();

    // Delay then advance (host only)
    if (_isHost) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.read<LanguageGamesBloc>().add(
                AdvanceRound(roomId: widget.room.id),
              );
        }
      });
    }
  }

  void _checkAutoAdvance() {
    if (_roundAdvanceDispatched || widget.currentRound == null) return;

    final guessers = widget.room.players
        .where((p) => p.userId != widget.room.currentDescriberId)
        .toList();

    final allAnsweredCorrectly = guessers.every((p) {
      final answer = widget.currentRound!.playerAnswers[p.userId];
      return answer != null && answer.isCorrect;
    });

    if (allAnsweredCorrectly && guessers.isNotEmpty) {
      setState(() {
        _showAnswerReveal = true;
        _roundAdvanceDispatched = true;
      });
      HapticFeedback.mediumImpact();

      if (_isHost) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.read<LanguageGamesBloc>().add(
                  AdvanceRound(roomId: widget.room.id),
                );
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
        _triggerScorePop('+$diff pts');
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
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showRoundTransition = false);
    });
  }

  // ── Clue submission (describer) ──

  void _submitClue(String clue) {
    final secretWord =
        widget.currentRound?.prompt ?? widget.room.currentPrompt ?? '';

    // Prevent using the secret word in the clue
    if (secretWord.isNotEmpty &&
        clue.toLowerCase().contains(secretWord.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.gamePictureGuessCantUseWord),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    context.read<LanguageGamesBloc>().add(SubmitClue(
          roomId: widget.room.id,
          clue: clue,
        ));
  }

  // ── Guess submission (guesser) ──

  void _submitGuess(String guess) {
    if (_isGuessLocked) return;

    HapticFeedback.mediumImpact();
    setState(() => _guessAttempts++);

    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: guess,
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
          '${widget.room.gameType.emoji} ${l10n.gamePictureGuessTitle}',
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
          // Particle background
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

          // Main content
          AnimatedBuilder(
            animation: _roundTransitionController,
            builder: (context, child) {
              final slideValue = _showRoundTransition
                  ? (_roundTransitionController.value < 0.4
                      ? _roundSlideOut.value
                      : _roundSlideIn.value)
                  : 0.0;
              return Transform.translate(
                offset: Offset(
                    slideValue * MediaQuery.of(context).size.width, 0),
                child: child,
              );
            },
            child: Column(
              children: [
                // Player avatars with roles + scores
                _buildPlayerBar(),

                const SizedBox(height: 8),

                // Role indicator
                _buildRoleIndicator(),

                const SizedBox(height: 12),

                // Main content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isDescriber
                        ? _buildDescriberView()
                        : _buildGuesserView(),
                  ),
                ),

                // Score bar
                _buildScoreBar(),

                // Input area
                _buildInput(),
              ],
            ),
          ),

          // Round transition overlay
          if (_showRoundTransition) _buildRoundOverlay(),

          // Answer reveal overlay
          if (_showAnswerReveal) _buildAnswerReveal(),

          // Score pop
          if (_showScorePop) _buildScorePop(),
        ],
      ),
    );
  }

  // ── Player bar ──

  Widget _buildPlayerBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.room.players.map((player) {
          final isDescriber =
              widget.room.currentDescriberId == player.userId;
          final score = widget.room.scores[player.userId] ?? 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  PlayerAvatarCircle(
                    player: player,
                    isCurrentTurn: isDescriber,
                    isCurrentUser:
                        player.userId == widget.currentUserId,
                    showScore: false,
                    size: 36,
                  ),
                  if (isDescriber)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.richGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$score',
                style: TextStyle(
                  color: isDescriber
                      ? AppColors.richGold
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isDescriber)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.gamePictureGuessDescriber,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Role indicator ──

  Widget _buildRoleIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _roleGlowAnimation,
      builder: (context, child) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ? l10n.gamePictureGuessYouAreDescriber
              : _isGuessLocked
                  ? l10n.gamePictureGuessWaitingForOthers
                  : l10n.gamePictureGuessGuessTheWord,
          style: TextStyle(
            color: _isDescriber
                ? AppColors.richGold
                : AppColors.infoBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Describer view ──

  Widget _buildDescriberView() {
    final l10n = AppLocalizations.of(context)!;
    final wordToDescribe =
        widget.currentRound?.prompt ?? widget.room.currentPrompt ?? '...';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            l10n.gamePictureGuessYourWord,
            style: const TextStyle(
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

          const SizedBox(height: 12),

          // Rules reminder
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.gamePictureGuessDescriberRules,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Clues sent so far
          if (_clues.isNotEmpty) ...[
            Text(
              l10n.gamePictureGuessCluesSent(_clues.length),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _clues.asMap().entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${e.key + 1}. ${e.value}',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          _buildGuessingProgress(),
        ],
      ),
    );
  }

  // ── Guesser view ──

  Widget _buildGuesserView() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            l10n.gamePictureGuessClues,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Clues area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
            ),
            child: _clues.isEmpty
                ? _buildWaitingForClues()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _clues.asMap().entries.map((entry) {
                      final isNew = entry.key >= _previousClueCount - 1 &&
                          _previousClueCount > 0;
                      return AnimatedScale(
                        scale: 1.0,
                        duration: Duration(
                            milliseconds: isNew ? 400 : 0),
                        curve: Curves.elasticOut,
                        child: Container(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${entry.key + 1}.',
                                style: TextStyle(
                                  color: AppColors.infoBlue
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 12),

          // Guess feedback
          if (_hasGuessedCorrectly) _buildGuessFeedback(true),
          if (!_hasGuessedCorrectly && _guessAttempts > 0)
            _buildGuessFeedback(false),

          // Attempt counter
          if (!_isGuessLocked && !_hasGuessedCorrectly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.gamePictureGuessAttemptCounter(_guessAttempts + 1, _maxAttempts),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),

          if (_isGuessLocked && !_hasGuessedCorrectly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.gamePictureGuessNoMoreAttempts,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
          _buildGuessingProgress(),
        ],
      ),
    );
  }

  Widget _buildWaitingForClues() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gamePictureGuessWaitingForClues,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessFeedback(bool isCorrect) {
    final l10n = AppLocalizations.of(context)!;
    final answer =
        widget.currentRound?.playerAnswers[widget.currentUserId];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.successGreen.withValues(alpha: 0.15)
            : AppColors.errorRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.successGreen.withValues(alpha: 0.4)
              : AppColors.errorRed.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? AppColors.successGreen : AppColors.errorRed)
                .withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppColors.successGreen : AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isCorrect
                ? l10n.gamePictureGuessCorrectPoints(answer?.pointsEarned ?? 10)
                : l10n.gamePictureGuessWrongGuess(answer?.answer ?? ''),
            style: TextStyle(
              color:
                  isCorrect ? AppColors.successGreen : AppColors.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessingProgress() {
    final l10n = AppLocalizations.of(context)!;
    final guessers = widget.room.players
        .where((p) => p.userId != widget.room.currentDescriberId)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: guessers.map((player) {
        final answer =
            widget.currentRound?.playerAnswers[player.userId];
        final hasGuessed = answer != null;
        final isCorrect = answer?.isCorrect ?? false;
        final isMe = player.userId == widget.currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
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
              const SizedBox(height: 3),
              Text(
                isMe ? l10n.gameYou : player.displayName,
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

  // ── Score bar ──

  Widget _buildScoreBar() {
    final l10n = AppLocalizations.of(context)!;
    final sortedPlayers = [...widget.room.players]
      ..sort((a, b) =>
          (widget.room.scores[b.userId] ?? 0)
              .compareTo(widget.room.scores[a.userId] ?? 0));

    final maxScore = sortedPlayers.isEmpty
        ? 1
        : (widget.room.scores[sortedPlayers.first.userId] ?? 1)
            .clamp(1, 99999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: sortedPlayers.asMap().entries.map((entry) {
          final idx = entry.key;
          final player = entry.value;
          final score = widget.room.scores[player.userId] ?? 0;
          final ratio = score / maxScore;
          final isDescriber =
              widget.room.currentDescriberId == player.userId;
          final isMe = player.userId == widget.currentUserId;
          final badges = [l10n.gamePositionFirst, l10n.gamePositionSecond, l10n.gamePositionThird];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    idx < 3 ? badges[idx] : l10n.gamePositionNth(idx + 1),
                    style: TextStyle(
                      color: idx == 0
                          ? AppColors.richGold
                          : AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDescriber)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.richGold, size: 12),
                  ),
                SizedBox(
                  width: 50,
                  child: Text(
                    isMe ? l10n.gameYou : player.displayName,
                    style: TextStyle(
                      color: isMe
                          ? AppColors.richGold
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight:
                          isMe ? FontWeight.bold : FontWeight.normal,
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
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: idx == 0
                                  ? [
                                      AppColors.richGold,
                                      AppColors.richGold
                                          .withValues(alpha: 0.7),
                                    ]
                                  : [
                                      AppColors.infoBlue,
                                      AppColors.infoBlue
                                          .withValues(alpha: 0.7),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: idx == 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.richGold
                                          .withValues(alpha: 0.3),
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
                  width: 28,
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: isMe
                          ? AppColors.richGold
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Input ──

  Widget _buildInput() {
    final l10n = AppLocalizations.of(context)!;
    if (_isDescriber) {
      return AnswerInput(
        hintText: l10n.gamePictureGuessTypeClueHint,
        enabled: !_showAnswerReveal,
        onSubmitted: _submitClue,
      );
    }

    String hint;
    if (_hasGuessedCorrectly) {
      hint = l10n.gamePictureGuessCorrectWaiting;
    } else if (_guessAttempts >= _maxAttempts) {
      hint = l10n.gamePictureGuessNoMoreAttemptsRound;
    } else {
      hint = l10n.gamePictureGuessTypeGuessHint(_guessAttempts + 1, _maxAttempts);
    }

    return AnswerInput(
      hintText: hint,
      enabled: !_isGuessLocked && !_showAnswerReveal,
      onSubmitted: _submitGuess,
    );
  }

  // ── Overlays ──

  Widget _buildRoundOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _roundTransitionController,
      builder: (context, _) {
        final scale = Curves.elasticOut
            .transform(_roundTransitionController.value.clamp(0, 1));
        final opacity =
            (_roundTransitionController.value < 0.8) ? 1.0 :
            (1.0 - ((_roundTransitionController.value - 0.8) / 0.2)).clamp(0.0, 1.0);

        return IgnorePointer(
          child: Container(
            color: AppColors.backgroundDark.withValues(alpha: 0.85 * opacity),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Text(
                        l10n.gameRoundNumber(widget.room.currentRound),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Transform.scale(
                      scale: scale * 0.8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isDescriber
                              ? AppColors.richGold.withValues(alpha: 0.2)
                              : AppColors.infoBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isDescriber
                                ? AppColors.richGold
                                : AppColors.infoBlue,
                          ),
                        ),
                        child: Text(
                          _isDescriber
                              ? l10n.gamePictureGuessYouAreDescriber
                              : l10n.gamePictureGuessGuessTheWordUpper,
                          style: TextStyle(
                            color: _isDescriber
                                ? AppColors.richGold
                                : AppColors.infoBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerReveal() {
    final l10n = AppLocalizations.of(context)!;
    final correctWord =
        widget.currentRound?.correctAnswer ??
        widget.currentRound?.prompt ??
        widget.room.currentPrompt ??
        '';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: child,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.richGold.withValues(alpha: 0.9),
                  AppColors.richGold.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.gamePictureGuessTheWordWas,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  correctWord,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScorePop() {
    return AnimatedBuilder(
      animation: _scorePopController,
      builder: (context, _) {
        final progress = _scorePopController.value;
        final opacity = progress < 0.7 ? 1.0 : (1.0 - ((progress - 0.7) / 0.3));
        final yOffset = -60 * progress;

        return Positioned(
          top: MediaQuery.of(context).size.height * 0.35 + yOffset,
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

      final color = i % 2 == 0 ? AppColors.richGold : AppColors.infoBlue;

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );

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
