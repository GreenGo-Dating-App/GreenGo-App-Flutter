import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Chat Remote Data Source
///
/// Handles Firestore operations for chat feature
abstract class ChatRemoteDataSource {
  /// Get or create conversation for a match
  Future<ConversationModel> getConversation(String matchId);

  /// Stream of messages for a conversation
  Stream<List<MessageModel>> getMessagesStream({
    required String conversationId,
    int? limit,
  });

  /// Send a message
  Future<MessageModel> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
  });

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String messageId,
    required String conversationId,
  });

  /// Mark all messages as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  });

  /// Stream of user's conversations
  Stream<List<ConversationModel>> getConversationsStream(String userId);

  /// Set typing indicator
  Future<void> setTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  });

  /// Delete message
  Future<void> deleteMessage({
    required String messageId,
    required String conversationId,
  });

  /// Get unread count
  Future<int> getUnreadCount(String userId);

  /// Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String conversationId,
    required String userId,
    required String emoji,
  });

  /// Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  /// Pin conversation
  Future<void> pinConversation({
    required String conversationId,
    required String userId,
    required bool isPinned,
  });

  /// Mute conversation
  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool isMuted,
  });

  /// Archive conversation
  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool isArchived,
  });

  /// Update conversation theme
  Future<void> updateConversationTheme({
    required String conversationId,
    required String theme,
  });

  /// Search messages in conversation
  Stream<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    int? limit,
  });

  /// Translate message
  Future<void> translateMessage({
    required String messageId,
    required String conversationId,
    required String translatedContent,
    required String detectedLanguage,
  });

  /// Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required String conversationId,
    required MessageStatus status,
  });
}

/// Implementation
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl({required this.firestore});

  @override
  Future<ConversationModel> getConversation(String matchId) async {
    try {
      // Check if conversation exists
      final querySnapshot = await firestore
          .collection('conversations')
          .where('matchId', isEqualTo: matchId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ConversationModel.fromFirestore(querySnapshot.docs.first);
      }

      // Get match details to create conversation
      final matchDoc = await firestore.collection('matches').doc(matchId).get();

      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }

      final matchData = matchDoc.data()!;
      final userId1 = matchData['userId1'] as String;
      final userId2 = matchData['userId2'] as String;

      // Create new conversation
      final conversationRef = firestore.collection('conversations').doc();

      final newConversation = ConversationModel(
        conversationId: conversationRef.id,
        matchId: matchId,
        userId1: userId1,
        userId2: userId2,
        createdAt: DateTime.now(),
        unreadCount: 0,
      );

      await conversationRef.set(newConversation.toFirestore());

      return newConversation;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream({
    required String conversationId,
    int? limit,
  }) {
    Query query = firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<MessageModel> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
  }) async {
    try {
      // Get or create conversation
      final conversation = await getConversation(matchId);

      // Create message
      final messageRef = firestore
          .collection('conversations')
          .doc(conversation.conversationId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        messageId: messageRef.id,
        matchId: matchId,
        conversationId: conversation.conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        sentAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        status: MessageStatus.sent,
      );

      // Save message
      await messageRef.set(message.toFirestore());

      // Update conversation with last message
      await firestore
          .collection('conversations')
          .doc(conversation.conversationId)
          .update({
        'lastMessage': {
          'messageId': message.messageId,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'content': message.content,
          'type': message.type.value,
          'sentAt': Timestamp.fromDate(message.sentAt),
        },
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'unreadCount': FieldValue.increment(1),
      });

      // Update match with last message info
      await firestore.collection('matches').doc(matchId).update({
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'lastMessage': content,
      });

      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String conversationId,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final batch = firestore.batch();

      // Get all unread messages
      final messagesSnapshot = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('readAt', isNull: true)
          .get();

      // Mark all as read
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Reset unread count
      batch.update(
        firestore.collection('conversations').doc(conversationId),
        {'unreadCount': 0},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  @override
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return firestore
        .collection('conversations')
        .where(Filter.or(
          Filter('userId1', isEqualTo: userId),
          Filter('userId2', isEqualTo: userId),
        ))
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> setTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await firestore.collection('conversations').doc(conversationId).update({
        'isTyping': isTyping,
        'typingUserId': isTyping ? userId : null,
      });
    } catch (e) {
      throw Exception('Failed to set typing indicator: $e');
    }
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required String conversationId,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final conversationsSnapshot = await firestore
          .collection('conversations')
          .where(Filter.or(
            Filter('userId1', isEqualTo: userId),
            Filter('userId2', isEqualTo: userId),
          ))
          .get();

      int totalUnread = 0;
      for (final doc in conversationsSnapshot.docs) {
        final data = doc.data();
        totalUnread += (data['unreadCount'] as int?) ?? 0;
      }

      return totalUnread;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String conversationId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': emoji,
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  @override
  Stream<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
    int? limit,
  }) {
    // Note: Firestore doesn't support text search natively
    // This is a basic implementation that filters on the client side
    // For production, consider using Algolia or ElasticSearch
    return getMessagesStream(conversationId: conversationId, limit: limit)
        .map((messages) {
      return messages
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Future<void> translateMessage({
    required String messageId,
    required String conversationId,
    required String translatedContent,
    required String detectedLanguage,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'translatedContent': translatedContent,
        'detectedLanguage': detectedLanguage,
      });
    } catch (e) {
      throw Exception('Failed to translate message: $e');
    }
  }

  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required String conversationId,
    required MessageStatus status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
      };

      // Update timestamps based on status
      if (status == MessageStatus.delivered && status != MessageStatus.read) {
        updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == MessageStatus.read) {
        updateData['readAt'] = Timestamp.fromDate(DateTime.now());
        updateData['deliveredAt'] ??= Timestamp.fromDate(DateTime.now());
      }

      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  /// Pin or unpin conversation (Point 118)
  Future<void> pinConversation({
    required String conversationId,
    required String userId,
    required bool isPinned,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isPinned': isPinned,
        'pinnedAt': isPinned ? Timestamp.fromDate(DateTime.now()) : null,
      };

      await firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to pin conversation: $e');
    }
  }

  /// Mute or unmute conversation (Point 119)
  Future<void> muteConversation({
    required String conversationId,
    required String userId,
    required bool isMuted,
    DateTime? mutedUntil,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isMuted': isMuted,
        'mutedUntil': isMuted && mutedUntil != null
            ? Timestamp.fromDate(mutedUntil)
            : null,
      };

      await firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to mute conversation: $e');
    }
  }

  /// Archive or unarchive conversation (Point 120)
  Future<void> archiveConversation({
    required String conversationId,
    required String userId,
    required bool isArchived,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isArchived': isArchived,
        'archivedAt': isArchived ? Timestamp.fromDate(DateTime.now()) : null,
      };

      await firestore
          .collection('conversations')
          .doc(conversationId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to archive conversation: $e');
    }
  }

  /// Update conversation theme (Point 117)
  Future<void> updateConversationTheme({
    required String conversationId,
    required String theme,
  }) async {
    try {
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'theme': theme});
    } catch (e) {
      throw Exception('Failed to update conversation theme: $e');
    }
  }
}
