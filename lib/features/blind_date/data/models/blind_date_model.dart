import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blind_date.dart';

/// Blind Date Profile Model
class BlindDateProfileModel extends BlindDateProfile {
  const BlindDateProfileModel({
    required super.id,
    required super.odldid,
    super.isActive = true,
    super.photosRevealed = false,
    super.messageCount = 0,
    required super.createdAt,
    super.revealedAt,
  });

  factory BlindDateProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BlindDateProfileModel(
      id: doc.id,
      odldid: data['odldid'] as String,
      isActive: data['isActive'] as bool? ?? true,
      photosRevealed: data['photosRevealed'] as bool? ?? false,
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      revealedAt: data['revealedAt'] != null
          ? (data['revealedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory BlindDateProfileModel.fromMap(Map<String, dynamic> map) {
    return BlindDateProfileModel(
      id: map['id'] as String,
      odldid: map['odldid'] as String,
      isActive: map['isActive'] as bool? ?? true,
      photosRevealed: map['photosRevealed'] as bool? ?? false,
      messageCount: (map['messageCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      revealedAt: map['revealedAt'] != null
          ? (map['revealedAt'] is String
              ? DateTime.parse(map['revealedAt'] as String)
              : (map['revealedAt'] as Timestamp).toDate())
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'odldid': odldid,
      'isActive': isActive,
      'photosRevealed': photosRevealed,
      'messageCount': messageCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'revealedAt': revealedAt != null ? Timestamp.fromDate(revealedAt!) : null,
    };
  }
}

/// Blind Match Model
class BlindMatchModel extends BlindMatch {
  const BlindMatchModel({
    required super.id,
    required super.profile1Id,
    required super.profile2Id,
    required super.user1Id,
    required super.user2Id,
    super.messageCount = 0,
    super.isRevealed = false,
    required super.matchedAt,
    super.revealedAt,
    super.conversationId,
  });

  factory BlindMatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BlindMatchModel(
      id: doc.id,
      profile1Id: data['profile1Id'] as String,
      profile2Id: data['profile2Id'] as String,
      user1Id: data['user1Id'] as String,
      user2Id: data['user2Id'] as String,
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      isRevealed: data['isRevealed'] as bool? ?? false,
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
      revealedAt: data['revealedAt'] != null
          ? (data['revealedAt'] as Timestamp).toDate()
          : null,
      conversationId: data['conversationId'] as String?,
    );
  }

  factory BlindMatchModel.fromMap(Map<String, dynamic> map) {
    return BlindMatchModel(
      id: map['id'] as String,
      profile1Id: map['profile1Id'] as String,
      profile2Id: map['profile2Id'] as String,
      user1Id: map['user1Id'] as String,
      user2Id: map['user2Id'] as String,
      messageCount: (map['messageCount'] as num?)?.toInt() ?? 0,
      isRevealed: map['isRevealed'] as bool? ?? false,
      matchedAt: map['matchedAt'] is String
          ? DateTime.parse(map['matchedAt'] as String)
          : (map['matchedAt'] as Timestamp).toDate(),
      revealedAt: map['revealedAt'] != null
          ? (map['revealedAt'] is String
              ? DateTime.parse(map['revealedAt'] as String)
              : (map['revealedAt'] as Timestamp).toDate())
          : null,
      conversationId: map['conversationId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'profile1Id': profile1Id,
      'profile2Id': profile2Id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'messageCount': messageCount,
      'isRevealed': isRevealed,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'revealedAt': revealedAt != null ? Timestamp.fromDate(revealedAt!) : null,
      'conversationId': conversationId,
    };
  }
}

/// Blind Profile View Model
class BlindProfileViewModel extends BlindProfileView {
  const BlindProfileViewModel({
    required super.odldid,
    required super.displayName,
    required super.age,
    super.bio,
    super.interests = const [],
    super.occupation,
    super.education,
    super.distance,
    super.isVerified = false,
    super.photos,
    super.isRevealed = false,
  });

  factory BlindProfileViewModel.fromMap(Map<String, dynamic> map) {
    return BlindProfileViewModel(
      odldid: map['odldid'] as String,
      displayName: map['displayName'] as String,
      age: (map['age'] as num).toInt(),
      bio: map['bio'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      occupation: map['occupation'] as String?,
      education: map['education'] as String?,
      distance: (map['distance'] as num?)?.toDouble(),
      isVerified: map['isVerified'] as bool? ?? false,
      photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
      isRevealed: map['isRevealed'] as bool? ?? false,
    );
  }
}
