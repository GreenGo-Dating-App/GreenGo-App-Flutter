import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';
import '../widgets/conversation_card.dart';
import 'chat_screen.dart';
import 'support_chat_screen.dart';

/// Conversations Screen
///
/// Displays list of user's conversations
class ConversationsScreen extends StatefulWidget {
  final String userId;

  const ConversationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  Conversation? _activeSupportConversation;
  bool _isLoadingSupport = true;
  bool _isCreatingSupport = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Profile?> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _loadActiveSupportConversation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSupportConversation() async {
    try {
      // Check if user already has an active support conversation
      final supportQuery = await FirebaseFirestore.instance
          .collection('conversations')
          .where('userId1', isEqualTo: widget.userId)
          .where('conversationType', isEqualTo: 'support')
          .where('supportTicketStatus', whereIn: ['open', 'assigned', 'inProgress', 'waitingOnUser'])
          .limit(1)
          .get();

      if (supportQuery.docs.isNotEmpty && mounted) {
        final doc = supportQuery.docs.first;
        final data = doc.data();
        setState(() {
          _activeSupportConversation = Conversation(
            conversationId: doc.id,
            matchId: data['matchId'] ?? '',
            userId1: data['userId1'],
            userId2: data['userId2'],
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            conversationType: ConversationType.support,
            supportTicketStatus: SupportTicketStatus.values.firstWhere(
              (s) => s.name == (data['supportTicketStatus'] as String? ?? 'open'),
              orElse: () => SupportTicketStatus.open,
            ),
            supportSubject: data['supportSubject'] as String?,
          );
          _isLoadingSupport = false;
        });
        return;
      }
      if (mounted) {
        setState(() {
          _isLoadingSupport = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading support conversation: $e');
      if (mounted) {
        setState(() {
          _isLoadingSupport = false;
        });
      }
    }
  }

  Future<void> _navigateToSupportChat(BuildContext context) async {
    setState(() {
      _isCreatingSupport = true;
    });

    try {
      String conversationId;

      if (_activeSupportConversation != null) {
        // Use existing conversation
        conversationId = _activeSupportConversation!.conversationId;
      } else {
        // Create new support conversation via Cloud Function
        final functions = FirebaseFunctions.instance;
        final result = await functions.httpsCallable('createSupportConversation').call({
          'subject': 'General Support',
          'category': 'general',
          'priority': 'medium',
        });

        conversationId = result.data['conversationId'] as String;

        // Reload the support conversation
        await _loadActiveSupportConversation();
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SupportChatScreen(
            conversationId: conversationId,
            currentUserId: widget.userId,
          ),
        ),
      );

      // Refresh after returning
      if (mounted) {
        await _loadActiveSupportConversation();
      }
    } catch (e) {
      debugPrint('Error navigating to support chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open support chat: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSupport = false;
        });
      }
    }
  }

  Future<Profile?> _getProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    final result = await di.sl<ProfileRepository>().getProfile(userId);
    final profile = result.fold((l) => null, (r) => r);
    _profileCache[userId] = profile;
    return profile;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name or @nickname',
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withOpacity(0.6),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textTertiary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.richGold),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    if (_isLoadingSupport) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.richGold, Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    final hasActiveTicket = _activeSupportConversation != null;
    String statusText = 'Tap to chat with us!';
    Color statusBadgeColor = Colors.green;
    String statusBadgeText = 'ONLINE';

    if (hasActiveTicket) {
      final status = _activeSupportConversation!.supportTicketStatus;
      switch (status) {
        case SupportTicketStatus.open:
          statusText = 'Waiting for agent...';
          statusBadgeColor = Colors.orange;
          statusBadgeText = 'PENDING';
          break;
        case SupportTicketStatus.assigned:
        case SupportTicketStatus.inProgress:
          statusText = 'Agent is helping you';
          statusBadgeColor = Colors.green;
          statusBadgeText = 'ACTIVE';
          break;
        case SupportTicketStatus.waitingOnUser:
          statusText = 'We need your response';
          statusBadgeColor = Colors.blue;
          statusBadgeText = 'WAITING';
          break;
        default:
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.richGold, Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreatingSupport ? null : () => _navigateToSupportChat(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: _isCreatingSupport
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.support_agent, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'GreenGo Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBadgeColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusBadgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ConversationsBloc>()
        ..add(ConversationsLoadRequested(widget.userId)),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            if (state is ConversationsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ConversationsBloc>()
                            .add(const ConversationsRefreshRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ConversationsEmpty) {
              return ListView(
                children: [
                  _buildSupportCard(context),
                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Start swiping and matching to chat with people!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (state is ConversationsLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ConversationsBloc>()
                      .add(const ConversationsRefreshRequested());
                },
                color: AppColors.richGold,
                child: CustomScrollView(
                  slivers: [
                    // Search bar
                    SliverToBoxAdapter(
                      child: _buildSearchBar(),
                    ),
                    // Support card
                    SliverToBoxAdapter(
                      child: _buildSupportCard(context),
                    ),
                    // Conversations list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conversation = state.conversations[index];
                          final otherUserId =
                              conversation.getOtherUserId(widget.userId);

                          return FutureBuilder(
                            future: _getProfile(otherUserId),
                            builder: (context, snapshot) {
                              final profile = snapshot.data;

                              // Filter by search query
                              if (_searchQuery.isNotEmpty && profile != null) {
                                final query = _searchQuery.toLowerCase();
                                final nameMatches = profile.displayName
                                    .toLowerCase()
                                    .contains(query);
                                final nicknameMatches = profile.nickname
                                        ?.toLowerCase()
                                        .contains(query) ??
                                    false;
                                if (!nameMatches && !nicknameMatches) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return ConversationCard(
                                conversation: conversation,
                                otherUserProfile: profile,
                                currentUserId: widget.userId,
                                onTap: () async {
                                  if (profile != null) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          matchId: conversation.matchId,
                                          currentUserId: widget.userId,
                                          otherUserId: otherUserId,
                                          otherUserProfile: profile,
                                        ),
                                      ),
                                    );

                                    // Refresh conversations after returning from chat
                                    if (context.mounted) {
                                      context
                                          .read<ConversationsBloc>()
                                          .add(const ConversationsRefreshRequested());
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                        childCount: state.conversations.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
