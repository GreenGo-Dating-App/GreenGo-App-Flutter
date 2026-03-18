import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/providers/language_provider.dart';
import '../../../../core/utils/base_membership_gate.dart';
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
  final void Function(int decrementBy)? onBadgeDecrement;

  const ConversationsScreen({
    super.key,
    required this.userId,
    this.onBadgeDecrement,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

enum ConversationFilter { all, newMessages, notReplied, fromMatch, fromSearch, favorites, toApprove }

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ConversationFilter _selectedFilter = ConversationFilter.all;
  final Map<String, Profile?> _profileCache = {};
  final Map<String, String> _chatLanguageCache = {};
  Profile? _currentUserProfile;
  SharedPreferences? _prefs;
  String? _userDefaultLanguage;

  @override
  void initState() {
    super.initState();
    _selectedFilter = ConversationFilter.all;
    _searchQuery = '';
    _searchController.clear();
    _loadCurrentUserProfile();
    _loadPrefs();
  }

  @override
  void didUpdateWidget(covariant ConversationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() {
        _selectedFilter = ConversationFilter.all;
        _searchQuery = '';
        _searchController.clear();
        _profileCache.clear();
      });
      _loadCurrentUserProfile();
    }
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get saved chat language for a conversation (null = user default, not shown)
  /// Always reads fresh from SharedPreferences to reflect language changes made in chat.
  String? _getChatLanguage(String matchId) {
    final lang = _prefs?.getString('chat_${matchId}_language');
    return (lang != null && lang.isNotEmpty && lang != _userDefaultLanguage) ? lang : null;
  }

  Future<void> _loadCurrentUserProfile({bool forceServer = false}) async {
    if (forceServer) {
      // Force server read to get latest membership status after purchase
      try {
        final doc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.userId)
            .get(const GetOptions(source: Source.server));
        if (mounted && doc.exists) {
          final data = doc.data()!;
          setState(() {
            _currentUserProfile = ProfileModel.fromJson({...data, 'userId': doc.id});
          });
        }
      } catch (_) {
        // Fallback to repository
        final result = await di.sl<ProfileRepository>().getProfile(widget.userId);
        result.fold((_) {}, (profile) {
          if (mounted) setState(() => _currentUserProfile = profile);
        });
      }
    } else {
      final result = await di.sl<ProfileRepository>().getProfile(widget.userId);
      result.fold((_) {}, (profile) {
        if (mounted) setState(() => _currentUserProfile = profile);
      });
    }
  }

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

  int _countForFilter(ConversationFilter filter, List<Conversation> conversations) {
    final saved = _selectedFilter;
    _selectedFilter = filter;
    final count = conversations.where(_passesFilter).length;
    _selectedFilter = saved;
    return count;
  }

  Widget _buildFilterChips(List<Conversation> conversations) {
    final l10n = AppLocalizations.of(context);
    final filters = [
      (ConversationFilter.all, l10n?.filterAll ?? 'All'),
      (ConversationFilter.newMessages, l10n?.filterNewMessages ?? 'New'),
      (ConversationFilter.notReplied, l10n?.filterNotReplied ?? 'Unread'),
      (ConversationFilter.favorites, l10n?.filterFavorites ?? 'Favorites'),
      (ConversationFilter.toApprove, l10n?.filterToApprove ?? 'To Approve'),
      (ConversationFilter.fromMatch, l10n?.filterFromMatch ?? 'Match'),
      (ConversationFilter.fromSearch, l10n?.filterFromSearch ?? 'Search'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _selectedFilter == filter;
          final showCount = filter == ConversationFilter.newMessages ||
              filter == ConversationFilter.notReplied ||
              filter == ConversationFilter.toApprove;
          final count = showCount ? _countForFilter(filter, conversations) : 0;
          final chipLabel = showCount && count > 0 ? '$label ($count)' : label;

          return FilterChip(
            selected: isSelected,
            label: Text(chipLabel),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.deepBlack : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: AppColors.backgroundCard,
            selectedColor: AppColors.richGold,
            checkmarkColor: AppColors.deepBlack,
            side: BorderSide(
              color: isSelected ? AppColors.richGold : AppColors.divider,
            ),
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          );
        },
      ),
    );
  }

  bool _passesFilter(Conversation conversation) {
    switch (_selectedFilter) {
      case ConversationFilter.all:
        // "All" excludes support, search (directs), and pending superLikes
        return conversation.conversationType != ConversationType.support &&
            conversation.conversationType != ConversationType.search &&
            !(conversation.isSuperLikeConversation && conversation.visibleTo != null);
      case ConversationFilter.newMessages:
        // Exclude pending superLike/priority connect — those go to "To Approve"
        if (conversation.isSuperLikeConversation && conversation.visibleTo != null) {
          return false;
        }
        return conversation.unreadCount > 0 &&
            conversation.lastMessage != null &&
            !conversation.lastMessage!.isSentBy(widget.userId);
      case ConversationFilter.notReplied:
        if (conversation.isSuperLikeConversation && conversation.visibleTo != null) {
          return false;
        }
        return conversation.unreadCount > 0 &&
            conversation.lastMessage != null &&
            !conversation.lastMessage!.isSentBy(widget.userId);
      case ConversationFilter.favorites:
        return conversation.isFavoritedBy(widget.userId);
      case ConversationFilter.toApprove:
        // Show all superLike conversations (pending ones needing approval)
        return conversation.isSuperLikeConversation &&
            conversation.visibleTo != null &&
            conversation.visibleTo!.contains(widget.userId);
      case ConversationFilter.fromMatch:
        return conversation.conversationType == ConversationType.match;
      case ConversationFilter.fromSearch:
        return conversation.conversationType == ConversationType.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    _userDefaultLanguage = Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode;
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
              return Center(
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
                    // Filter chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterChips(state.conversations),
                      ),
                    ),
                    // Conversations list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final filteredConversations = state.conversations
                              .where(_passesFilter)
                              .toList();
                          if (index >= filteredConversations.length) {
                            return const SizedBox.shrink();
                          }
                          final conversation = filteredConversations[index];
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
                                key: ValueKey(conversation.conversationId),
                                conversation: conversation,
                                otherUserProfile: profile,
                                currentUserId: widget.userId,
                                chatLanguage: _getChatLanguage(conversation.matchId),
                                onToggleFavorite: () {
                                  context.read<ConversationsBloc>().add(
                                    ConversationToggleFavoriteRequested(
                                      conversationId: conversation.conversationId,
                                      userId: widget.userId,
                                      isFavorite: !conversation.isFavoritedBy(widget.userId),
                                    ),
                                  );
                                },
                                onAcceptSuperLike: () {
                                  context.read<ConversationsBloc>().add(
                                    ConversationAcceptSuperLikeRequested(
                                      conversationId: conversation.conversationId,
                                    ),
                                  );
                                  widget.onBadgeDecrement?.call(1);
                                },
                                onRejectSuperLike: () {
                                  context.read<ConversationsBloc>().add(
                                    ConversationRejectSuperLikeRequested(
                                      conversationId: conversation.conversationId,
                                      userId: widget.userId,
                                    ),
                                  );
                                  widget.onBadgeDecrement?.call(1);
                                },
                                onLongPress: () {
                                  _showDeleteBottomSheet(
                                    context,
                                    conversation,
                                    profile?.displayName ?? 'this user',
                                  );
                                },
                                onTap: () async {
                                  // Base membership gate
                                  final wasMember = _currentUserProfile?.isBaseMembershipActive ?? false;
                                  final allowed = await BaseMembershipGate.checkAndGate(
                                    context: context,
                                    profile: _currentUserProfile,
                                    userId: widget.userId,
                                  );
                                  if (!allowed) return;
                                  // Refresh profile after successful purchase so gate won't block again
                                  if (!wasMember) await _loadCurrentUserProfile(forceServer: true);

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
                                    // Decrement badge by 1 conversation (Instagram style)
                                    // Only decrement if truly unread for current user
                                    if (conversation.unreadCount > 0 &&
                                        conversation.lastMessage != null &&
                                        !conversation.lastMessage!.isSentBy(widget.userId)) {
                                      widget.onBadgeDecrement?.call(1);
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                        childCount: state.conversations
                            .where(_passesFilter)
                            .length,
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

  void _showDeleteBottomSheet(
    BuildContext context,
    Conversation conversation,
    String otherUserName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.chatDeleteConversationWith(otherUserName),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                  title: Text(
                    AppLocalizations.of(context)!.chatDeleteForMe,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.chatDeleteForMeDescription,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.read<ConversationsBloc>().add(
                      ConversationDeleteForMeRequested(
                        conversationId: conversation.conversationId,
                        userId: widget.userId,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.errorRed),
                  title: Text(
                    AppLocalizations.of(context)!.chatDeleteForBoth,
                    style: const TextStyle(color: AppColors.errorRed),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.chatDeleteForBothDescription,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.read<ConversationsBloc>().add(
                      ConversationDeleteForBothRequested(
                        conversationId: conversation.conversationId,
                        userId: widget.userId,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.close, color: AppColors.textTertiary),
                  title: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => Navigator.pop(bottomSheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
