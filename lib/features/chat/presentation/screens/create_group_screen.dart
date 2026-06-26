import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/tier_limits_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/usecases/create_group.dart';
import 'group_chat_screen.dart';

/// A selectable contact for group creation. Supplied by the caller (e.g. the
/// conversations screen) from data it has already loaded, keeping this screen
/// decoupled from any specific contacts source.
class GroupCandidate {
  const GroupCandidate({
    required this.userId,
    required this.name,
    this.photoUrl,
  });
  final String userId;
  final String name;
  final String? photoUrl;
}

/// Create Group Screen — name the group, pick members, create.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
    required this.candidates,
  });

  final String currentUserId;
  final List<GroupCandidate> candidates;

  static Route<void> route({
    required String currentUserId,
    required List<GroupCandidate> candidates,
  }) {
    return MaterialPageRoute(
      builder: (_) => CreateGroupScreen(
        currentUserId: currentUserId,
        candidates: candidates,
      ),
    );
  }

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // Max members per group is 10 (creator + up to 9 others).
  static const int _maxOtherMembers = 9;
  // How many conversations to pull per page, per query side.
  static const int _chatsPageSize = 20;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _scrollController = ScrollController();
  final _selected = <String>{};
  // Members found via nickname invite (merged with the supplied chat partners).
  final _invited = <GroupCandidate>[];

  // People the user has chatted with (1:1), loaded with infinite scroll from the
  // `conversations` collection. Includes partners that have no nickname.
  final _chatPartners = <GroupCandidate>[];
  final _partnerIds = <String>{};
  final _partnerRecency = <String, int>{}; // userId -> lastMessageAt millis
  DocumentSnapshot<Map<String, dynamic>>? _cursor1;
  DocumentSnapshot<Map<String, dynamic>>? _cursor2;
  bool _hasMore1 = true;
  bool _hasMore2 = true;
  bool _loadingChats = false;

  bool _creating = false;
  bool _searching = false;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMorePartners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMoreChats => _hasMore1 || _hasMore2;

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadMorePartners();
    }
  }

  /// Loads the next page of 1:1 chat partners. Two equality queries
  /// (`userId1 == me` and `userId2 == me`), each ordered by recency and
  /// cursor-paginated, then merged/sorted client-side. Partners without a
  /// nickname are included (name falls back to display name / id).
  Future<void> _loadMorePartners() async {
    if (_loadingChats || !_hasMoreChats) return;
    setState(() => _loadingChats = true);
    final me = widget.currentUserId;
    final fs = FirebaseFirestore.instance;

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> page(
      String field,
      DocumentSnapshot<Map<String, dynamic>>? cursor,
    ) async {
      var q = fs
          .collection('conversations')
          .where(field, isEqualTo: me)
          .orderBy('lastMessageAt', descending: true)
          .limit(_chatsPageSize);
      if (cursor != null) q = q.startAfterDocument(cursor);
      final snap = await q.get();
      return snap.docs;
    }

    try {
      final results = await Future.wait([
        if (_hasMore1) page('userId1', _cursor1) else Future.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]),
        if (_hasMore2) page('userId2', _cursor2) else Future.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]),
      ]);
      final docs1 = _hasMore1 ? results[0] : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final docs2 = _hasMore2 ? results[1] : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (_hasMore1) {
        if (docs1.length < _chatsPageSize) _hasMore1 = false;
        if (docs1.isNotEmpty) _cursor1 = docs1.last;
      }
      if (_hasMore2) {
        if (docs2.length < _chatsPageSize) _hasMore2 = false;
        if (docs2.isNotEmpty) _cursor2 = docs2.last;
      }

      final newIds = <String>[];
      for (final doc in [...docs1, ...docs2]) {
        final data = doc.data();
        if (data['conversationType'] == 'support') continue;
        if (data['isDeleted'] == true) continue;
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        final other = u1 == me ? u2 : u1;
        if (other == null || other.isEmpty || other == me) continue;
        final ts = data['lastMessageAt'];
        final millis = ts is Timestamp ? ts.millisecondsSinceEpoch : 0;
        // Keep the most recent recency seen for this partner.
        if (!_partnerRecency.containsKey(other) ||
            millis > _partnerRecency[other]!) {
          _partnerRecency[other] = millis;
        }
        if (_partnerIds.add(other)) newIds.add(other);
      }

      if (newIds.isNotEmpty) {
        final briefs = await UserDirectoryService.instance.resolve(newIds);
        for (final id in newIds) {
          final b = briefs[id];
          _chatPartners.add(GroupCandidate(
            userId: id,
            name: b?.name ?? id,
            photoUrl: b?.photoUrl,
          ));
        }
        // Sort accumulated partners by recency (newest first).
        _chatPartners.sort((a, b) => (_partnerRecency[b.userId] ?? 0)
            .compareTo(_partnerRecency[a.userId] ?? 0));
      }
    } catch (_) {
      _hasMore1 = false;
      _hasMore2 = false;
    } finally {
      if (mounted) setState(() => _loadingChats = false);
    }
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty &&
      _selected.isNotEmpty &&
      !_creating;

  /// Combined, de-duplicated candidate pool: existing chat partners first, then
  /// people invited by nickname.
  List<GroupCandidate> get _allCandidates {
    final seen = <String>{};
    final all = <GroupCandidate>[];
    // Invited (nickname) + supplied candidates first, then chat partners.
    for (final c in [...widget.candidates, ..._invited, ..._chatPartners]) {
      if (c.userId == widget.currentUserId) continue;
      if (seen.add(c.userId)) all.add(c);
    }
    return all;
  }

  /// Invite-by-nickname: prefix search on the `profiles` collection
  /// (case-insensitive via `nicknameLower`), excluding self and ghost-mode users.
  Future<void> _searchNickname() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = _nicknameController.text.trim();
    if (raw.isEmpty) return;
    // Match the stored nickname whether it's saved as-typed or lowercased.
    final candidatesQuery = <String>{raw, raw.toLowerCase()}.toList();
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', whereIn: candidatesQuery)
          .limit(20)
          .get();

      var added = 0;
      var capped = false;
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = doc.id;
        if (uid == widget.currentUserId) continue;
        if (data['isGhostMode'] == true) continue;
        if (_invited.any((c) => c.userId == uid) ||
            widget.candidates.any((c) => c.userId == uid)) {
          // Already in the list — just make sure it's selected.
          if (_selected.length < _maxOtherMembers) _selected.add(uid);
          continue;
        }
        if (_selected.length >= _maxOtherMembers) {
          capped = true;
          break;
        }
        final photos = (data['photoUrls'] as List?)?.cast<String>() ?? const [];
        _invited.add(GroupCandidate(
          userId: uid,
          name: (data['displayName'] ?? data['nickname'] ?? 'User') as String,
          photoUrl: photos.isNotEmpty ? photos.first : null,
        ));
        _selected.add(uid); // auto-select an invited person
        added++;
      }
      setState(() {
        _searching = false;
        _searchMessage = capped
            ? l10n.groupMemberLimit(_maxOtherMembers + 1)
            : (snap.docs.isEmpty
                ? l10n.groupNoOneFound
                : (added == 0
                    ? l10n.groupAlreadyAdded
                    : l10n.groupAddedCount(added)));
        _nicknameController.clear();
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _searchMessage = l10n.groupSearchFailed;
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _creating = true);

    // Enforce tier cap on number of groups created.
    final check =
        await TierLimitsService().canCreateGroup(widget.currentUserId);
    if (!mounted) return;
    if (!check.allowed) {
      setState(() => _creating = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tierLimitTitle),
          content: Text(l10n.tierLimitGroupsBody(check.max ?? 0)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.tourGotIt),
            ),
          ],
        ),
      );
      return;
    }

    final result = await sl<CreateGroup>()(
      CreateGroupParams(
        creatorId: widget.currentUserId,
        name: _nameController.text.trim(),
        memberIds: _selected.toList(),
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (group) {
        Navigator.of(context).pushReplacement(
          GroupChatScreen.route(
            groupId: group.conversationId,
            groupName: group.groupInfo?.name ?? 'Group',
            currentUserId: widget.currentUserId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidates = _allCandidates;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupNewGroup),
        actions: [
          TextButton(
            onPressed: _canCreate ? _create : null,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.groupCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.groupNameLabel,
                prefixIcon: const Icon(Icons.groups_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // Invite by nickname.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchNickname(),
                    decoration: InputDecoration(
                      labelText: l10n.groupInviteByNickname,
                      hintText: l10n.groupNicknameHint,
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _searching
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton.filled(
                        icon: const Icon(Icons.person_add_alt),
                        onPressed: _searchNickname,
                      ),
              ],
            ),
          ),
          if (_searchMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _searchMessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_selected.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.groupSelectedCount(_selected.length)),
              ),
            ),
          const Divider(),
          Expanded(
            child: candidates.isEmpty
                ? (_loadingChats
                    ? const Center(child: CircularProgressIndicator())
                    : Center(child: Text(l10n.groupNoContacts)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: candidates.length + (_hasMoreChats ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= candidates.length) {
                        // Infinite-scroll footer loader.
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final c = candidates[index];
                      final selected = _selected.contains(c.userId);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) {
                          if (v == true &&
                              _selected.length >= _maxOtherMembers) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .groupMemberLimit(_maxOtherMembers + 1)),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (v == true) {
                              _selected.add(c.userId);
                            } else {
                              _selected.remove(c.userId);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          backgroundImage: (c.photoUrl != null &&
                                  c.photoUrl!.isNotEmpty)
                              ? NetworkImage(c.photoUrl!)
                              : null,
                          child: (c.photoUrl == null || c.photoUrl!.isEmpty)
                              ? Text(c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(c.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
