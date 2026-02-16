import 'package:equatable/equatable.dart';
import 'message.dart';

/// Chat Theme Options
enum ChatTheme {
  gold,    // Default gold theme
  silver,  // Silver theme
  dark,    // Dark mode
  light,   // Light mode
  rose,    // Rose gold
  ocean,   // Ocean blue
}

/// Conversation Type Options
enum ConversationType {
  match,    // Regular match conversation between two users
  support,  // Support conversation between user and support agent
}

/// Support Ticket Priority
enum SupportPriority {
  low,
  medium,
  high,
  urgent,
}

/// Support Ticket Status
enum SupportTicketStatus {
  open,       // New ticket, not yet assigned
  assigned,   // Assigned to support agent
  inProgress, // Being worked on
  waitingOnUser, // Waiting for user response
  resolved,   // Resolved
  closed,     // Closed
}

/// Conversation Entity
///
/// Represents a chat conversation between two matched users
class Conversation extends Equatable {
  final String conversationId;
  final String matchId;
  final String userId1;
  final String userId2;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isTyping;
  final String? typingUserId;
  final DateTime createdAt;

  // Point 118: Conversation Pinning
  final bool isPinned;
  final DateTime? pinnedAt;

  // Point 119: Conversation Muting
  final bool isMuted;
  final DateTime? mutedUntil; // null = muted indefinitely

  // Point 120: Conversation Archiving
  final bool isArchived;
  final DateTime? archivedAt;

  // Point 117: Chat Themes
  final ChatTheme theme;

  // Additional settings
  final Map<String, dynamic>? settings;

  // Conversation type (match or support)
  final ConversationType conversationType;

  // Support-specific fields (only used when conversationType is support)
  final String? supportAgentId;       // Assigned support agent
  final SupportPriority? supportPriority;
  final SupportTicketStatus? supportTicketStatus;
  final String? supportCategory;       // e.g., "billing", "technical", "account"
  final String? supportSubject;        // User's initial subject/topic
  final DateTime? supportResolvedAt;   // When the ticket was resolved

  // Deletion tracking
  final bool isDeleted;
  final Map<String, dynamic>? deletedFor; // userId → Timestamp of deletion

  const Conversation({
    required this.conversationId,
    required this.matchId,
    required this.userId1,
    required this.userId2,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingUserId,
    required this.createdAt,
    this.isPinned = false,
    this.pinnedAt,
    this.isMuted = false,
    this.mutedUntil,
    this.isArchived = false,
    this.archivedAt,
    this.theme = ChatTheme.gold,
    this.settings,
    this.conversationType = ConversationType.match,
    this.supportAgentId,
    this.supportPriority,
    this.supportTicketStatus,
    this.supportCategory,
    this.supportSubject,
    this.supportResolvedAt,
    this.isDeleted = false,
    this.deletedFor,
  });

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  /// Check if user is typing
  bool isOtherUserTyping(String currentUserId) {
    return isTyping && typingUserId != currentUserId;
  }

  /// Check if there are unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if this is a support conversation
  bool get isSupportConversation => conversationType == ConversationType.support;

  /// Check if this is a match conversation
  bool get isMatchConversation => conversationType == ConversationType.match;

  /// Check if support ticket is resolved
  bool get isSupportResolved =>
      supportTicketStatus == SupportTicketStatus.resolved ||
      supportTicketStatus == SupportTicketStatus.closed;

  /// Check if mute is active
  bool get isCurrentlyMuted {
    if (!isMuted) return false;
    if (mutedUntil == null) return true; // Muted indefinitely
    return DateTime.now().isBefore(mutedUntil!);
  }

  /// Get theme colors
  Map<String, dynamic> get themeColors {
    switch (theme) {
      case ChatTheme.gold:
        return {
          'primary': '#D4AF37',
          'secondary': '#F5F5DC',
          'bubble': '#D4AF37',
          'text': '#FFFFFF',
        };
      case ChatTheme.silver:
        return {
          'primary': '#C0C0C0',
          'secondary': '#F5F5F5',
          'bubble': '#C0C0C0',
          'text': '#000000',
        };
      case ChatTheme.dark:
        return {
          'primary': '#1E1E1E',
          'secondary': '#2C2C2C',
          'bubble': '#3A3A3A',
          'text': '#FFFFFF',
        };
      case ChatTheme.light:
        return {
          'primary': '#FFFFFF',
          'secondary': '#F8F8F8',
          'bubble': '#E3E3E3',
          'text': '#000000',
        };
      case ChatTheme.rose:
        return {
          'primary': '#E0BFB8',
          'secondary': '#FFF5F3',
          'bubble': '#E0BFB8',
          'text': '#FFFFFF',
        };
      case ChatTheme.ocean:
        return {
          'primary': '#4A90E2',
          'secondary': '#E6F2FF',
          'bubble': '#4A90E2',
          'text': '#FFFFFF',
        };
    }
  }

  /// Get last message preview text
  String get lastMessagePreview {
    if (lastMessage == null) {
      return 'Say hi to your match!';
    }

    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.gif:
        return 'GIF';
      case MessageType.sticker:
        return '✨ Sticker';
      case MessageType.voiceNote:
        return '🎤 Voice message';
      case MessageType.system:
        return lastMessage!.content;
    }
  }

  /// Get time since last message
  String get timeSinceLastMessage {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${lastMessageAt!.month}/${lastMessageAt!.day}';
    }
  }

  /// Copy with updated fields
  Conversation copyWith({
    String? conversationId,
    String? matchId,
    String? userId1,
    String? userId2,
    Message? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isTyping,
    String? typingUserId,
    DateTime? createdAt,
    bool? isPinned,
    DateTime? pinnedAt,
    bool? isMuted,
    DateTime? mutedUntil,
    bool? isArchived,
    DateTime? archivedAt,
    ChatTheme? theme,
    Map<String, dynamic>? settings,
    ConversationType? conversationType,
    String? supportAgentId,
    SupportPriority? supportPriority,
    SupportTicketStatus? supportTicketStatus,
    String? supportCategory,
    String? supportSubject,
    DateTime? supportResolvedAt,
    bool? isDeleted,
    Map<String, dynamic>? deletedFor,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      matchId: matchId ?? this.matchId,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      theme: theme ?? this.theme,
      settings: settings ?? this.settings,
      conversationType: conversationType ?? this.conversationType,
      supportAgentId: supportAgentId ?? this.supportAgentId,
      supportPriority: supportPriority ?? this.supportPriority,
      supportTicketStatus: supportTicketStatus ?? this.supportTicketStatus,
      supportCategory: supportCategory ?? this.supportCategory,
      supportSubject: supportSubject ?? this.supportSubject,
      supportResolvedAt: supportResolvedAt ?? this.supportResolvedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
    );
  }

  @override
  List<Object?> get props => [
        conversationId,
        matchId,
        userId1,
        userId2,
        lastMessage,
        lastMessageAt,
        unreadCount,
        isTyping,
        typingUserId,
        createdAt,
        isPinned,
        pinnedAt,
        isMuted,
        mutedUntil,
        isArchived,
        archivedAt,
        theme,
        settings,
        conversationType,
        supportAgentId,
        supportPriority,
        supportTicketStatus,
        supportCategory,
        supportSubject,
        supportResolvedAt,
        isDeleted,
        deletedFor,
      ];
}
