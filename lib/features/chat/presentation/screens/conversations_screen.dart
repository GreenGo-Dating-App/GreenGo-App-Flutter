import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Profile?> _profileCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          hintText: AppLocalizations.of(context)!.chatSearchByNameOrNickname,
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
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            }

            if (state is ConversationsEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.chatNoMessagesYet,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            AppLocalizations.of(context)!.chatStartSwipingToChat,
                            style: const TextStyle(
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
