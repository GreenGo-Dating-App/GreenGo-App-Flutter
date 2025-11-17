import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/swipe_action.dart';

/// Swipe Action Model for Firestore serialization
class SwipeActionModel extends SwipeAction {
  const SwipeActionModel({
    required super.userId,
    required super.targetUserId,
    required super.actionType,
    required super.timestamp,
    super.createdMatch,
  });

  /// Create from domain entity
  factory SwipeActionModel.fromEntity(SwipeAction action) {
    return SwipeActionModel(
      userId: action.userId,
      targetUserId: action.targetUserId,
      actionType: action.actionType,
      timestamp: action.timestamp,
      createdMatch: action.createdMatch,
    );
  }

  /// Create from Firestore document
  factory SwipeActionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SwipeActionModel(
      userId: data['userId'] as String,
      targetUserId: data['targetUserId'] as String,
      actionType: _parseActionType(data['actionType'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdMatch: data['createdMatch'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'targetUserId': targetUserId,
      'actionType': actionTypeString,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdMatch': createdMatch,
    };
  }

  /// Parse action type from string
  static SwipeActionType _parseActionType(String type) {
    switch (type) {
      case 'like':
        return SwipeActionType.like;
      case 'pass':
        return SwipeActionType.pass;
      case 'superLike':
        return SwipeActionType.superLike;
      default:
        return SwipeActionType.pass;
    }
  }

  /// Convert to entity
  SwipeAction toEntity() => this;
}
