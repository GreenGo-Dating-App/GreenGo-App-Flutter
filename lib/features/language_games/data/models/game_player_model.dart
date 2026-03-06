import '../../domain/entities/game_player.dart';

/// Game Player Firestore Model
class GamePlayerModel extends GamePlayer {
  const GamePlayerModel({
    required super.userId,
    required super.displayName,
    super.photoUrl,
    super.score,
    super.lives,
    super.isReady,
    super.isConnected,
    super.languages,
  });

  /// Create from Firestore map data
  factory GamePlayerModel.fromMap(String id, Map<String, dynamic> data) {
    return GamePlayerModel(
      userId: id,
      displayName: data['displayName'] as String? ?? 'Player',
      photoUrl: data['photoUrl'] as String?,
      score: (data['score'] as num?)?.toInt() ?? 0,
      lives: (data['lives'] as num?)?.toInt() ?? 3,
      isReady: data['isReady'] as bool? ?? false,
      isConnected: data['isConnected'] as bool? ?? true,
      languages: (data['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'score': score,
      'lives': lives,
      'isReady': isReady,
      'isConnected': isConnected,
      'languages': languages,
    };
  }

  /// Create from entity
  factory GamePlayerModel.fromEntity(GamePlayer player) {
    return GamePlayerModel(
      userId: player.userId,
      displayName: player.displayName,
      photoUrl: player.photoUrl,
      score: player.score,
      lives: player.lives,
      isReady: player.isReady,
      isConnected: player.isConnected,
      languages: player.languages,
    );
  }
}
