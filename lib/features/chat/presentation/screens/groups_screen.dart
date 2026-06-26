import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/group_tags_service.dart';
import '../bloc/groups_bloc.dart';
import '../bloc/groups_event.dart';
import '../bloc/groups_state.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

/// Groups tab — lists the user's group conversations ("Culture Circles"),
/// searchable by name. Backed by [GroupsBloc] (per-user inbox index, scales to
/// millions). Layout mirrors the 1:1 chats list, with groups instead of people.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Per-user PRIVATE group tags (groupId -> tags) and the active tag filter.
  final _tagsService = GroupTagsService();
  StreamSubscription<Map<String, List<String>>>? _tagsSub;
  Map<String, List<String>> _tags = const {};
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tagsSub = _tagsService.watchAll(widget.userId).listen((tags) {
      if (!mounted) return;
      setState(() {
        _tags = tags;
        // Drop any selected tag that no longer exists.
        final all = tags.values.expand((t) => t).toSet();
        _selectedTags.removeWhere((t) => !all.contains(t));
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagsSub?.cancel();
    super.dispose();
  }

  /// All distinct tags the user has applied across their groups, sorted.
  List<String> get _allTags {
    final set = <String>{};
    for (final list in _tags.values) {
      set.addAll(list);
    }
    final out = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// A group passes the tag filter if no tags are selected, or it carries any
  /// of the selected tags (OR semantics).
  bool _matchesTagFilter(String groupId) {
    if (_selectedTags.isEmpty) return true;
    final groupTags = _tags[groupId];
    if (groupTags == null) return false;
    return groupTags.any(_selectedTags.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.userId;
    return BlocProvider<GroupsBloc>(
      create: (_) => di.sl<GroupsBloc>()..add(GroupsLoadRequested(userId)),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(l10n.groupsTitle,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
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
            // Search by group name (chats-style search bar).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.groupSearchHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Personal tag filter — chips of the user's own tags. Only the
            // current user sees these; selecting filters their groups list.
            if (_allTags.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final tag in _allTags)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          showCheckmark: false,
                          selectedColor: AppColors.richGold,
                          backgroundColor: AppColors.backgroundCard,
                          labelStyle: TextStyle(
                            color: _selectedTags.contains(tag)
                                ? AppColors.deepBlack
                                : AppColors.textSecondary,
                          ),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          }),
                        ),
                      ),
                  ],
                ),
              ),
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
                  final allGroups =
                      state is GroupsLoaded ? state.groups : [];
                  final groups = allGroups.where((g) {
                    final nameOk = _query.isEmpty ||
                        (g.groupInfo?.name ?? '')
                            .toLowerCase()
                            .contains(_query);
                    return nameOk && _matchesTagFilter(g.conversationId);
                  }).toList();
                  if (groups.isEmpty) {
                    return Center(
                      child: Text(l10n.groupNoSearchResults,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: AppColors.backgroundCard),
                    itemBuilder: (context, index) {
                      final g = groups[index];
                      final name = g.groupInfo?.name ?? 'Group';
                      final unread = g.unreadCountFor(userId);
                      final groupTags = _tags[g.conversationId] ?? const [];
                      return ListTile(
                        isThreeLine: groupTags.isNotEmpty,
                        leading: _GroupAvatar(
                          groupId: g.conversationId,
                          inboxPhotoUrl: g.groupInfo?.photoUrl,
                          name: name,
                        ),
                        title: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            if (groupTags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    for (final t in groupTags)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundCard,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          t,
                                          style: const TextStyle(
                                            color: AppColors.richGold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: unread > 0
                            ? CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.richGold,
                                child: Text('$unread',
                                    style: const TextStyle(
                                        color: AppColors.deepBlack,
                                        fontSize: 12)),
                              )
                            : null,
                        onTap: () => Navigator.of(context).push(
                          GroupChatScreen.route(
                            groupId: g.conversationId,
                            groupName: name,
                            currentUserId: userId,
                            groupPhotoUrl: g.groupInfo?.photoUrl,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group avatar that shows the group photo. Uses the inbox thread photo when
/// present; otherwise falls back to a one-time read of the group document
/// (covers groups created before inbox photo-sync existed). Cached by Firestore
/// persistence, so the fallback read only happens once per photo-less group.
class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({
    required this.groupId,
    required this.inboxPhotoUrl,
    required this.name,
  });

  final String groupId;
  final String? inboxPhotoUrl;
  final String name;

  Widget _avatar(String? photoUrl) {
    final has = photoUrl != null && photoUrl.isNotEmpty;
    return CircleAvatar(
      backgroundColor: AppColors.richGold,
      foregroundColor: AppColors.deepBlack,
      backgroundImage: has ? CachedNetworkImageProvider(photoUrl) : null,
      child: has
          ? null
          : Text(name.isNotEmpty ? name[0].toUpperCase() : '#'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inboxPhotoUrl != null && inboxPhotoUrl!.isNotEmpty) {
      return _avatar(inboxPhotoUrl);
    }
    // Fallback: read the group doc's photo once.
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
      builder: (context, snap) {
        final photo = (snap.data?.data()?['groupInfo']
            as Map<String, dynamic>?)?['photoUrl'] as String?;
        return _avatar(photo);
      },
    );
  }
}
