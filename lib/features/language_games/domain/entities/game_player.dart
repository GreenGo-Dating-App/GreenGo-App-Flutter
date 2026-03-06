import 'package:equatable/equatable.dart';

/// Game Player Entity
///
/// Represents a player participating in a language game
class GamePlayer extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int score;
  final int lives;
  final bool isReady;
  final bool isConnected;
  final List<String> languages;

  const GamePlayer({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.score = 0,
    this.lives = 3,
    this.isReady = false,
    this.isConnected = true,
    this.languages = const [],
  });

  /// Check if player is still alive (has lives remaining)
  bool get isAlive => lives > 0;

  /// Get display for lives (hearts)
  String get livesDisplay => List.filled(lives, '❤️').join();

  GamePlayer copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    int? score,
    int? lives,
    bool? isReady,
    bool? isConnected,
    List<String>? languages,
  }) {
    return GamePlayer(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      languages: languages ?? this.languages,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        score,
        lives,
        isReady,
        isConnected,
        languages,
      ];
}
