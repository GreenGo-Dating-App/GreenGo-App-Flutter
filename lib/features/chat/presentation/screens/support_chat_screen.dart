import 'dart:io';
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';

/// Support Chat Screen
///
/// Dedicated screen for support conversations
/// Uses 'support_chats' collection to sync with admin panel
class SupportChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final bool isAdmin;

  const SupportChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    this.isAdmin = false,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _supportAgentName;
  String? _ticketStatus;
  String? _ticketSubject;
  String? _ticketCategory;

  // Pagination for infinite scroll
  static const int _pageSize = 100;
  List<QueryDocumentSnapshot> _messages = [];
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  DocumentSnapshot? _lastDocument;
  String? _ticketStartMessageId;

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _markAsRead();
    _loadInitialMessages();

    // Listen for scroll to load more
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when reaching the top (since list is reversed)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final query = _firestore
          .collection('support_messages')
          .where('conversationId', isEqualTo: widget.conversationId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _messages = snapshot.docs;
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          _hasMoreMessages = snapshot.docs.length >= _pageSize;
        });

        // Find ticket start message
        for (final doc in _messages) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isTicketStart'] == true) {
            _ticketStartMessageId = doc.id;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading initial messages: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collection('support_messages')
          .where('conversationId', isEqualTo: widget.conversationId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _messages.addAll(snapshot.docs);
          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
          _hasMoreMessages = snapshot.docs.length >= _pageSize;
          _isLoadingMore = false;
        });

        // Check for ticket start message in newly loaded messages
        if (_ticketStartMessageId == null) {
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isTicketStart'] == true) {
              _ticketStartMessageId = doc.id;
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollToTicketStart() {
    if (_ticketStartMessageId == null) return;

    // Find the index of the ticket start message
    final index = _messages.indexWhere((doc) => doc.id == _ticketStartMessageId);
    if (index != -1 && _scrollController.hasClients) {
      // Since list is reversed, we scroll to position from the bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markAsRead() async {
    try {
      // Mark messages as read by the current viewer
      final senderTypeToMark = widget.isAdmin ? 'user' : 'admin';
      final readField = widget.isAdmin ? 'readByAdmin' : 'readByUser';

      final messagesSnapshot = await _firestore
          .collection('support_messages')
          .where('conversationId', isEqualTo: widget.conversationId)
          .where('senderType', isEqualTo: senderTypeToMark)
          .where(readField, isEqualTo: false)
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.update({readField: true});
      }

      // Reset unread count
      await _firestore
          .collection('support_chats')
          .doc(widget.conversationId)
          .update({widget.isAdmin ? 'adminUnreadCount' : 'unreadCount': 0});
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

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    final hasImage = imageUrl != null || _selectedImage != null;

    if (text.isEmpty && !hasImage) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final now = FieldValue.serverTimestamp();

      // Upload image if selected and not already uploaded
      String? finalImageUrl = imageUrl;
      if (_selectedImage != null && imageUrl == null) {
        finalImageUrl = await _uploadImage(_selectedImage!);
        if (finalImageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

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

      // Determine message type
      final String messageType = finalImageUrl != null ? 'image' : 'text';
      final String content = text.isNotEmpty ? text : (finalImageUrl != null ? '[Image]' : '');

      // Create message in support_messages collection (matches admin panel)
      final messageRef = _firestore.collection('support_messages').doc();
      await messageRef.set({
        'conversationId': widget.conversationId,
        'senderId': widget.currentUserId,
        'senderType': widget.isAdmin ? 'admin' : 'user',
        'senderName': userData['displayName'] ?? (widget.isAdmin ? 'Support' : 'User'),
        'senderAvatar': userData['photoUrls']?.isNotEmpty == true
            ? userData['photoUrls'][0]
            : null,
        'content': content,
        'messageType': messageType,
        if (finalImageUrl != null) 'imageUrl': finalImageUrl,
        'readByAdmin': widget.isAdmin ? true : false,
        'readByUser': widget.isAdmin ? false : true,
        'createdAt': now,
      });

      // Update conversation
      final conversationRef = _firestore
          .collection('support_chats')
          .doc(widget.conversationId);

      final conversationDoc = await conversationRef.get();
      final currentMessageCount = conversationDoc.data()?['messageCount'] ?? 0;

      final String lastMessagePreview = finalImageUrl != null
          ? '📷 ${text.isNotEmpty ? text : 'Image'}'
          : (text.length > 100 ? text.substring(0, 100) : text);

      await conversationRef.update({
        'lastMessage': lastMessagePreview,
        'lastMessageAt': now,
        'lastMessageBy': widget.isAdmin ? 'admin' : 'user',
        'messageCount': currentMessageCount + 1,
        'updatedAt': now,
        'status': 'open', // Reopen if it was pending
      });

      _messageController.clear();
      _clearSelectedImage();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatSupportFailedToSend(e.toString())),
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

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.chatSupportAddAttachment,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: AppLocalizations.of(context)!.chatAttachCamera,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: AppLocalizations.of(context)!.chatAttachGallery,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.richGold, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatFailedToPickImage(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('support_attachments/${widget.conversationId}/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  String _getStatusDisplayText() {
    final l10n = AppLocalizations.of(context)!;
    switch (_ticketStatus) {
      case 'open':
        return l10n.chatSupportStatusOpen;
      case 'pending':
        return l10n.chatSupportStatusPending;
      case 'resolved':
        return l10n.chatSupportStatusResolved;
      case 'closed':
        return l10n.chatSupportStatusClosed;
      default:
        return l10n.chatSupportStatusDefault;
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
                Text(
                  AppLocalizations.of(context)!.chatSupportTitle,
                  style: const TextStyle(
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
                AppLocalizations.of(context)!.chatSupportAgent(_supportAgentName!),
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
          // Messages list with real-time updates
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('support_messages')
                  .where('conversationId', isEqualTo: widget.conversationId)
                  .orderBy('createdAt', descending: true)
                  .limit(_pageSize)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                if (snapshot.hasError && _messages.isEmpty) {
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
                          AppLocalizations.of(context)!.chatSupportErrorLoading,
                          style: const TextStyle(color: AppColors.errorRed),
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

                // Merge stream data with paginated data
                final streamMessages = snapshot.data?.docs ?? [];
                final allMessages = <QueryDocumentSnapshot>[];

                // Add stream messages (most recent)
                allMessages.addAll(streamMessages);

                // Add older paginated messages that aren't in stream
                final streamIds = streamMessages.map((d) => d.id).toSet();
                for (final doc in _messages) {
                  if (!streamIds.contains(doc.id)) {
                    allMessages.add(doc);
                  }
                }

                if (allMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.chatSupportWelcome,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            AppLocalizations.of(context)!.chatSupportStartMessage,
                            style: const TextStyle(
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

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: allMessages.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Loading indicator at the end (top of chat)
                        if (index == allMessages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: AppColors.richGold,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }

                        final messageData = allMessages[index].data() as Map<String, dynamic>;
                        final isMe = messageData['senderId'] == widget.currentUserId;
                        final isSystem = messageData['messageType'] == 'system';
                        final isTicketStart = messageData['isTicketStart'] == true ||
                            messageData['messageType'] == 'ticket_creation';

                        return _buildMessageBubble(
                          messageData,
                          isMe,
                          isSystem,
                          isTicketStart: isTicketStart,
                        );
                      },
                    ),
                    // Scroll to ticket start button
                    if (_ticketStartMessageId != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _scrollToTicketStart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_upward, color: Colors.black, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.chatSupportTicketStart,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
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

  Widget _buildMessageBubble(
    Map<String, dynamic> messageData,
    bool isMe,
    bool isSystem, {
    bool isTicketStart = false,
  }) {
    final content = messageData['content'] as String? ?? '';
    final sentAt = messageData['createdAt'];
    final senderName = messageData['senderName'] as String?;
    final isAI = messageData['isAIGenerated'] == true;
    final messageType = messageData['messageType'] as String? ?? 'text';
    final imageUrl = messageData['imageUrl'] as String?;

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

    // Ticket start message styling
    if (isTicketStart) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.richGold.withOpacity(0.15),
              AppColors.richGold.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.richGold.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.confirmation_number,
                    color: AppColors.richGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.chatSupportTicketCreated,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Text(
              content.replaceAll('📋 **New Support Ticket**\n\n', '').replaceAll('**', ''),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
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
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show image if message type is image
                  if (messageType == 'image' && imageUrl != null)
                    GestureDetector(
                      onTap: () => _showFullScreenImage(imageUrl),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: MediaQuery.of(context).size.width * 0.65,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: 200,
                          color: AppColors.backgroundDark,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.richGold,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: 200,
                          color: AppColors.backgroundDark,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textTertiary,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Show text content (if any, and not just "[Image]")
                  if (content.isNotEmpty && content != '[Image]')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: isMe ? AppColors.deepBlack : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  // Timestamp
                  if (timestamp != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: (content.isEmpty || content == '[Image]') ? 10 : 0,
                        bottom: 10,
                      ),
                      child: Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          color: (isMe ? AppColors.deepBlack : AppColors.textSecondary)
                              .withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
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
                Text(
                  AppLocalizations.of(context)!.chatSupportTicketResolved,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _reopenTicket(),
              child: Text(
                AppLocalizations.of(context)!.chatSupportReopenTicket,
                style: const TextStyle(
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
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected image preview
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _clearSelectedImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.richGold,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Input row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Attachment button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                      onPressed: _isSending ? null : _showImagePickerOptions,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: _selectedImage != null
                              ? AppLocalizations.of(context)!.chatSupportAddCaptionOptional
                              : AppLocalizations.of(context)!.chatSupportTypeMessage,
                          hintStyle: const TextStyle(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
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
                      icon: (_isSending || _isUploadingImage)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.deepBlack,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: AppColors.deepBlack),
                      onPressed: (_isSending || _isUploadingImage) ? null : _sendMessage,
                    ),
                  ),
                ],
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatSupportTicketReopened),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatSupportFailedToReopen(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) {
      return l10n.chatSupportJustNow;
    } else if (diff.inHours < 1) {
      return l10n.chatSupportMinutesAgo(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return l10n.chatSupportHoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.chatSupportDaysAgo(diff.inDays);
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
                Text(
                  AppLocalizations.of(context)!.chatSupportTicketInfo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(AppLocalizations.of(context)!.chatSupportSubject, _ticketSubject ?? AppLocalizations.of(context)!.chatSupportGeneralSupport),
            _buildInfoRow(AppLocalizations.of(context)!.chatSupportCategory, _ticketCategory ?? AppLocalizations.of(context)!.chatSupportGeneral),
            _buildInfoRow(AppLocalizations.of(context)!.chatSupportStatus, _getStatusDisplayText()),
            _buildInfoRow(AppLocalizations.of(context)!.chatSupportAgentLabel, _supportAgentName ?? AppLocalizations.of(context)!.chatSupportWaitingAssignment),
            _buildInfoRow(AppLocalizations.of(context)!.chatSupportTicketId, widget.conversationId.substring(0, 8).toUpperCase()),
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
                child: Text(AppLocalizations.of(context)!.chatSupportClose),
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
