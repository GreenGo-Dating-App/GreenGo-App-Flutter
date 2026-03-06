import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/bloc/coin_state.dart';
import '../../domain/entities/game_room.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../widgets/game_card.dart';
import 'game_waiting_screen.dart';

/// Main game selection/lobby screen
/// User lands here first to choose language, difficulty, and game type
class GameLobbyScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String? photoUrl;

  const GameLobbyScreen({
    super.key,
    required this.userId,
    this.displayName = 'Player',
    this.photoUrl,
  });

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  // Language selection
  int _selectedLanguageIndex = 0;
  static const List<_LanguageOption> _languages = [
    _LanguageOption(code: 'it', flag: '\u{1F1EE}\u{1F1F9}', name: 'Italian'),
    _LanguageOption(code: 'en', flag: '\u{1F1EC}\u{1F1E7}', name: 'English'),
    _LanguageOption(code: 'fr', flag: '\u{1F1EB}\u{1F1F7}', name: 'French'),
    _LanguageOption(code: 'de', flag: '\u{1F1E9}\u{1F1EA}', name: 'German'),
    _LanguageOption(code: 'pt', flag: '\u{1F1F5}\u{1F1F9}', name: 'Portuguese'),
    _LanguageOption(code: 'pt-BR', flag: '\u{1F1E7}\u{1F1F7}', name: 'Brazilian'),
    _LanguageOption(code: 'es', flag: '\u{1F1EA}\u{1F1F8}', name: 'Spanish'),
  ];

  // Difficulty selection
  int _selectedDifficulty = 1;
  static const List<String> _difficultyLabels = [
    'Beginner',
    'Elementary',
    'Pre-Intermediate',
    'Intermediate',
    'Upper-Intermediate',
    'Advanced',
    'Proficient',
    'Expert',
    'Champion',
    'Master',
  ];

  // Active rooms the user is in
  List<GameRoom> _myActiveRooms = [];

  // Live counts per game type
  final Map<GameType, _LiveCounts> _liveCounts = {};

  /// Cost in coins per game play
  static const int _gamePlayCost = 10;

  String get _selectedLanguageCode => _languages[_selectedLanguageIndex].code;

  @override
  void initState() {
    super.initState();
    context.read<LanguageGamesBloc>().add(
          LoadAvailableRooms(targetLanguage: _selectedLanguageCode),
        );
  }

  void _onLanguageChanged(int index) {
    setState(() => _selectedLanguageIndex = index);
    HapticFeedback.selectionClick();
    context.read<LanguageGamesBloc>().add(
          LoadAvailableRooms(targetLanguage: _selectedLanguageCode),
        );
  }

  void _onDifficultyChanged(double value) {
    setState(() => _selectedDifficulty = value.round());
    HapticFeedback.selectionClick();
  }

  void _onGameCardTapped(GameType gameType) {
    HapticFeedback.mediumImpact();
    _showGameModeSheet(gameType);
  }

  /// Charges game play coins. Returns true if successful, false if not enough coins.
  bool _chargeGameCoins() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final coinState = context.read<CoinBloc>().state;
    int currentCoins = 0;
    if (coinState is CoinBalanceLoaded) {
      currentCoins = coinState.balance.totalCoins;
    }

    if (currentCoins < _gamePlayCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough coins! You need $_gamePlayCost coins to play. Current balance: $currentCoins',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return false;
    }

    context.read<CoinBloc>().add(PurchaseFeatureWithCoins(
          userId: userId,
          featureName: 'game_play',
          cost: _gamePlayCost,
        ));
    return true;
  }

  /// Selected round count for Word Bomb (1, 3, or 5 lives)
  int _selectedWordBombRounds = 3;

  void _showGameModeSheet(GameType gameType) {
    // Reset round selector when opening sheet
    int localRounds = _selectedWordBombRounds;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${gameType.emoji}  ${gameType.displayName}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gameType.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // Round selector for Word Bomb
              if (gameType == GameType.wordBomb) ...[
                const Text(
                  'LIVES',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 3, 5].map((count) {
                    final isSelected = localRounds == count;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() => localRounds = count);
                          setState(() => _selectedWordBombRounds = count);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.richGold.withValues(alpha: 0.15)
                                : AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.richGold
                                  : AppColors.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.richGold
                                  : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Coin cost indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on,
                        color: AppColors.richGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_gamePlayCost coins per play',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Quick Play button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (!_chargeGameCoins()) return;
                      Navigator.of(sheetContext).pop();
                      HapticFeedback.mediumImpact();
                      context.read<LanguageGamesBloc>().add(
                            QuickPlay(
                              gameType: gameType,
                              targetLanguage: _selectedLanguageCode,
                              userId: widget.userId,
                              displayName: widget.displayName,
                              photoUrl: widget.photoUrl,
                              difficulty: _selectedDifficulty,
                            ),
                          );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.backgroundDark, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Play',
                            style: TextStyle(
                              color: AppColors.backgroundDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.monetization_on,
                                    color: AppColors.backgroundDark
                                        .withValues(alpha: 0.8),
                                    size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '$_gamePlayCost',
                                  style: TextStyle(
                                    color: AppColors.backgroundDark
                                        .withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Private Room button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (!_chargeGameCoins()) return;
                      Navigator.of(sheetContext).pop();
                      HapticFeedback.mediumImpact();
                      context.read<LanguageGamesBloc>().add(
                            CreateRoom(
                              gameType: gameType,
                              targetLanguage: _selectedLanguageCode,
                              hostUserId: widget.userId,
                              hostDisplayName: widget.displayName,
                              hostPhotoUrl: widget.photoUrl,
                              maxPlayers: gameType.maxPlayers,
                              difficulty: _selectedDifficulty,
                              totalRounds: gameType == GameType.wordBomb
                                  ? localRounds
                                  : null,
                            ),
                          );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.richGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_add_rounded,
                              color: AppColors.richGold, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Private Room',
                            style: TextStyle(
                              color: AppColors.richGold,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.monetization_on,
                                    color:
                                        AppColors.richGold.withValues(alpha: 0.8),
                                    size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '$_gamePlayCost',
                                  style: TextStyle(
                                    color: AppColors.richGold
                                        .withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
          },
        );
      },
    );
  }


  void _navigateToWaitingRoom(GameRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<LanguageGamesBloc>(),
          child: GameWaitingScreen(
            userId: widget.userId,
            displayName: widget.displayName,
            room: room,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesInRoom) {
          _navigateToWaitingRoom(state.room);
        } else if (state is LanguageGamesLobby) {
          _updateLiveCounts(state.availableRooms);
          setState(() {
            _myActiveRooms = state.availableRooms
                .where((r) =>
                    r.players.any((p) => p.userId == widget.userId) &&
                    r.status != GameStatus.finished)
                .toList();
          });
        } else if (state is LanguageGamesError) {
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
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.greengoPlay,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.richGold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildLanguageSelector()),
        SliverToBoxAdapter(child: _buildDifficultySelector()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'CHOOSE A GAME',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gameType = GameType.values[index];
                final counts = _liveCounts[gameType];
                return GameCard(
                  gameType: gameType,
                  waitingCount: counts?.waiting ?? 0,
                  playingCount: counts?.playing ?? 0,
                  onTap: () => _onGameCardTapped(gameType),
                );
              },
              childCount: GameType.values.length,
            ),
          ),
        ),
        if (_myActiveRooms.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'MY ACTIVE GAMES',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildActiveGameTile(_myActiveRooms[index]),
                childCount: _myActiveRooms.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'TARGET LANGUAGE',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = index == _selectedLanguageIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onLanguageChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.richGold.withValues(alpha: 0.15)
                            : AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.richGold
                              : AppColors.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang.flag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            lang.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.richGold
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DIFFICULTY',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Lv.$_selectedDifficulty - ${_difficultyLabels[_selectedDifficulty - 1]}',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.richGold,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.richGold,
              overlayColor: AppColors.richGold.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _selectedDifficulty.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: _onDifficultyChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Beginner',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              Text('Master',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActiveGameTile(GameRoom room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            context.read<LanguageGamesBloc>().add(
                  JoinRoom(
                    roomId: room.id,
                    userId: widget.userId,
                    displayName: widget.displayName,
                    photoUrl: widget.photoUrl,
                  ),
                );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(room.gameType.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.gameType.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${room.status.displayName} - ${room.playerCountText}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: room.isInProgress
                        ? AppColors.successGreen.withValues(alpha: 0.15)
                        : AppColors.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    room.isInProgress ? 'Rejoin' : 'Open',
                    style: TextStyle(
                      color: room.isInProgress
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _updateLiveCounts(List<GameRoom> rooms) {
    final counts = <GameType, _LiveCounts>{};
    for (final type in GameType.values) {
      final typeRooms = rooms.where((r) => r.gameType == type);
      counts[type] = _LiveCounts(
        waiting: typeRooms
            .where((r) => r.isWaiting)
            .fold(0, (sum, r) => sum + r.players.length),
        playing: typeRooms
            .where((r) => r.isInProgress)
            .fold(0, (sum, r) => sum + r.players.length),
      );
    }
    setState(() {
      _liveCounts
        ..clear()
        ..addAll(counts);
    });
  }
}

class _LanguageOption {
  final String code;
  final String flag;
  final String name;

  const _LanguageOption({
    required this.code,
    required this.flag,
    required this.name,
  });
}

class _LiveCounts {
  final int waiting;
  final int playing;

  const _LiveCounts({required this.waiting, required this.playing});
}
