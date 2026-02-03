import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

/// Support Chat Screen
///
/// Dedicated screen for support conversations
/// Uses 'support_chats' collection to sync with admin panel
class SupportChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;

  const SupportChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSending = false;
  String? _supportAgentName;
  String? _ticketStatus;
  String? _ticketSubject;
  String? _ticketCategory;

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    try {
      // Mark messages as read by user
      final messagesSnapshot = await _firestore
          .collection('support_messages')
          .where('conversationId', isEqualTo: widget.conversationId)
          .where('senderType', isEqualTo: 'admin')
          .where('readByUser', isEqualTo: false)
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.update({'readByUser': true});
      }

      // Reset unread count
      await _firestore
          .collection('support_chats')
          .doc(widget.conversationId)
          .update({'unreadCount': 0});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _loadConversationDetails() async {
    try {
      final doc = await _firestore
          .collection('support_chats')
          .doc(widget.conversationId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final agentId = data['assignedTo'] as String?;

        String? agentName = data['assignedToName'] as String?;
        if (agentName == null && agentId != null) {
          final agentProfile = await _firestore
              .collection('admins')
              .doc(agentId)
              .get();
          if (agentProfile.exists) {
            agentName = agentProfile.data()?['displayName'] as String?;
          }
        }

        setState(() {
          _supportAgentName = agentName;
          _ticketStatus = data['status'] as String? ?? 'open';
          _ticketSubject = data['subject'] as String?;
          _ticketCategory = data['category'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversation details: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final now = FieldValue.serverTimestamp();

      // Get user profile for sender info with defensive handling
      Map<String, dynamic> userData = {};
      try {
        final userProfile = await _firestore
            .collection('profiles')
            .doc(widget.currentUserId)
            .get();
        if (userProfile.exists) {
          userData = userProfile.data() ?? {};
        }
      } catch (e) {
        debugPrint('Could not fetch profile: $e');
        // Continue with empty userData - message sending should not be blocked
      }

      // Create message in support_messages collection (matches admin panel)
      final messageRef = _firestore.collection('support_messages').doc();
      await messageRef.set({
        'conversationId': widget.conversationId,
        'senderId': widget.currentUserId,
        'senderType': 'user',
        'senderName': userData['displayName'] ?? 'User',
        'senderAvatar': userData['photoUrls']?.isNotEmpty == true
            ? userData['photoUrls'][0]
            : null,
        'content': text,
        'messageType': 'text',
        'readByAdmin': false,
        'readByUser': true,
        'createdAt': now,
      });

      // Update conversation
      final conversationRef = _firestore
          .collection('support_chats')
          .doc(widget.conversationId);

      final conversationDoc = await conversationRef.get();
      final currentMessageCount = conversationDoc.data()?['messageCount'] ?? 0;

      await conversationRef.update({
        'lastMessage': text.length > 100 ? text.substring(0, 100) : text,
        'lastMessageAt': now,
        'lastMessageBy': 'user',
        'messageCount': currentMessageCount + 1,
        'updatedAt': now,
        'status': 'open', // Reopen if it was pending
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getStatusDisplayText() {
    switch (_ticketStatus) {
      case 'open':
        return 'Open';
      case 'pending':
        return 'Pending';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Support';
    }
  }

  Color _getStatusColor() {
    switch (_ticketStatus) {
      case 'open':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return AppColors.richGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'GreenGo Support',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplayText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_supportAgentName != null)
              Text(
                'Agent: $_supportAgentName',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.richGold),
            onPressed: () => _showTicketInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list - using support_messages collection
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('support_messages')
                  .where('conversationId', isEqualTo: widget.conversationId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Welcome to Support',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Send a message to start the conversation.\nOur team will respond as soon as possible.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderType'] == 'user';
                    final isSystem = messageData['messageType'] == 'system';

                    return _buildMessageBubble(messageData, isMe, isSystem);
                  },
                );
              },
            ),
          ),

          // Input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe, bool isSystem) {
    final content = messageData['content'] as String? ?? '';
    final sentAt = messageData['createdAt'];
    final senderName = messageData['senderName'] as String?;
    final isAI = messageData['isAIGenerated'] == true;

    DateTime? timestamp;
    if (sentAt is Timestamp) {
      timestamp = sentAt.toDate();
    }

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.richGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: AppColors.richGold, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name for support agent messages
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isAI) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.richGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isMe ? AppColors.richGold : AppColors.backgroundCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isMe ? AppColors.deepBlack : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        color: (isMe ? AppColors.deepBlack : AppColors.textSecondary)
                            .withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isClosed = _ticketStatus == 'resolved' || _ticketStatus == 'closed';

    if (isClosed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          border: Border(
            top: BorderSide(color: AppColors.divider.withOpacity(0.3)),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'This ticket has been resolved',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _reopenTicket(),
              child: const Text(
                'Need more help? Tap to reopen',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.richGold,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.deepBlack,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: AppColors.deepBlack),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reopenTicket() async {
    try {
      await _firestore
          .collection('support_chats')
          .doc(widget.conversationId)
          .update({
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _ticketStatus = 'open';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket reopened. You can send a message now.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reopen ticket: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _showTicketInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: AppColors.richGold),
                const SizedBox(width: 8),
                const Text(
                  'Ticket Information',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Subject', _ticketSubject ?? 'General Support'),
            _buildInfoRow('Category', _ticketCategory ?? 'General'),
            _buildInfoRow('Status', _getStatusDisplayText()),
            _buildInfoRow('Agent', _supportAgentName ?? 'Waiting for assignment'),
            _buildInfoRow('Ticket ID', widget.conversationId.substring(0, 8).toUpperCase()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
