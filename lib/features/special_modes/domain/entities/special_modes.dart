import 'package:equatable/equatable.dart';

/// Blind Date Mode Entity
/// Match based on personality, photos revealed later
class BlindDate extends Equatable {
  final String id;
  final String participantId;
  final String? matchedWithId;
  final String? matchedWithName;
  final String anonymousName; // e.g., "Mystery Person #42"
  final String anonymousAvatar; // Emoji or placeholder
  final List<String> personalityTraits;
  final List<String> interests;
  final String? introMessage;
  final DateTime createdAt;
  final DateTime? matchedAt;
  final DateTime? revealedAt;
  final int messagesExchanged;
  final bool isActive;
  final bool isRevealed;
  final BlindDatePhase phase;

  const BlindDate({
    required this.id,
    required this.participantId,
    this.matchedWithId,
    this.matchedWithName,
    required this.anonymousName,
    required this.anonymousAvatar,
    required this.personalityTraits,
    required this.interests,
    this.introMessage,
    required this.createdAt,
    this.matchedAt,
    this.revealedAt,
    this.messagesExchanged = 0,
    this.isActive = true,
    this.isRevealed = false,
    required this.phase,
  });

  bool get canReveal => messagesExchanged >= 20 && !isRevealed;

  @override
  List<Object?> get props => [
        id,
        participantId,
        matchedWithId,
        matchedWithName,
        anonymousName,
        anonymousAvatar,
        personalityTraits,
        interests,
        introMessage,
        createdAt,
        matchedAt,
        revealedAt,
        messagesExchanged,
        isActive,
        isRevealed,
        phase,
      ];
}

enum BlindDatePhase {
  waiting,
  matched,
  chatting,
  readyToReveal,
  revealed,
  ended,
}

/// Speed Dating Session Entity
class SpeedDatingSession extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int roundDurationMinutes;
  final int breakDurationMinutes;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final int? minAge;
  final int? maxAge;
  final String? genderPreference;
  final String? theme; // 'professionals', 'gamers', 'foodies', etc.
  final SpeedDatingStatus status;
  final double? entryFee;
  final List<SpeedDatingRound> rounds;
  final DateTime createdAt;

  const SpeedDatingSession({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.roundDurationMinutes,
    required this.breakDurationMinutes,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.participantIds = const [],
    this.minAge,
    this.maxAge,
    this.genderPreference,
    this.theme,
    required this.status,
    this.entryFee,
    this.rounds = const [],
    required this.createdAt,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  bool get isUpcoming => status == SpeedDatingStatus.scheduled;
  bool get isLive => status == SpeedDatingStatus.inProgress;
  int get spotsLeft => maxParticipants - currentParticipants;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        roundDurationMinutes,
        breakDurationMinutes,
        maxParticipants,
        currentParticipants,
        participantIds,
        minAge,
        maxAge,
        genderPreference,
        theme,
        status,
        entryFee,
        rounds,
        createdAt,
      ];
}

enum SpeedDatingStatus {
  scheduled,
  registrationOpen,
  registrationClosed,
  inProgress,
  completed,
  cancelled,
}

/// Speed Dating Round
class SpeedDatingRound extends Equatable {
  final String id;
  final String sessionId;
  final int roundNumber;
  final String participant1Id;
  final String participant2Id;
  final DateTime startTime;
  final DateTime endTime;
  final bool participant1Interested;
  final bool participant2Interested;
  final bool isMatch;

  const SpeedDatingRound({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.participant1Id,
    required this.participant2Id,
    required this.startTime,
    required this.endTime,
    this.participant1Interested = false,
    this.participant2Interested = false,
    this.isMatch = false,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        roundNumber,
        participant1Id,
        participant2Id,
        startTime,
        endTime,
        participant1Interested,
        participant2Interested,
        isMatch,
      ];
}

/// Music Integration Entity
class MusicProfile extends Equatable {
  final String userId;
  final String? spotifyUserId;
  final String? appleMusicUserId;
  final List<String> topArtists;
  final List<String> topGenres;
  final List<MusicTrack> favoriteTracks;
  final String? currentlyPlaying;
  final String? anthem; // Featured song on profile
  final DateTime? lastSynced;

  const MusicProfile({
    required this.userId,
    this.spotifyUserId,
    this.appleMusicUserId,
    this.topArtists = const [],
    this.topGenres = const [],
    this.favoriteTracks = const [],
    this.currentlyPlaying,
    this.anthem,
    this.lastSynced,
  });

  bool get isConnected => spotifyUserId != null || appleMusicUserId != null;

  @override
  List<Object?> get props => [
        userId,
        spotifyUserId,
        appleMusicUserId,
        topArtists,
        topGenres,
        favoriteTracks,
        currentlyPlaying,
        anthem,
        lastSynced,
      ];
}

/// Music Track
class MusicTrack extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  final int? durationMs;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    this.durationMs,
  });

  @override
  List<Object?> get props => [id, title, artist, albumArt, previewUrl, durationMs];
}

/// Music Compatibility
class MusicCompatibility extends Equatable {
  final String userId1;
  final String userId2;
  final double compatibilityScore; // 0-100
  final List<String> sharedArtists;
  final List<String> sharedGenres;
  final List<MusicTrack> sharedTracks;

  const MusicCompatibility({
    required this.userId1,
    required this.userId2,
    required this.compatibilityScore,
    this.sharedArtists = const [],
    this.sharedGenres = const [],
    this.sharedTracks = const [],
  });

  @override
  List<Object?> get props => [
        userId1,
        userId2,
        compatibilityScore,
        sharedArtists,
        sharedGenres,
        sharedTracks,
      ];
}
