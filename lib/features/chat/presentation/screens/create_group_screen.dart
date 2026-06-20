import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
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
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _selected = <String>{};
  // Members found via nickname invite (merged with the supplied chat partners).
  final _invited = <GroupCandidate>[];
  bool _creating = false;
  bool _searching = false;
  String? _searchMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
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
    for (final c in [...widget.candidates, ..._invited]) {
      if (c.userId == widget.currentUserId) continue;
      if (seen.add(c.userId)) all.add(c);
    }
    return all;
  }

  /// Invite-by-nickname: prefix search on the `profiles` collection
  /// (case-insensitive via `nicknameLower`), excluding self and ghost-mode users.
  Future<void> _searchNickname() async {
    final l10n = AppLocalizations.of(context)!;
    final query = _nicknameController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nicknameLower', isGreaterThanOrEqualTo: query)
          .where('nicknameLower', isLessThanOrEqualTo: query + String.fromCharCode(0xf8ff))
          .limit(20)
          .get();

      var added = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = doc.id;
        if (uid == widget.currentUserId) continue;
        if (data['isGhostMode'] == true) continue;
        if (_invited.any((c) => c.userId == uid) ||
            widget.candidates.any((c) => c.userId == uid)) {
          // Already in the list — just make sure it's selected.
          _selected.add(uid);
          continue;
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
        _searchMessage = snap.docs.isEmpty
            ? l10n.groupNoOneFound
            : (added == 0 ? l10n.groupAlreadyAdded : l10n.groupAddedCount(added));
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
    setState(() => _creating = true);
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
                ? Center(child: Text(l10n.groupNoContacts))
                : ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final c = candidates[index];
                      final selected = _selected.contains(c.userId);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(c.userId);
                          } else {
                            _selected.remove(c.userId);
                          }
                        }),
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
