import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/second_chance.dart';

/// Second Chance Entry Model
class SecondChanceEntryModel extends SecondChanceEntry {
  const SecondChanceEntryModel({
    required super.id,
    required super.userId,
    required super.skippedUserId,
    required super.skippedAt,
    required super.availableUntil,
    super.isUsed = false,
    super.usedAt,
    super.action,
  });

  factory SecondChanceEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecondChanceEntryModel(
      id: doc.id,
      userId: data['userId'] as String,
      skippedUserId: data['skippedUserId'] as String,
      skippedAt: (data['skippedAt'] as Timestamp).toDate(),
      availableUntil: (data['availableUntil'] as Timestamp).toDate(),
      isUsed: data['isUsed'] as bool? ?? false,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
      action: data['action'] != null
          ? SecondChanceAction.values.firstWhere(
              (e) => e.name == data['action'],
              orElse: () => SecondChanceAction.expired,
            )
          : null,
    );
  }

  factory SecondChanceEntryModel.fromMap(Map<String, dynamic> map) {
    return SecondChanceEntryModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      skippedUserId: map['skippedUserId'] as String,
      skippedAt: map['skippedAt'] is Timestamp
          ? (map['skippedAt'] as Timestamp).toDate()
          : DateTime.parse(map['skippedAt'] as String),
      availableUntil: map['availableUntil'] is Timestamp
          ? (map['availableUntil'] as Timestamp).toDate()
          : DateTime.parse(map['availableUntil'] as String),
      isUsed: map['isUsed'] as bool? ?? false,
      usedAt: map['usedAt'] != null
          ? (map['usedAt'] is Timestamp
              ? (map['usedAt'] as Timestamp).toDate()
              : DateTime.parse(map['usedAt'] as String))
          : null,
      action: map['action'] != null
          ? SecondChanceAction.values.firstWhere(
              (e) => e.name == map['action'],
              orElse: () => SecondChanceAction.expired,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'skippedUserId': skippedUserId,
      'skippedAt': Timestamp.fromDate(skippedAt),
      'availableUntil': Timestamp.fromDate(availableUntil),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'action': action?.name,
    };
  }
}

/// Second Chance Profile Model
class SecondChanceProfileModel extends SecondChanceProfile {
  const SecondChanceProfileModel({
    required super.odldid,
    required super.name,
    required super.age,
    required super.photos,
    super.bio,
    super.interests = const [],
    super.distance,
    super.isVerified = false,
    required super.likedYouAt,
    required super.entry,
  });

  factory SecondChanceProfileModel.fromMap(Map<String, dynamic> map) {
    return SecondChanceProfileModel(
      odldid: map['userId'] as String,
      name: map['name'] as String,
      age: (map['age'] as num).toInt(),
      photos: List<String>.from(map['photos'] ?? []),
      bio: map['bio'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      distance: (map['distance'] as num?)?.toDouble(),
      isVerified: map['isVerified'] as bool? ?? false,
      likedYouAt: map['likedYouAt'] is Timestamp
          ? (map['likedYouAt'] as Timestamp).toDate()
          : DateTime.parse(map['likedYouAt'] as String),
      entry: SecondChanceEntryModel.fromMap(
        map['entry'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Second Chance Usage Model
class SecondChanceUsageModel extends SecondChanceUsage {
  const SecondChanceUsageModel({
    required super.odldid,
    required super.date,
    super.freeUsed = 0,
    super.hasUnlimited = false,
    super.unlimitedExpiresAt,
  });

  factory SecondChanceUsageModel.fromMap(Map<String, dynamic> map) {
    return SecondChanceUsageModel(
      odldid: map['userId'] as String,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'] as String),
      freeUsed: (map['freeUsed'] as num?)?.toInt() ?? 0,
      hasUnlimited: map['hasUnlimited'] as bool? ?? false,
      unlimitedExpiresAt: map['unlimitedExpiresAt'] != null
          ? (map['unlimitedExpiresAt'] is Timestamp
              ? (map['unlimitedExpiresAt'] as Timestamp).toDate()
              : DateTime.parse(map['unlimitedExpiresAt'] as String))
          : null,
    );
  }
}

/// Second Chance Result Model
class SecondChanceResultModel extends SecondChanceResult {
  const SecondChanceResultModel({
    required super.success,
    super.isMatch = false,
    super.matchId,
    super.errorMessage,
  });

  factory SecondChanceResultModel.fromMap(Map<String, dynamic> map) {
    return SecondChanceResultModel(
      success: map['success'] as bool,
      isMatch: map['isMatch'] as bool? ?? false,
      matchId: map['matchId'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
