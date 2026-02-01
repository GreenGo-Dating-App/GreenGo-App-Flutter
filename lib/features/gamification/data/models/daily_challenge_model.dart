/**
 * Daily Challenge Data Models
 * Points 196-200: Firestore serialization for challenges
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/daily_challenge.dart';

class UserChallengeProgressModel extends UserChallengeProgress {
  UserChallengeProgressModel({
    required super.userId,
    required super.challengeId,
    required super.progress,
    required super.requiredCount,
    super.isCompleted,
    super.completedAt,
    super.createdAt,
    super.rewardsClaimed,
  });

  factory UserChallengeProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserChallengeProgressModel(
      userId: data['userId'] as String,
      challengeId: data['challengeId'] as String,
      progress: data['progress'] as int,
      requiredCount: data['requiredCount'] as int,
      isCompleted: data['isCompleted'] as bool,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      rewardsClaimed: data['rewardsClaimed'] as bool? ?? false,
    );
  }

  factory UserChallengeProgressModel.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgressModel(
      userId: map['userId'] as String,
      challengeId: map['challengeId'] as String,
      progress: map['progress'] as int,
      requiredCount: map['requiredCount'] as int,
      isCompleted: map['isCompleted'] as bool,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      rewardsClaimed: map['rewardsClaimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'progress': progress,
      'requiredCount': requiredCount,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rewardsClaimed': rewardsClaimed,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserChallengeProgressModel.fromEntity(
    UserChallengeProgress entity,
  ) {
    return UserChallengeProgressModel(
      userId: entity.userId,
      challengeId: entity.challengeId,
      progress: entity.progress,
      requiredCount: entity.requiredCount,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      rewardsClaimed: entity.rewardsClaimed,
    );
  }

  UserChallengeProgressModel copyWith({
    String? userId,
    String? challengeId,
    int? progress,
    int? requiredCount,
    bool? isCompleted,
    DateTime? completedAt,
    bool? rewardsClaimed,
  }) {
    return UserChallengeProgressModel(
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      progress: progress ?? this.progress,
      requiredCount: requiredCount ?? this.requiredCount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }
}

/// Seasonal Event Model (Point 200)
class SeasonalEventModel extends SeasonalEvent {
  const SeasonalEventModel({
    required super.eventId,
    required super.name,
    required super.description,
    required super.theme,
    required super.startDate,
    required super.endDate,
    required super.challenges,
    required super.themeConfig,
  });

  factory SeasonalEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse challenges
    final challengesData = data['challenges'] as List<dynamic>? ?? [];
    final eventStartDate = (data['startDate'] as Timestamp).toDate();
    final eventEndDate = (data['endDate'] as Timestamp).toDate();
    final challenges = challengesData.map((c) {
      final challengeMap = c as Map<String, dynamic>;
      return DailyChallenge(
        challengeId: challengeMap['challengeId'] as String,
        name: challengeMap['name'] as String,
        description: challengeMap['description'] as String,
        type: ChallengeType.values.firstWhere(
          (t) => t.toString() == 'ChallengeType.${challengeMap['type']}',
        ),
        requiredCount: challengeMap['requiredCount'] as int,
        actionType: challengeMap['actionType'] as String? ?? 'unknown',
        rewards: (challengeMap['rewards'] as List<dynamic>)
            .map((r) => ChallengeReward(
                  type: r['type'] as String,
                  amount: r['amount'] as int,
                  itemId: r['itemId'] as String?,
                ))
            .toList(),
        difficulty: ChallengeDifficulty.values.firstWhere(
          (d) =>
              d.toString() ==
              'ChallengeDifficulty.${challengeMap['difficulty'] ?? 'easy'}',
        ),
        startDate: challengeMap['startDate'] != null
            ? (challengeMap['startDate'] as Timestamp).toDate()
            : eventStartDate,
        endDate: challengeMap['endDate'] != null
            ? (challengeMap['endDate'] as Timestamp).toDate()
            : eventEndDate,
      );
    }).toList();

    return SeasonalEventModel(
      eventId: data['eventId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      theme: data['theme'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      challenges: challenges,
      themeConfig: Map<String, dynamic>.from(data['themeConfig'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'description': description,
      'theme': theme,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'challenges': challenges
          .map((c) => {
                'challengeId': c.challengeId,
                'name': c.name,
                'description': c.description,
                'type': c.type.toString().split('.').last,
                'requiredCount': c.requiredCount,
                'rewards': c.rewards
                    .map((r) => {
                          'type': r.type,
                          'amount': r.amount,
                          'itemId': r.itemId,
                        })
                    .toList(),
                'difficulty': c.difficulty.toString().split('.').last,
              })
          .toList(),
      'themeConfig': themeConfig,
    };
  }

  factory SeasonalEventModel.fromEntity(SeasonalEvent entity) {
    return SeasonalEventModel(
      eventId: entity.eventId,
      name: entity.name,
      description: entity.description,
      theme: entity.theme,
      startDate: entity.startDate,
      endDate: entity.endDate,
      challenges: entity.challenges,
      themeConfig: entity.themeConfig,
    );
  }
}
