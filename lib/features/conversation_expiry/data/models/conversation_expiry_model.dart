import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation_expiry.dart';

/// Conversation Expiry Model
class ConversationExpiryModel extends ConversationExpiry {
  const ConversationExpiryModel({
    required super.id,
    required super.matchId,
    required super.conversationId,
    required super.createdAt,
    required super.expiresAt,
    super.isExpired = false,
    super.hasActivity = false,
    super.extensionCount = 0,
    super.lastExtendedAt,
    super.extendedByUserId,
  });

  factory ConversationExpiryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationExpiryModel(
      id: doc.id,
      matchId: data['matchId'] as String,
      conversationId: data['conversationId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isExpired: data['isExpired'] as bool? ?? false,
      hasActivity: data['hasActivity'] as bool? ?? false,
      extensionCount: (data['extensionCount'] as num?)?.toInt() ?? 0,
      lastExtendedAt: data['lastExtendedAt'] != null
          ? (data['lastExtendedAt'] as Timestamp).toDate()
          : null,
      extendedByUserId: data['extendedByUserId'] as String?,
    );
  }

  factory ConversationExpiryModel.fromMap(Map<String, dynamic> map) {
    return ConversationExpiryModel(
      id: map['id'] as String,
      matchId: map['matchId'] as String,
      conversationId: map['conversationId'] as String,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      expiresAt: map['expiresAt'] is Timestamp
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.parse(map['expiresAt'] as String),
      isExpired: map['isExpired'] as bool? ?? false,
      hasActivity: map['hasActivity'] as bool? ?? false,
      extensionCount: (map['extensionCount'] as num?)?.toInt() ?? 0,
      lastExtendedAt: map['lastExtendedAt'] != null
          ? (map['lastExtendedAt'] is Timestamp
              ? (map['lastExtendedAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastExtendedAt'] as String))
          : null,
      extendedByUserId: map['extendedByUserId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'conversationId': conversationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isExpired': isExpired,
      'hasActivity': hasActivity,
      'extensionCount': extensionCount,
      'lastExtendedAt':
          lastExtendedAt != null ? Timestamp.fromDate(lastExtendedAt!) : null,
      'extendedByUserId': extendedByUserId,
    };
  }

  factory ConversationExpiryModel.fromEntity(ConversationExpiry entity) {
    return ConversationExpiryModel(
      id: entity.id,
      matchId: entity.matchId,
      conversationId: entity.conversationId,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      isExpired: entity.isExpired,
      hasActivity: entity.hasActivity,
      extensionCount: entity.extensionCount,
      lastExtendedAt: entity.lastExtendedAt,
      extendedByUserId: entity.extendedByUserId,
    );
  }
}

/// Extension Result Model
class ExtensionResultModel extends ExtensionResult {
  const ExtensionResultModel({
    required super.success,
    super.expiry,
    super.coinsSpent,
    super.errorMessage,
  });

  factory ExtensionResultModel.fromMap(Map<String, dynamic> map) {
    return ExtensionResultModel(
      success: map['success'] as bool,
      expiry: map['expiry'] != null
          ? ConversationExpiryModel.fromMap(
              map['expiry'] as Map<String, dynamic>,
            )
          : null,
      coinsSpent: map['coinsSpent'] as int?,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
