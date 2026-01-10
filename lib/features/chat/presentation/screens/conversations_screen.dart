import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/models/profile_model.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';
import '../widgets/conversation_card.dart';
import 'chat_screen.dart';

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
  Profile? _adminProfile;
  bool _isLoadingAdmin = true;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final adminQuery = await FirebaseFirestore.instance
          .collection('profiles')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty && mounted) {
        final adminDoc = adminQuery.docs.first;
        // Don't show admin to themselves
        if (adminDoc.id != widget.userId) {
          setState(() {
            _adminProfile = ProfileModel.fromFirestore(adminDoc);
            _isLoadingAdmin = false;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
        });
      }
    }
  }

  Future<void> _navigateToAdminChat(BuildContext context) async {
    if (_adminProfile == null) return;

    // Create or get match with admin
    final firestore = FirebaseFirestore.instance;
    final adminId = _adminProfile!.userId;

    // Check if match exists
    final matchQuery1 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: widget.userId)
        .where('userId2', isEqualTo: adminId)
        .limit(1)
        .get();

    final matchQuery2 = await firestore
        .collection('matches')
        .where('userId1', isEqualTo: adminId)
        .where('userId2', isEqualTo: widget.userId)
        .limit(1)
        .get();

    String matchId;
    if (matchQuery1.docs.isNotEmpty) {
      matchId = matchQuery1.docs.first.id;
    } else if (matchQuery2.docs.isNotEmpty) {
      matchId = matchQuery2.docs.first.id;
    } else {
      // Create new match with admin
      final matchRef = await firestore.collection('matches').add({
        'userId1': widget.userId,
        'userId2': adminId,
        'matchedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'user1Seen': true,
        'user2Seen': true,
      });
      matchId = matchRef.id;
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: matchId,
          currentUserId: widget.userId,
          otherUserId: adminId,
          otherUserProfile: _adminProfile!,
        ),
      ),
    );
  }

  Widget _buildAdminSupportCard(BuildContext context) {
    if (_adminProfile == null || _isLoadingAdmin) {
      return const SizedBox.shrink();
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
          onTap: () => _navigateToAdminChat(context),
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
                    image: _adminProfile!.photoUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_adminProfile!.photoUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _adminProfile!.photoUrls.isEmpty
                      ? const Icon(Icons.support_agent, color: Colors.white, size: 32)
                      : null,
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to chat with us!',
                        style: TextStyle(
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
                  _buildAdminSupportCard(context),
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
                child: ListView.builder(
                  itemCount: state.conversations.length + 1, // +1 for admin card
                  itemBuilder: (context, index) {
                    // Admin support card at the top
                    if (index == 0) {
                      return _buildAdminSupportCard(context);
                    }

                    final conversation = state.conversations[index - 1];
                    final otherUserId =
                        conversation.getOtherUserId(widget.userId);

                    return FutureBuilder(
                      future: di
                          .sl<ProfileRepository>()
                          .getProfile(otherUserId),
                      builder: (context, snapshot) {
                        final profile = snapshot.data?.fold(
                          (l) => null,
                          (r) => r,
                        );

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
