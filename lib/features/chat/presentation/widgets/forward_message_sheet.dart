import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message.dart';
import '../../data/datasources/chat_remote_datasource.dart';

/// Bottom sheet for forwarding a message to other conversations
class ForwardMessageSheet extends StatefulWidget {
  final Message message;
  final String currentUserId;
  final String fromConversationId;

  const ForwardMessageSheet({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.fromConversationId,
  });

  /// Show the forward message sheet
  static Future<void> show(
    BuildContext context, {
    required Message message,
    required String currentUserId,
    required String fromConversationId,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ForwardMessageSheet(
          message: message,
          currentUserId: currentUserId,
          fromConversationId: fromConversationId,
        ),
      ),
    );
  }

  @override
  State<ForwardMessageSheet> createState() => _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends State<ForwardMessageSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMatchIds = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ChatRemoteDataSourceImpl _chatDataSource;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    _chatDataSource = ChatRemoteDataSourceImpl(firestore: _firestore);
    _loadConversations();
    _searchController.addListener(_filterConversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      // Get all matches for the current user
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'matched')
          .get();

      final conversations = <Map<String, dynamic>>[];

      for (final matchDoc in matchesSnapshot.docs) {
        final matchData = matchDoc.data();
        final userId1 = matchData['userId1'] as String;
        final userId2 = matchData['userId2'] as String;

        // Only include matches where current user is a participant
        if (userId1 != widget.currentUserId && userId2 != widget.currentUserId) {
          continue;
        }

        // Skip the current conversation
        if (matchDoc.id == widget.message.matchId) {
          continue;
        }

        final otherUserId = userId1 == widget.currentUserId ? userId2 : userId1;

        // Get other user's profile
        final profileSnapshot = await _firestore
            .collection('profiles')
            .doc(otherUserId)
            .get();

        if (profileSnapshot.exists) {
          final profileData = profileSnapshot.data()!;
          conversations.add({
            'matchId': matchDoc.id,
            'userId': otherUserId,
            'displayName': profileData['displayName'] ?? 'User',
            'nickname': profileData['nickname'],
            'photoUrl': profileData['photoUrls']?.isNotEmpty == true
                ? profileData['photoUrls'][0]
                : null,
            'lastMessage': matchData['lastMessage'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filteredConversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredConversations = _conversations;
      });
      return;
    }

    setState(() {
      _filteredConversations = _conversations.where((conv) {
        final name = (conv['displayName'] as String).toLowerCase();
        final nickname = (conv['nickname'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || nickname.contains(query);
      }).toList();
    });
  }

  void _toggleSelection(String matchId) {
    setState(() {
      if (_selectedMatchIds.contains(matchId)) {
        _selectedMatchIds.remove(matchId);
      } else {
        _selectedMatchIds.add(matchId);
      }
    });
  }

  Future<void> _forwardMessage() async {
    if (_selectedMatchIds.isEmpty) return;

    setState(() {
      _isForwarding = true;
    });

    try {
      await _chatDataSource.forwardMessage(
        messageId: widget.message.messageId,
        fromConversationId: widget.fromConversationId,
        senderId: widget.currentUserId,
        toMatchIds: _selectedMatchIds.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message forwarded to ${_selectedMatchIds.length} conversation${_selectedMatchIds.length > 1 ? 's' : ''}',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isForwarding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to forward message: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border(
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Forward Message',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: _selectedMatchIds.isNotEmpty && !_isForwarding
                        ? _forwardMessage
                        : null,
                    child: _isForwarding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.richGold,
                            ),
                          )
                        : Text(
                            'Send (${_selectedMatchIds.length})',
                            style: TextStyle(
                              color: _selectedMatchIds.isNotEmpty
                                  ? AppColors.richGold
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Message preview
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.reply,
                color: AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message.content.length > 100
                      ? '${widget.message.content.substring(0, 100)}...'
                      : widget.message.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Conversation list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                )
              : _filteredConversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No conversations to forward to'
                                : 'No matching conversations',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conv = _filteredConversations[index];
                        final matchId = conv['matchId'] as String;
                        final isSelected = _selectedMatchIds.contains(matchId);

                        return _buildConversationTile(conv, isSelected);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv, bool isSelected) {
    final matchId = conv['matchId'] as String;
    final displayName = conv['displayName'] as String;
    final nickname = conv['nickname'] as String?;
    final photoUrl = conv['photoUrl'] as String?;

    return ListTile(
      onTap: () => _toggleSelection(matchId),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.backgroundDark,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: AppColors.textTertiary)
                : null,
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.richGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundCard, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        displayName,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: nickname != null
          ? Text(
              '@$nickname',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.richGold)
          : const Icon(Icons.circle_outlined, color: AppColors.textTertiary),
    );
  }
}
