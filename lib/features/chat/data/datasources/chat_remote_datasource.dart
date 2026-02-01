import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/content_filter_service.dart';
import '../../domain/entities/conversation.dart';
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
    String? userId,
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

  /// Report a message
  Future<void> reportMessage({
    required String messageId,
    required String conversationId,
    required String reporterId,
    required String reportedUserId,
    required String reason,
  });

  /// Get messages around a reported message (50 before and 50 after)
  Future<List<MessageModel>> getMessagesAroundMessage({
    required String conversationId,
    required String messageId,
    int contextCount = 50,
  });

  /// Block a user
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String reason,
  });

  /// Unblock a user
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  });

  /// Check if user is blocked
  Future<bool> isUserBlocked({
    required String userId,
    required String otherUserId,
  });

  /// Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? conversationId,
    String? messageId,
    String? additionalDetails,
  });

  /// Star/unstar a message
  Future<void> starMessage({
    required String messageId,
    required String conversationId,
    required String userId,
    required bool isStarred,
  });

  /// Get starred messages for a user
  Future<List<MessageModel>> getStarredMessages({
    required String userId,
    int? limit,
  });

  /// Forward a message to multiple conversations
  Future<void> forwardMessage({
    required String messageId,
    required String fromConversationId,
    required String senderId,
    required List<String> toMatchIds,
  });

  /// Delete conversation for current user only
  Future<void> deleteConversationForMe({
    required String conversationId,
    required String userId,
  });

  /// Delete all messages in conversation for both users
  Future<void> deleteConversationForBoth({
    required String conversationId,
    required String userId,
  });

  /// Delete a specific message for current user only
  Future<void> deleteMessageForMe({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  /// Delete a specific message for both users
  Future<void> deleteMessageForBoth({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  // ============== Support Chat Methods ==============

  /// Create a support conversation for a user
  Future<ConversationModel> createSupportConversation({
    required String userId,
    required String subject,
    String? category,
    SupportPriority priority,
  });

  /// Get user's active support conversation (if any)
  Future<ConversationModel?> getActiveSupportConversation(String userId);

  /// Get all support conversations (for support agents)
  Stream<List<ConversationModel>> getSupportConversationsStream({
    SupportTicketStatus? filterStatus,
    String? assignedAgentId,
  });

  /// Assign support conversation to agent
  Future<void> assignSupportAgent({
    required String conversationId,
    required String agentId,
  });

  /// Update support ticket status
  Future<void> updateSupportTicketStatus({
    required String conversationId,
    required SupportTicketStatus status,
    String? resolvedByAgentId,
  });

  /// Get support agent profile
  Future<Map<String, dynamic>?> getSupportAgentProfile(String agentId);

  /// Get available support agents
  Future<List<Map<String, dynamic>>> getAvailableSupportAgents();
}

/// Implementation
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final ContentFilterService _contentFilter = ContentFilterService();

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
    String? userId,
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
      var messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();

      // Filter out messages deleted for this user (client-side filtering)
      if (userId != null) {
        messages = messages.where((message) {
          final metadata = message.metadata;
          if (metadata == null) return true;

          // Check if message is deleted for this user
          final deletedFor = metadata['deletedFor'] as Map<String, dynamic>?;
          if (deletedFor != null && deletedFor[userId] == true) {
            return false;
          }

          // Check if message is deleted for everyone
          if (metadata['isDeletedForEveryone'] == true) {
            return false;
          }

          return true;
        }).toList();
      }

      return messages;
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
      // Check for contact information in the message
      if (type == MessageType.text) {
        final filterResult = _contentFilter.analyzeContent(content);
        if (filterResult.hasContactInfo) {
          throw ContactInfoBlockedException(
            'Message blocked: Contains ${filterResult.violations.join(', ')}',
            filterResult.violations,
          );
        }
      }

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

      // Check if this is the first message in conversation (new chat notification)
      // Count total messages in conversation
      final messagesCount = await firestore
          .collection('conversations')
          .doc(conversation.conversationId)
          .collection('messages')
          .count()
          .get();

      // Get sender profile for notification
      final senderProfile = await firestore.collection('profiles').doc(senderId).get();
      final senderNickname = senderProfile.data()?['nickname'] as String? ?? '';
      final senderName = senderProfile.data()?['displayName'] as String? ?? 'Someone';

      if (messagesCount.count == 1) {
        // First message - create new_chat notification
        final displayName = senderNickname.isNotEmpty ? '@$senderNickname' : senderName;
        await _createNotification(
          userId: receiverId,
          type: 'new_chat',
          title: 'New Conversation',
          message: '$displayName started a conversation with you.',
          data: {
            'senderId': senderId,
            'senderNickname': senderNickname,
            'senderName': senderName,
            'matchId': matchId,
            'conversationId': conversation.conversationId,
          },
        );
      } else {
        // Regular message - create new_message notification
        final displayName = senderNickname.isNotEmpty ? '@$senderNickname' : senderName;
        await _createNotification(
          userId: receiverId,
          type: 'new_message',
          title: 'New Message',
          message: 'New message from $displayName',
          data: {
            'senderId': senderId,
            'senderNickname': senderNickname,
            'senderName': senderName,
            'matchId': matchId,
            'conversationId': conversation.conversationId,
          },
        );
      }

      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Helper to create notifications
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      await firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      // Silently fail notification creation
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

  @override
  Future<void> reportMessage({
    required String messageId,
    required String conversationId,
    required String reporterId,
    required String reportedUserId,
    required String reason,
  }) async {
    try {
      // Get the message being reported
      final messageDoc = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;

      // Create report in reports collection
      final reportRef = firestore.collection('message_reports').doc();
      await reportRef.set({
        'reportId': reportRef.id,
        'messageId': messageId,
        'conversationId': conversationId,
        'messageContent': messageData['content'],
        'messageSentAt': messageData['sentAt'],
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'reportedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'pending', // pending, reviewed, action_taken, dismissed
        'reviewedBy': null,
        'reviewedAt': null,
        'actionTaken': null,
      });

      // Mark message as reported
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'isReported': true, 'reportId': reportRef.id});

    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessagesAroundMessage({
    required String conversationId,
    required String messageId,
    int contextCount = 50,
  }) async {
    try {
      // Get the target message to find its timestamp
      final targetMessageDoc = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!targetMessageDoc.exists) {
        throw Exception('Message not found');
      }

      final targetTimestamp = targetMessageDoc.data()!['sentAt'] as Timestamp;

      // Get messages before (older)
      final beforeQuery = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sentAt', isLessThan: targetTimestamp)
          .orderBy('sentAt', descending: true)
          .limit(contextCount)
          .get();

      // Get messages after (newer)
      final afterQuery = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sentAt', isGreaterThan: targetTimestamp)
          .orderBy('sentAt')
          .limit(contextCount)
          .get();

      // Combine results: before (reversed) + target + after
      final messages = <MessageModel>[];

      // Add before messages (reverse to chronological order)
      final beforeMessages = beforeQuery.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList()
          .reversed;
      messages.addAll(beforeMessages);

      // Add target message
      messages.add(MessageModel.fromFirestore(targetMessageDoc));

      // Add after messages
      final afterMessages = afterQuery.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      messages.addAll(afterMessages);

      return messages;
    } catch (e) {
      throw Exception('Failed to get messages around message: $e');
    }
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String reason,
  }) async {
    try {
      final blockRef = firestore.collection('blocked_users').doc();
      await blockRef.set({
        'blockId': blockRef.id,
        'blockerId': blockerId,
        'blockedUserId': blockedUserId,
        'reason': reason,
        'blockedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Also add to user's blocked list for quick lookup
      await firestore.collection('users').doc(blockerId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      // Find and delete the block record
      final blockQuery = await firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (final doc in blockQuery.docs) {
        await doc.reference.delete();
      }

      // Remove from user's blocked list
      await firestore.collection('users').doc(blockerId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  @override
  Future<bool> isUserBlocked({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      // Check if either user has blocked the other
      final blockQuery = await firestore
          .collection('blocked_users')
          .where('blockerId', whereIn: [userId, otherUserId])
          .get();

      for (final doc in blockQuery.docs) {
        final data = doc.data();
        final blockerId = data['blockerId'] as String;
        final blockedUserId = data['blockedUserId'] as String;

        // Check if userId blocked otherUserId or vice versa
        if ((blockerId == userId && blockedUserId == otherUserId) ||
            (blockerId == otherUserId && blockedUserId == userId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check block status: $e');
    }
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? conversationId,
    String? messageId,
    String? additionalDetails,
  }) async {
    try {
      final reportRef = firestore.collection('user_reports').doc();

      final reportData = <String, dynamic>{
        'reportId': reportRef.id,
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'reportedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'pending', // pending, reviewed, action_taken, dismissed
        'reviewedBy': null,
        'reviewedAt': null,
        'actionTaken': null,
      };

      if (conversationId != null) {
        reportData['conversationId'] = conversationId;
      }
      if (messageId != null) {
        reportData['messageId'] = messageId;
      }
      if (additionalDetails != null) {
        reportData['additionalDetails'] = additionalDetails;
      }

      await reportRef.set(reportData);

      // Increment reported count on user profile for moderation
      await firestore.collection('users').doc(reportedUserId).update({
        'reportCount': FieldValue.increment(1),
        'lastReportedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to report user: $e');
    }
  }

  @override
  Future<void> starMessage({
    required String messageId,
    required String conversationId,
    required String userId,
    required bool isStarred,
  }) async {
    try {
      if (isStarred) {
        // Add to starred messages collection
        await firestore
            .collection('users')
            .doc(userId)
            .collection('starred_messages')
            .doc(messageId)
            .set({
          'messageId': messageId,
          'conversationId': conversationId,
          'starredAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Remove from starred messages collection
        await firestore
            .collection('users')
            .doc(userId)
            .collection('starred_messages')
            .doc(messageId)
            .delete();
      }

      // Update message metadata
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'starredBy.$userId': isStarred ? true : FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to star message: $e');
    }
  }

  @override
  Future<List<MessageModel>> getStarredMessages({
    required String userId,
    int? limit,
  }) async {
    try {
      Query query = firestore
          .collection('users')
          .doc(userId)
          .collection('starred_messages')
          .orderBy('starredAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final starredSnapshot = await query.get();
      final messages = <MessageModel>[];

      for (final starredDoc in starredSnapshot.docs) {
        final data = starredDoc.data() as Map<String, dynamic>;
        final conversationId = data['conversationId'] as String;
        final messageId = data['messageId'] as String;

        final messageDoc = await firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId)
            .get();

        if (messageDoc.exists) {
          messages.add(MessageModel.fromFirestore(messageDoc));
        }
      }

      return messages;
    } catch (e) {
      throw Exception('Failed to get starred messages: $e');
    }
  }

  @override
  Future<void> forwardMessage({
    required String messageId,
    required String fromConversationId,
    required String senderId,
    required List<String> toMatchIds,
  }) async {
    try {
      // Get the original message
      final originalMessageDoc = await firestore
          .collection('conversations')
          .doc(fromConversationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!originalMessageDoc.exists) {
        throw Exception('Original message not found');
      }

      final originalMessage = MessageModel.fromFirestore(originalMessageDoc);

      // Forward to each match/conversation
      for (final matchId in toMatchIds) {
        // Get or create conversation for this match
        final conversation = await getConversation(matchId);

        // Get the receiver ID (the other user in the match)
        final matchDoc = await firestore.collection('matches').doc(matchId).get();
        if (!matchDoc.exists) continue;

        final matchData = matchDoc.data()!;
        final receiverId = matchData['userId1'] == senderId
            ? matchData['userId2'] as String
            : matchData['userId1'] as String;

        // Create forwarded message
        final messageRef = firestore
            .collection('conversations')
            .doc(conversation.conversationId)
            .collection('messages')
            .doc();

        final forwardedMessage = MessageModel(
          messageId: messageRef.id,
          matchId: matchId,
          conversationId: conversation.conversationId,
          senderId: senderId,
          receiverId: receiverId,
          content: originalMessage.content,
          type: originalMessage.type,
          sentAt: DateTime.now(),
          deliveredAt: DateTime.now(),
          status: MessageStatus.sent,
          metadata: {
            'isForwarded': true,
            'originalMessageId': messageId,
            'originalConversationId': fromConversationId,
          },
        );

        await messageRef.set(forwardedMessage.toFirestore());

        // Update conversation with last message
        await firestore
            .collection('conversations')
            .doc(conversation.conversationId)
            .update({
          'lastMessage': {
            'messageId': forwardedMessage.messageId,
            'senderId': forwardedMessage.senderId,
            'receiverId': forwardedMessage.receiverId,
            'content': forwardedMessage.content,
            'type': forwardedMessage.type.value,
            'sentAt': Timestamp.fromDate(forwardedMessage.sentAt),
          },
          'lastMessageAt': Timestamp.fromDate(forwardedMessage.sentAt),
          'unreadCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Failed to forward message: $e');
    }
  }

  @override
  Future<void> deleteConversationForMe({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Mark conversation as deleted for this user
      await firestore.collection('conversations').doc(conversationId).update({
        'deletedFor.$userId': Timestamp.fromDate(DateTime.now()),
      });

      // Mark all messages as deleted for this user
      final messagesSnapshot = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'deletedFor.$userId': true,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  @override
  Future<void> deleteConversationForBoth({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Get conversation to verify user is part of it
      final conversationDoc =
          await firestore.collection('conversations').doc(conversationId).get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final data = conversationDoc.data()!;
      final userId1 = data['userId1'] as String;
      final userId2 = data['userId2'] as String;

      if (userId != userId1 && userId != userId2) {
        throw Exception('User is not part of this conversation');
      }

      // Delete all messages in the conversation
      final messagesSnapshot = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Mark conversation as deleted
      batch.update(
        firestore.collection('conversations').doc(conversationId),
        {
          'isDeleted': true,
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'deletedBy': userId,
          'lastMessage': null,
          'unreadCount': 0,
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation for both: $e');
    }
  }

  @override
  Future<void> deleteMessageForMe({
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
        'deletedFor.$userId': true,
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<void> deleteMessageForBoth({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      final messageDoc = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;
      final senderId = messageData['senderId'] as String;

      // Only the sender can delete for both
      if (senderId != userId) {
        throw Exception('Only the sender can delete message for everyone');
      }

      // Check if message is within deletion time limit (e.g., 1 hour)
      final sentAt = (messageData['sentAt'] as Timestamp).toDate();
      final timeSinceSent = DateTime.now().difference(sentAt);
      const deletionTimeLimit = Duration(hours: 1);

      if (timeSinceSent > deletionTimeLimit) {
        throw Exception(
            'Cannot delete message for everyone after ${deletionTimeLimit.inMinutes} minutes');
      }

      // Mark as deleted for everyone
      await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeletedForEveryone': true,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'content': 'This message was deleted',
        'originalContent': messageData['content'],
      });
    } catch (e) {
      throw Exception('Failed to delete message for both: $e');
    }
  }

  // ============== Support Chat Methods Implementation ==============

  @override
  Future<ConversationModel> createSupportConversation({
    required String userId,
    required String subject,
    String? category,
    SupportPriority priority = SupportPriority.medium,
  }) async {
    try {
      // Check if user already has an active support conversation
      final existingConversation = await getActiveSupportConversation(userId);
      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new support conversation
      final conversationRef = firestore.collection('conversations').doc();

      // Use a special "support" matchId to indicate this is a support conversation
      const supportMatchId = 'support';

      final newConversation = ConversationModel(
        conversationId: conversationRef.id,
        matchId: supportMatchId,
        userId1: userId,
        userId2: 'support_system', // Placeholder until agent is assigned
        createdAt: DateTime.now(),
        unreadCount: 0,
        conversationType: ConversationType.support,
        supportPriority: priority,
        supportTicketStatus: SupportTicketStatus.open,
        supportCategory: category,
        supportSubject: subject,
      );

      await conversationRef.set(newConversation.toFirestore());

      // Create system message to start the conversation
      final messageRef = conversationRef.collection('messages').doc();
      await messageRef.set({
        'messageId': messageRef.id,
        'matchId': supportMatchId,
        'conversationId': conversationRef.id,
        'senderId': 'system',
        'receiverId': userId,
        'content': 'Welcome to GreenGo Support! A support agent will be with you shortly. Your ticket: $subject',
        'type': 'system',
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'status': 'sent',
      });

      return newConversation;
    } catch (e) {
      throw Exception('Failed to create support conversation: $e');
    }
  }

  @override
  Future<ConversationModel?> getActiveSupportConversation(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('conversations')
          .where('userId1', isEqualTo: userId)
          .where('conversationType', isEqualTo: 'support')
          .where('supportTicketStatus', whereIn: ['open', 'assigned', 'inProgress', 'waitingOnUser'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ConversationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get active support conversation: $e');
    }
  }

  @override
  Stream<List<ConversationModel>> getSupportConversationsStream({
    SupportTicketStatus? filterStatus,
    String? assignedAgentId,
  }) {
    Query query = firestore
        .collection('conversations')
        .where('conversationType', isEqualTo: 'support');

    if (filterStatus != null) {
      query = query.where('supportTicketStatus', isEqualTo: filterStatus.name);
    }

    if (assignedAgentId != null) {
      query = query.where('supportAgentId', isEqualTo: assignedAgentId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> assignSupportAgent({
    required String conversationId,
    required String agentId,
  }) async {
    try {
      await firestore.collection('conversations').doc(conversationId).update({
        'supportAgentId': agentId,
        'userId2': agentId, // Update userId2 to agent for messaging
        'supportTicketStatus': SupportTicketStatus.assigned.name,
      });

      // Create system message about agent assignment
      final messageRef = firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      // Get agent name
      final agentDoc = await firestore.collection('profiles').doc(agentId).get();
      final agentName = agentDoc.exists
          ? (agentDoc.data()?['displayName'] as String? ?? 'Support Agent')
          : 'Support Agent';

      await messageRef.set({
        'messageId': messageRef.id,
        'matchId': 'support',
        'conversationId': conversationId,
        'senderId': 'system',
        'receiverId': '',
        'content': '$agentName has joined the conversation and will assist you.',
        'type': 'system',
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'status': 'sent',
      });
    } catch (e) {
      throw Exception('Failed to assign support agent: $e');
    }
  }

  @override
  Future<void> updateSupportTicketStatus({
    required String conversationId,
    required SupportTicketStatus status,
    String? resolvedByAgentId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'supportTicketStatus': status.name,
      };

      if (status == SupportTicketStatus.resolved ||
          status == SupportTicketStatus.closed) {
        updateData['supportResolvedAt'] = Timestamp.fromDate(DateTime.now());
        if (resolvedByAgentId != null) {
          updateData['resolvedByAgentId'] = resolvedByAgentId;
        }
      }

      await firestore.collection('conversations').doc(conversationId).update(updateData);

      // Create system message about status change
      String statusMessage;
      switch (status) {
        case SupportTicketStatus.inProgress:
          statusMessage = 'Support agent is working on your issue.';
          break;
        case SupportTicketStatus.waitingOnUser:
          statusMessage = 'We\'re waiting for your response.';
          break;
        case SupportTicketStatus.resolved:
          statusMessage = 'Your issue has been resolved. Thank you for contacting GreenGo Support!';
          break;
        case SupportTicketStatus.closed:
          statusMessage = 'This support ticket has been closed.';
          break;
        default:
          statusMessage = 'Ticket status updated.';
      }

      final messageRef = firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'messageId': messageRef.id,
        'matchId': 'support',
        'conversationId': conversationId,
        'senderId': 'system',
        'receiverId': '',
        'content': statusMessage,
        'type': 'system',
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'status': 'sent',
      });
    } catch (e) {
      throw Exception('Failed to update support ticket status: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getSupportAgentProfile(String agentId) async {
    try {
      final profileDoc = await firestore.collection('profiles').doc(agentId).get();
      if (!profileDoc.exists) return null;

      final data = profileDoc.data()!;
      return {
        'userId': agentId,
        'displayName': data['displayName'] as String? ?? 'Support Agent',
        'photoUrl': data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty
            ? (data['photoUrls'] as List).first
            : null,
        'isSupport': data['isSupport'] as bool? ?? false,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableSupportAgents() async {
    try {
      final querySnapshot = await firestore
          .collection('profiles')
          .where('isSupport', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] as String? ?? 'Support Agent',
          'photoUrl': data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty
              ? (data['photoUrls'] as List).first
              : null,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Exception thrown when a message is blocked due to contact information
class ContactInfoBlockedException implements Exception {
  final String message;
  final List<String> violations;

  ContactInfoBlockedException(this.message, this.violations);

  @override
  String toString() => 'ContactInfoBlockedException: $message';
}
