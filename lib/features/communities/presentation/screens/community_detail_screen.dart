import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_message.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/community_message_bubble.dart';
import '../widgets/community_member_tile.dart';

/// Community Detail Screen
///
/// Shows the community group chat, members, and info.
/// Allows joining/leaving and sending messages.
class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String _currentUserName = '';
  String? _currentUserPhoto;
  bool _isLocalGuide = false;
  List<String> _userLanguages = [];
  bool _isMember = false;
  CommunityMessageType _selectedMessageType = CommunityMessageType.text;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserInfo();
    _loadCommunityDetail();
  }

  void _loadUserInfo() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      _currentUserName = profileState.profile.displayName;
      _currentUserPhoto = profileState.profile.photoUrls.isNotEmpty
          ? profileState.profile.photoUrls.first
          : null;
      _isLocalGuide = profileState.profile.isLocalGuide;
      _userLanguages = profileState.profile.preferredLanguages;
    }
  }

  void _loadCommunityDetail() {
    context.read<CommunitiesBloc>().add(
          LoadCommunityDetail(communityId: widget.community.id),
        );

    // Subscribe to message stream
    context.read<CommunitiesBloc>().add(
          SubscribeToCommunityMessages(communityId: widget.community.id),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: BlocConsumer<CommunitiesBloc, CommunitiesState>(
        listener: (context, state) {
          if (state is CommunityJoined) {
            setState(() => _isMember = true);
            _loadCommunityDetail();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Joined community!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          } else if (state is CommunityLeft) {
            setState(() => _isMember = false);
            Navigator.of(context).pop();
          } else if (state is CommunitiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          } else if (state is CommunityDetailLoaded) {
            // Check membership
            final userId = _currentUserId;
            if (userId != null) {
              final isMember =
                  state.members.any((m) => m.userId == userId);
              if (mounted) {
                setState(() => _isMember = isMember);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is CommunitiesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (state is CommunityDetailLoaded) {
            return Column(
              children: [
                // Messages list
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyChat()
                      : _buildMessagesList(state.messages),
                ),

                // Message input or join button
                if (_isMember)
                  _buildMessageInput(state)
                else
                  _buildJoinBar(),
              ],
            );
          }

          return const Center(
            child: Text(
              'Unable to load community',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.community.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${widget.community.memberCount} members',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        // Members list button
        IconButton(
          icon: const Icon(Icons.people_outline, color: AppColors.textSecondary),
          onPressed: () => _showMembersSheet(),
        ),
        // Info / More button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          color: AppColors.backgroundCard,
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showCommunityInfo();
                break;
              case 'leave':
                _confirmLeave();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 12),
                  Text('Community Info',
                      style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (_isMember)
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: AppColors.errorRed, size: 20),
                    SizedBox(width: 12),
                    Text('Leave Community',
                        style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<CommunityMessage> messages) {
    // Messages come in reverse order (newest first) from Firestore
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == _currentUserId;

        // Determine if we should show sender info (group chat style)
        bool showSenderInfo = true;
        if (index < messages.length - 1) {
          final prevMessage = messages[index + 1]; // Previous in display (next in list)
          if (prevMessage.senderId == message.senderId) {
            showSenderInfo = false;
          }
        }

        return CommunityMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          showSenderInfo: showSenderInfo,
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to say something!',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(CommunityDetailLoaded state) {
    // For local guide communities, non-guides can only send regular text
    final isLocalGuideCommunity =
        widget.community.type == CommunityType.localGuides;
    final canPostCityTip = isLocalGuideCommunity && _isLocalGuide;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message type selector (for authorized users)
            if (canPostCityTip || !isLocalGuideCommunity)
              _buildMessageTypeSelector(canPostCityTip),

            Row(
              children: [
                // Message input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.backgroundInput,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: state.isSending ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: state.isSending
                          ? AppColors.richGold.withValues(alpha: 0.5)
                          : AppColors.richGold,
                      shape: BoxShape.circle,
                    ),
                    child: state.isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepBlack,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.deepBlack,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeSelector(bool canPostCityTip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeChip(
              label: 'Text',
              icon: Icons.chat_bubble_outline,
              type: CommunityMessageType.text,
            ),
            const SizedBox(width: 6),
            _buildTypeChip(
              label: 'Language Tip',
              icon: Icons.lightbulb_outline,
              type: CommunityMessageType.languageTip,
            ),
            const SizedBox(width: 6),
            _buildTypeChip(
              label: 'Cultural Fact',
              icon: Icons.auto_awesome,
              type: CommunityMessageType.culturalFact,
            ),
            if (canPostCityTip) ...[
              const SizedBox(width: 6),
              _buildTypeChip(
                label: 'City Tip',
                icon: Icons.location_on,
                type: CommunityMessageType.cityTip,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required CommunityMessageType type,
  }) {
    final isSelected = _selectedMessageType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMessageType = type);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.richGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.richGold : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.richGold : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _joinCommunity,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            child: const Text(
              'Join Community',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedMessageType) {
      case CommunityMessageType.text:
        return 'Type a message...';
      case CommunityMessageType.languageTip:
        return 'Share a language tip...';
      case CommunityMessageType.culturalFact:
        return 'Share a cultural fact...';
      case CommunityMessageType.cityTip:
        return 'Share a city tip...';
      default:
        return 'Type a message...';
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userId = _currentUserId;
    if (userId == null) return;

    context.read<CommunitiesBloc>().add(
          SendCommunityMessage(
            communityId: widget.community.id,
            senderId: userId,
            senderName: _currentUserName,
            senderPhotoUrl: _currentUserPhoto,
            content: content,
            type: _selectedMessageType,
          ),
        );

    _messageController.clear();
    setState(() => _selectedMessageType = CommunityMessageType.text);
    HapticFeedback.lightImpact();
  }

  void _joinCommunity() {
    final userId = _currentUserId;
    if (userId == null) return;

    context.read<CommunitiesBloc>().add(
          JoinCommunity(
            communityId: widget.community.id,
            userId: userId,
            displayName: _currentUserName,
            photoUrl: _currentUserPhoto,
            languages: _userLanguages,
            isLocalGuide: _isLocalGuide,
          ),
        );

    HapticFeedback.mediumImpact();
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Leave Community',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to leave "${widget.community.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final userId = _currentUserId;
              if (userId != null) {
                this.context.read<CommunitiesBloc>().add(
                      LeaveCommunity(
                        communityId: widget.community.id,
                        userId: userId,
                      ),
                    );
              }
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersSheet() {
    final state = context.read<CommunitiesBloc>().state;
    if (state is! CommunityDetailLoaded) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${state.members.length})',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.divider, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: state.members.length,
                    itemBuilder: (context, index) {
                      return CommunityMemberTile(
                        member: state.members[index],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommunityInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Community name
                  Text(
                    widget.community.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.community.type.displayName,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.community.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Languages
                  if (widget.community.languages.isNotEmpty) ...[
                    const Text(
                      'Languages',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.community.languages.map((lang) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (widget.community.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.community.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // City / Country
                  if (widget.community.city != null ||
                      widget.community.country != null) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textTertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          [
                            widget.community.city,
                            widget.community.country,
                          ].whereType<String>().join(', '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats
                  const Text(
                    'Stats',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.people_outline,
                        '${widget.community.memberCount}',
                        'Members',
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        Icons.calendar_today_outlined,
                        _formatDate(widget.community.createdAt),
                        'Created',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Created by
                  Text(
                    'Created by ${widget.community.createdByName}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
