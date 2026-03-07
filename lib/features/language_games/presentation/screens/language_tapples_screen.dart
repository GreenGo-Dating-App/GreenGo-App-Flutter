import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/content/game_content.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../widgets/answer_input.dart';
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';
import '../widgets/tapples_letter_wheel.dart';

/// Language Tapples — word category game with letter constraints.
/// Players take turns picking a letter, then naming a word in the current
/// category starting with that letter. Lives-based (3 lives), 10 pts per word.
class LanguageTapplesScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const LanguageTapplesScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<LanguageTapplesScreen> createState() => _LanguageTapplesScreenState();
}

class _LanguageTapplesScreenState extends State<LanguageTapplesScreen>
    with TickerProviderStateMixin {
  // ── Letter selection ──
  String? _selectedLetter;

  // ── Timer ──
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _hasTimedOut = false;

  // ── Feedback ──
  bool _showFeedback = false;
  bool _feedbackCorrect = false;
  String _feedbackText = '';
  bool _hasSubmittedThisTurn = false;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  // ── Turn transition ──
  bool _showTurnTransition = false;
  String _turnTransitionText = '';
  String _turnTransitionSub = '';
  String? _previousTurnUserId;
  late AnimationController _turnTransitionController;
  late Animation<double> _turnTransitionScale;

  // ── Life lost ──
  bool _showLifeLost = false;
  String _lifeLostPlayerName = '';
  late AnimationController _lifeLostController;
  late Animation<double> _lifeLostScale;

  // ── Score pop ──
  bool _showScorePop = false;
  String _scorePopText = '';
  Map<String, int> _previousScores = {};

  // ── Particle background ──
  late AnimationController _particleController;

  // ── Category glow ──
  late AnimationController _categoryGlowController;
  late Animation<double> _categoryGlowAnimation;

  bool get _isMyTurn => widget.room.currentTurnUserId == widget.currentUserId;
  bool get _isHost => widget.room.isHost(widget.currentUserId);

  String _category(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return widget.room.roundTheme ?? l10n.gameCategoryAnimals;
  }
  String _categoryIcon(BuildContext context) => GameContent.getTapplesCategoryIcon(_category(context));

  /// Derive used letters from words already submitted this round.
  Set<String> get _usedLetters {
    final letters = <String>{};
    for (final word in widget.room.usedWords) {
      if (word.isNotEmpty) {
        letters.add(word[0].toUpperCase());
      }
    }
    return letters;
  }

  @override
  void initState() {
    super.initState();

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Feedback
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    // Turn transition
    _turnTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _turnTransitionScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _turnTransitionController, curve: Curves.elasticOut),
    );

    // Life lost
    _lifeLostController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lifeLostScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lifeLostController, curve: Curves.easeOutBack),
    );

    // Category glow
    _categoryGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _categoryGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _categoryGlowController, curve: Curves.easeInOut),
    );

    _previousScores = Map.from(widget.room.scores);
    _previousTurnUserId = widget.room.currentTurnUserId;

    _startTimer();
  }

  @override
  void didUpdateWidget(covariant LanguageTapplesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect turn change
    if (widget.room.currentTurnUserId != oldWidget.room.currentTurnUserId) {
      _hasTimedOut = false;
      _hasSubmittedThisTurn = false;
      _selectedLetter = null;
      _startTimer();

      if (_previousTurnUserId != null &&
          _previousTurnUserId != widget.room.currentTurnUserId) {
        _showTurnTransitionOverlay();
      }
      _previousTurnUserId = widget.room.currentTurnUserId;
    }

    // Detect score change
    final newScores = widget.room.scores;
    final myOldScore = _previousScores[widget.currentUserId] ?? 0;
    final myNewScore = newScores[widget.currentUserId] ?? 0;
    if (myNewScore > myOldScore) {
      _showScorePopOverlay('+${myNewScore - myOldScore}');
    }
    _previousScores = Map.from(newScores);

    // Detect life lost
    for (final player in widget.room.players) {
      final oldPlayer = oldWidget.room.getPlayer(player.userId);
      if (oldPlayer != null && player.lives < oldPlayer.lives) {
        final l10n = AppLocalizations.of(context)!;
        _showLifeLostOverlay(
          player.userId == widget.currentUserId
              ? l10n.gameYou
              : player.displayName,
        );
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = widget.room.turnDurationSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final startedAt = widget.room.turnStartedAt;
      if (startedAt == null) {
        setState(() => _remainingSeconds = widget.room.turnDurationSeconds);
        return;
      }

      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      final remaining =
          (widget.room.turnDurationSeconds - elapsed).clamp(0, 999);

      setState(() => _remainingSeconds = remaining);

      if (remaining <= 0 && !_hasTimedOut) {
        _hasTimedOut = true;
        _countdownTimer?.cancel();
        HapticFeedback.heavyImpact();

        if (_isHost) {
          final timedOutUserId = widget.room.currentTurnUserId;
          if (timedOutUserId != null) {
            context.read<LanguageGamesBloc>().add(
                  TapplesTimeout(
                    roomId: widget.room.id,
                    userId: timedOutUserId,
                  ),
                );
          }
        }
      }
    });
  }

  void _onLetterSelected(String letter) {
    setState(() => _selectedLetter = letter);
  }

  void _onSubmitAnswer(String answer) {
    if (!_isMyTurn || _hasSubmittedThisTurn || _selectedLetter == null) return;

    final trimmed = answer.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    // Client-side: must start with selected letter
    final l10n = AppLocalizations.of(context)!;
    if (!trimmed.startsWith(_selectedLetter!.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gameWordMustStartWith(_selectedLetter!)),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Client-side: not already used
    if (widget.room.usedWords.any((w) => w.toLowerCase() == trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gameWordAlreadyUsed),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _hasSubmittedThisTurn = true;

    // Submit in LETTER:word format
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: '$_selectedLetter:${answer.trim()}',
        ));

    // Optimistic feedback
    _showAnswerFeedback(true, '+10');
  }

  void _showTurnTransitionOverlay() {
    final l10n = AppLocalizations.of(context)!;
    if (_isMyTurn) {
      _turnTransitionText = l10n.gameYourTurn;
      _turnTransitionSub = l10n.gameTapplesPickLetterNameWord;
      HapticFeedback.mediumImpact();
    } else {
      final player = widget.room.currentTurnPlayer;
      final name = player?.displayName ?? l10n.gameOpponent;
      _turnTransitionText = l10n.gamePlayersTurn(name);
      _turnTransitionSub = '';
    }
    setState(() => _showTurnTransition = true);
    _turnTransitionController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showTurnTransition = false);
    });
  }

  void _showAnswerFeedback(bool correct, String text) {
    setState(() {
      _showFeedback = true;
      _feedbackCorrect = correct;
      _feedbackText = text;
    });
    _feedbackController.forward(from: 0);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showFeedback = false);
    });
  }

  void _showScorePopOverlay(String text) {
    setState(() {
      _showScorePop = true;
      _scorePopText = text;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showScorePop = false);
    });
  }

  void _showLifeLostOverlay(String playerName) {
    setState(() {
      _showLifeLost = true;
      _lifeLostPlayerName = playerName;
    });
    _lifeLostController.forward(from: 0);
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _showLifeLost = false);
    });
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
            l10n.gameAbandonProgressMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
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
            child: Text(l10n.gameAbandon,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _particleController.dispose();
    _feedbackController.dispose();
    _turnTransitionController.dispose();
    _lifeLostController.dispose();
    _categoryGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesError) {
          // Server rejected
          if (_hasSubmittedThisTurn) {
            _showAnswerFeedback(false, l10n.gameInvalidAnswer);
            _hasSubmittedThisTurn = false;
          }
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
            '${widget.room.gameType.emoji} ${l10n.gameTapplesTitle}',
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
                  l10n.gameRoundNumber(widget.room.currentRound),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
              tooltip: l10n.gameAbandonTooltip,
              onPressed: _showAbandonDialog,
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
                  painter: _TapplesParticlePainter(
                    progress: _particleController.value,
                  ),
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                // Player avatars with lives + scores
                _buildPlayerAvatars(),
                const SizedBox(height: 4),

                // Category badge with glow
                _buildCategoryBadge(),
                const SizedBox(height: 4),

                // Turn indicator + timer
                _buildTurnAndTimer(),
                const SizedBox(height: 4),

                // Instructions
                _buildInstructions(),
                const SizedBox(height: 4),

                // Letter wheel
                Expanded(child: _buildLetterWheel()),

                // Used words count
                _buildUsedWordsCount(),

                // Answer input (only when letter selected + my turn)
                if (_isMyTurn && _selectedLetter != null && !_hasSubmittedThisTurn)
                  AnswerInput(
                    hintText: l10n.gameTapplesWordStartingWithHint(_selectedLetter!),
                    enabled: true,
                    onSubmitted: _onSubmitAnswer,
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),

            // Overlays
            if (_showTurnTransition) _buildTurnTransitionOverlay(),
            if (_showFeedback) _buildFeedbackOverlay(),
            if (_showScorePop) _buildScorePopOverlay(),
            if (_showLifeLost) _buildLifeLostOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Player Avatars ──
  Widget _buildPlayerAvatars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.room.players.map((player) {
          return PlayerAvatarCircle(
            player: player,
            isCurrentTurn:
                widget.room.currentTurnUserId == player.userId,
            isCurrentUser: player.userId == widget.currentUserId,
            showLives: true,
            showScore: true,
            size: 38,
          );
        }).toList(),
      ),
    );
  }

  // ── Category Badge ──
  Widget _buildCategoryBadge() {
    return AnimatedBuilder(
      animation: _categoryGlowAnimation,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.richGold.withValues(alpha: 0.08),
              AppColors.richGold.withValues(
                  alpha: 0.04 + 0.06 * _categoryGlowAnimation.value),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.richGold.withValues(
                alpha: 0.3 + 0.2 * _categoryGlowAnimation.value),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.richGold.withValues(
                  alpha: 0.1 * _categoryGlowAnimation.value),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_categoryIcon(context), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _category(context),
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Turn & Timer ──
  Widget _buildTurnAndTimer() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _isMyTurn
                  ? AppColors.richGold.withValues(alpha: 0.15)
                  : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isMyTurn
                  ? [
                      BoxShadow(
                        color: AppColors.richGold.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              _isMyTurn
                  ? l10n.gameYourTurn
                  : l10n.gamePlayersTurn(widget.room.currentTurnPlayer?.displayName ?? l10n.gameOpponent),
              style: TextStyle(
                color: _isMyTurn
                    ? AppColors.richGold
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GameTimer(
            remainingSeconds: _remainingSeconds,
            totalSeconds: widget.room.turnDurationSeconds,
            size: 40,
          ),
        ],
      ),
    );
  }

  // ── Instructions ──
  Widget _buildInstructions() {
    final l10n = AppLocalizations.of(context)!;
    String text;
    if (!_isMyTurn) {
      text = l10n.gameWaitForYourTurn;
    } else if (_selectedLetter == null) {
      text = l10n.gameTapplesPickLetterFromWheel;
    } else {
      text = l10n.gameTapplesNameWordStartingWith(_selectedLetter!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _isMyTurn ? AppColors.textPrimary : AppColors.textTertiary,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Letter Wheel ──
  Widget _buildLetterWheel() {
    return Center(
      child: TapplesLetterWheel(
        usedLetters: _usedLetters,
        selectedLetter: _selectedLetter,
        enabled: _isMyTurn && !_hasSubmittedThisTurn,
        onLetterTap: _onLetterSelected,
        categoryName: _category(context),
        categoryIcon: _categoryIcon(context),
      ),
    );
  }

  // ── Used Words Count ──
  Widget _buildUsedWordsCount() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.textTertiary, size: 14),
            const SizedBox(width: 4),
            Text(
              l10n.gameTapplesWordsUsedLettersLeft(widget.room.usedWords.length, 26 - _usedLetters.length),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Turn Transition Overlay ──
  Widget _buildTurnTransitionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: _turnTransitionScale,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isMyTurn
                      ? AppColors.richGold
                      : AppColors.divider,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isMyTurn
                            ? AppColors.richGold
                            : Colors.black)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMyTurn ? Icons.touch_app_rounded : Icons.hourglass_top_rounded,
                    color: _isMyTurn ? AppColors.richGold : AppColors.textTertiary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _turnTransitionText,
                    style: TextStyle(
                      color: _isMyTurn
                          ? AppColors.richGold
                          : AppColors.textPrimary,
                      fontSize: _isMyTurn ? 24 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_turnTransitionSub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _turnTransitionSub,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Feedback Overlay ──
  Widget _buildFeedbackOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: _feedbackScale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (_feedbackCorrect
                        ? AppColors.successGreen
                        : AppColors.errorRed)
                    .withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_feedbackCorrect
                            ? AppColors.successGreen
                            : AppColors.errorRed)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _feedbackCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 36,
                  ),
                  Text(
                    _feedbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Score Pop ──
  Widget _buildScorePopOverlay() {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -30 * value),
                child: child,
              ),
            );
          },
          child: Center(
            child: Text(
              _scorePopText,
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Life Lost Overlay ──
  Widget _buildLifeLostOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: _lifeLostScale,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorRed.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.heart_broken,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.gameTapplesTimeUp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameTapplesPlayerLostLife(_lifeLostPlayerName),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Letter-themed floating particles
class _TapplesParticlePainter extends CustomPainter {
  final double progress;

  _TapplesParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 18;
    const seed = 55;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 43) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 789) % 1000) / 1000.0 * size.height;
      final speed = 0.15 + (hash % 100) / 100.0 * 0.4;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 10;
      final dy =
          math.cos(progress * math.pi * 2 * speed * 0.7 + phase) * 8;
      final opacity =
          (0.03 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      final pos = Offset(baseX + dx, baseY + dy);

      // Draw small letter-shaped dots
      canvas.drawCircle(
        pos,
        1.5,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TapplesParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
