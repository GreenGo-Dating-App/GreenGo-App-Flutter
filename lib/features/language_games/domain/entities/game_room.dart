import 'package:equatable/equatable.dart';

import 'game_player.dart';

/// Game Room Entity
///
/// Represents a multiplayer language learning game session
class GameRoom extends Equatable {
  final String id;
  final GameType gameType;
  final String targetLanguage;
  final String hostUserId;
  final List<GamePlayer> players;
  final int maxPlayers;
  final GameStatus status;
  final DateTime createdAt;
  final int currentRound;
  final int totalRounds;
  final String? currentTurnUserId;
  final Map<String, int> scores;
  final Map<String, int> lives;
  final List<String> usedWords;
  final String? currentPrompt;
  final DateTime? turnStartedAt;
  final int turnDurationSeconds;
  final String? winnerId;
  final String? currentDescriberId;
  final String? roundTheme;
  final List<String>? roundCategories;
  final int difficulty;
  final String? friendGroupId;
  final int xpReward;

  const GameRoom({
    required this.id,
    required this.gameType,
    required this.targetLanguage,
    required this.hostUserId,
    required this.players,
    required this.maxPlayers,
    required this.status,
    required this.createdAt,
    this.currentRound = 0,
    this.totalRounds = 10,
    this.currentTurnUserId,
    this.scores = const {},
    this.lives = const {},
    this.usedWords = const [],
    this.currentPrompt,
    this.turnStartedAt,
    this.turnDurationSeconds = 15,
    this.winnerId,
    this.currentDescriberId,
    this.roundTheme,
    this.roundCategories,
    this.difficulty = 1,
    this.friendGroupId,
    this.xpReward = 0,
  });

  /// Check if room is full
  bool get isFull => players.length >= maxPlayers;

  /// Check if all players are ready
  bool get allPlayersReady =>
      players.length >= gameType.minPlayers &&
      players.every((p) => p.isReady);

  /// Get player count text
  String get playerCountText => '${players.length}/$maxPlayers';

  /// Check if a specific user is the host
  bool isHost(String userId) => hostUserId == userId;

  /// Check if it's a specific user's turn
  bool isPlayerTurn(String userId) => currentTurnUserId == userId;

  /// Get a player by userId
  GamePlayer? getPlayer(String userId) {
    try {
      return players.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get the current turn player
  GamePlayer? get currentTurnPlayer {
    if (currentTurnUserId == null) return null;
    return getPlayer(currentTurnUserId!);
  }

  /// Get alive players (for games with lives)
  List<GamePlayer> get alivePlayers =>
      players.where((p) => (lives[p.userId] ?? 0) > 0).toList();

  /// Get sorted scores (descending)
  List<MapEntry<String, int>> get sortedScores {
    final entries = scores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Check if game is over
  bool get isGameOver => status == GameStatus.finished;

  /// Check if game is in progress
  bool get isInProgress => status == GameStatus.inProgress;

  /// Check if game is waiting for players
  bool get isWaiting => status == GameStatus.waiting;

  GameRoom copyWith({
    String? id,
    GameType? gameType,
    String? targetLanguage,
    String? hostUserId,
    List<GamePlayer>? players,
    int? maxPlayers,
    GameStatus? status,
    DateTime? createdAt,
    int? currentRound,
    int? totalRounds,
    String? currentTurnUserId,
    Map<String, int>? scores,
    Map<String, int>? lives,
    List<String>? usedWords,
    String? currentPrompt,
    DateTime? turnStartedAt,
    int? turnDurationSeconds,
    String? winnerId,
    String? currentDescriberId,
    String? roundTheme,
    List<String>? roundCategories,
    int? difficulty,
    String? friendGroupId,
    int? xpReward,
  }) {
    return GameRoom(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      hostUserId: hostUserId ?? this.hostUserId,
      players: players ?? this.players,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentTurnUserId: currentTurnUserId ?? this.currentTurnUserId,
      scores: scores ?? this.scores,
      lives: lives ?? this.lives,
      usedWords: usedWords ?? this.usedWords,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      turnStartedAt: turnStartedAt ?? this.turnStartedAt,
      turnDurationSeconds: turnDurationSeconds ?? this.turnDurationSeconds,
      winnerId: winnerId ?? this.winnerId,
      currentDescriberId: currentDescriberId ?? this.currentDescriberId,
      roundTheme: roundTheme ?? this.roundTheme,
      roundCategories: roundCategories ?? this.roundCategories,
      difficulty: difficulty ?? this.difficulty,
      friendGroupId: friendGroupId ?? this.friendGroupId,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameType,
        targetLanguage,
        hostUserId,
        players,
        maxPlayers,
        status,
        createdAt,
        currentRound,
        totalRounds,
        currentTurnUserId,
        scores,
        lives,
        usedWords,
        currentPrompt,
        turnStartedAt,
        turnDurationSeconds,
        winnerId,
        currentDescriberId,
        roundTheme,
        roundCategories,
        difficulty,
        friendGroupId,
        xpReward,
      ];
}

/// Types of mini-games available
enum GameType {
  wordBomb('Word Bomb', '💣', 'Think fast! Type words before the bomb explodes!', 2, 4, 'assets/icons/games/word_bomb.svg'),
  translationRace('Translation Race', '🏎️', 'Race to translate words the fastest!', 2, 4, 'assets/icons/games/translation_race.svg'),
  pictureGuess('Picture Guess', '🖼️', 'Describe words and guess them!', 3, 4, 'assets/icons/games/picture_guess.svg'),
  grammarDuel('Grammar Duel', '⚔️', 'Test your grammar knowledge!', 2, 2, 'assets/icons/games/grammar_duel.svg'),
  vocabularyChain('Vocabulary Chain', '🔗', 'Chain words together!', 2, 4, 'assets/icons/games/vocabulary_chain.svg'),
  languageSnaps('Language Snaps', '🃏', 'Match word pairs from memory!', 2, 4, 'assets/icons/games/language_snap.svg'),
  languageTapples('Language Tapples', '🔤', 'Name words by category with letter constraints!', 2, 4, 'assets/icons/games/language_tapples.svg'),
  categories('Categories', '📋', 'Fill categories with words starting with a letter!', 2, 6, 'assets/icons/games/categories.svg');

  final String displayName;
  final String emoji;
  final String tagline;
  final int minPlayers;
  final int maxPlayers;
  final String iconAsset;

  const GameType(
    this.displayName,
    this.emoji,
    this.tagline,
    this.minPlayers,
    this.maxPlayers,
    this.iconAsset,
  );
}

/// Game status progression
enum GameStatus {
  waiting,
  starting,
  inProgress,
  finished;

  String get displayName {
    switch (this) {
      case GameStatus.waiting:
        return 'Waiting for Players';
      case GameStatus.starting:
        return 'Starting...';
      case GameStatus.inProgress:
        return 'In Progress';
      case GameStatus.finished:
        return 'Finished';
    }
  }
}
