import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/match.dart';

/// Match Model for Firestore serialization
class MatchModel extends Match {
  const MatchModel({
    required super.matchId,
    required super.userId1,
    required super.userId2,
    required super.matchedAt,
    super.isActive,
    super.lastMessageAt,
    super.lastMessage,
    super.unreadCount,
    super.user1Seen,
    super.user2Seen,
  });

  /// Create from domain entity
  factory MatchModel.fromEntity(Match match) {
    return MatchModel(
      matchId: match.matchId,
      userId1: match.userId1,
      userId2: match.userId2,
      matchedAt: match.matchedAt,
      isActive: match.isActive,
      lastMessageAt: match.lastMessageAt,
      lastMessage: match.lastMessage,
      unreadCount: match.unreadCount,
      user1Seen: match.user1Seen,
      user2Seen: match.user2Seen,
    );
  }

  /// Create from Firestore document
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      matchId: doc.id,
      userId1: data['userId1'] as String,
      userId2: data['userId2'] as String,
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessage: data['lastMessage'] as String?,
      unreadCount: data['unreadCount'] ?? 0,
      user1Seen: data['user1Seen'] ?? false,
      user2Seen: data['user2Seen'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'isActive': isActive,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'user1Seen': user1Seen,
      'user2Seen': user2Seen,
    };
  }

  /// Convert to entity
  Match toEntity() => this;
}
