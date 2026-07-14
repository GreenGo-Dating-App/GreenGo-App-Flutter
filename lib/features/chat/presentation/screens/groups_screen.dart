import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/group_chat_remote_datasource.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/groups_bloc.dart';
import '../bloc/groups_event.dart';
import '../bloc/groups_state.dart';
import '../widgets/conversation_card.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

/// Groups filter (mirrors the Messages tab's All / Unread / Favorites).
enum _GroupFilter { all, unread, favorites }

/// Groups tab — the user's group conversations, rendered EXACTLY like the
/// Messages tab (same [ConversationCard] tile + the same filter chips, with a
/// star-favorite). Backed by [GroupsBloc] (per-user inbox index, scales).
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, required this.userId, this.showAppBar = true});

  final String userId;

  /// When embedded as a tab (Exchanges → Groups) the host provides the header.
  final bool showAppBar;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _GroupFilter _filter = _GroupFilter.all;

  final GroupChatRemoteDataSource _groupDs =
      di.sl<GroupChatRemoteDataSource>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(Conversation group) {
    // Fire-and-forget; the live inbox stream re-emits with the new flag.
    _groupDs.setGroupFavorite(
      userId: widget.userId,
      groupId: group.conversationId,
      favorite: !group.isFavoritedBy(widget.userId),
    );
  }

  bool _passesFilter(Conversation g) {
    switch (_filter) {
      case _GroupFilter.all:
        return true;
      case _GroupFilter.unread:
        return g.unreadCountFor(widget.userId) > 0;
      case _GroupFilter.favorites:
        return g.isFavoritedBy(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.userId;
    return BlocProvider<GroupsBloc>(
      create: (_) => di.sl<GroupsBloc>()..add(GroupsLoadRequested(userId)),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: AppColors.backgroundDark,
                title: Text(l10n.groupsTitle,
                    style: const TextStyle(color: AppColors.textPrimary)),
              )
            : null,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          icon: const Icon(Icons.group_add),
          label: Text(l10n.groupNewGroup),
          onPressed: () => Navigator.of(context).push(
            CreateGroupScreen.route(currentUserId: userId, candidates: const []),
          ),
        ),
        body: Column(
          children: [
            // Search by group name — same styling as the Exchanges search bar.
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.groupSearchHint,
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withOpacity(0.6),
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textTertiary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
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
              ),
            ),
            // Filter chips — same set/style as the Messages tab.
            _buildFilterChips(l10n),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, state) {
                  if (state is GroupsLoading || state is GroupsInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.richGold),
                    );
                  }
                  if (state is GroupsError) {
                    return Center(
                      child: Text(state.message,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  if (state is GroupsEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.groups_outlined,
                              size: 80, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text(l10n.groupSayHello,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  final all = state is GroupsLoaded
                      ? state.groups
                      : const <Conversation>[];
                  final groups = all.where((g) {
                    final nameOk = _query.isEmpty ||
                        (g.groupInfo?.name ?? '')
                            .toLowerCase()
                            .contains(_query);
                    return nameOk && _passesFilter(g);
                  }).toList();
                  if (groups.isEmpty) {
                    return Center(
                      child: Text(l10n.groupNoSearchResults,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundCard,
                    onRefresh: () async {
                      context
                          .read<GroupsBloc>()
                          .add(const GroupsRefreshRequested());
                    },
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        return ConversationCard(
                          conversation: g,
                          otherUserProfile: null, // group → uses groupInfo
                          currentUserId: userId,
                          onTap: () => Navigator.of(context).push(
                            GroupChatScreen.route(
                              groupId: g.conversationId,
                              groupName: g.groupInfo?.name ?? 'Group',
                              currentUserId: userId,
                              groupPhotoUrl: g.groupInfo?.photoUrl,
                            ),
                          ),
                          onToggleFavorite: () => _toggleFavorite(g),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final filters = [
      (_GroupFilter.all, l10n.filterAll),
      (_GroupFilter.unread, l10n.filterNotReplied),
      (_GroupFilter.favorites, l10n.filterFavorites),
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
          final selected = _filter == filter;
          return FilterChip(
            selected: selected,
            label: Text(label),
            labelStyle: TextStyle(
              color: selected ? AppColors.deepBlack : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: AppColors.backgroundCard,
            selectedColor: AppColors.richGold,
            checkmarkColor: AppColors.deepBlack,
            side: BorderSide(
              color: selected ? AppColors.richGold : AppColors.divider,
            ),
            onSelected: (_) => setState(() => _filter = filter),
          );
        },
      ),
    );
  }
}
