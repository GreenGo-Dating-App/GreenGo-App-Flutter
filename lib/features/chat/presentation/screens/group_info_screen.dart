import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/utils/language_flags.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/usecases/get_group_members.dart';
import '../../domain/usecases/group_membership.dart';
import '../../domain/usecases/report_user.dart';
import '../widgets/group_tags_editor.dart';

/// Group Info Screen — members list, roles, and leave action.
///
/// Uses use cases directly (it is pushed as a standalone route, outside the
/// GroupChatBloc provider). Admin-only actions are gated client-side and
/// re-validated by Firestore rules / Cloud Functions.
class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  final String groupId;
  final String currentUserId;

  /// Mirror of GroupChatRemoteDataSourceImpl.maxGroupMembers (server-enforced).
  static const int _maxGroupMembers = 256;

  static Route<void> route({
    required String groupId,
    required String currentUserId,
  }) {
    return MaterialPageRoute(
      builder: (_) => GroupInfoScreen(
        groupId: groupId,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final getMembers = sl<GetGroupMembers>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupInfo)),
      body: StreamBuilder(
        stream: getMembers(groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final members = snapshot.data!.fold(
            (failure) => <GroupMember>[],
            (list) => list.where((m) => m.isActive).toList(),
          );
          final isAdmin = members
              .any((m) => m.userId == currentUserId && m.isAdmin);
          return FutureBuilder<Map<String, UserBrief>>(
            future: UserDirectoryService.instance
                .resolve(members.map((m) => m.userId)),
            builder: (context, dirSnap) {
              final dir = dirSnap.data ?? const <String, UserBrief>{};
              return _buildList(
                  context, l10n, members, isAdmin, dir);
            },
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    List<GroupMember> members,
    bool isAdmin,
    Map<String, UserBrief> dir,
  ) {
    return ListView(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.groupMembersCount(members.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...members.map((m) {
                final brief = dir[m.userId];
                // Show only the member's NAME — never fall back to the raw user
                // id when the name hasn't resolved yet.
                final displayName = m.userId == currentUserId
                    ? l10n.groupYou
                    : (brief?.name ?? l10n.chatUnknown);
                final photo = brief?.photoUrl;
                final flag = languageFlagEmoji(brief?.language);
                // Admin can remove any non-self member.
                final canRemove = isAdmin && m.userId != currentUserId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? CachedNetworkImageProvider(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  title: Row(
                    children: [
                      if (flag.isNotEmpty) ...[
                        Text(flag, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(displayName,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.isAdmin) Chip(label: Text(l10n.groupAdmin)),
                      if (canRemove)
                        IconButton(
                          icon: const Icon(Icons.person_remove_outlined,
                              color: Colors.red),
                          tooltip: l10n.groupRemoveMember,
                          onPressed: () =>
                              _removeMember(context, m.userId, displayName),
                        ),
                    ],
                  ),
                );
              }),
              const Divider(),
              // My personal (private) tags for this group — only the current
              // user sees these; they don't affect the group or other members.
              MyGroupTagsTile(groupId: groupId, userId: currentUserId),
              const Divider(),
              if (isAdmin)
                ListTile(
                  leading: Icon(
                    members.length >= _maxGroupMembers
                        ? Icons.group_off_outlined
                        : Icons.person_add_alt_1,
                    color: members.length >= _maxGroupMembers
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(members.length >= _maxGroupMembers
                      ? l10n.groupMemberLimit(_maxGroupMembers)
                      : l10n.groupAddMembers),
                  subtitle: Text(
                      '${l10n.groupMembersCount(members.length)} / $_maxGroupMembers'),
                  enabled: members.length < _maxGroupMembers,
                  onTap: members.length >= _maxGroupMembers
                      ? null
                      : () => _addMembers(
                            context,
                            members.map((m) => m.userId).toSet(),
                          ),
                ),
              if (isAdmin)
                ListTile(
                  leading: Icon(Icons.edit,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(l10n.groupEditName),
                  onTap: () => _editGroupName(context),
                ),
              if (isAdmin)
                ListTile(
                  leading: Icon(Icons.add_a_photo_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(l10n.groupChangePhoto),
                  onTap: () => _changeGroupPhoto(context),
                ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: Text(
                  l10n.groupReport,
                  style: const TextStyle(color: Colors.orange),
                ),
                onTap: () => _confirmReport(context),
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: Text(
                  l10n.groupLeave,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmLeave(context),
              ),
              // Admin only: permanently delete the whole group for everyone.
              if (isAdmin)
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    l10n.groupDelete,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmDeleteGroup(context),
                ),
            ],
          );
  }

  /// Admin: permanently delete the group for everyone (confirmation required).
  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupDeleteConfirmTitle),
        content: Text(l10n.groupDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.groupCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.groupDelete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await sl<DeleteGroup>()(
      groupId: groupId,
      actorId: currentUserId,
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  /// Admin: remove a member from the group.
  Future<void> _removeMember(
      BuildContext context, String memberId, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupRemoveMember),
        content: Text(l10n.groupRemoveMemberConfirm(name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.groupRemoveMember,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<RemoveGroupMember>()(
      groupId: groupId,
      actorId: currentUserId,
      memberId: memberId,
    );
    result.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger
          .showSnackBar(SnackBar(content: Text(l10n.groupMemberRemoved(name)))),
    );
  }

  /// Admin: invite members by nickname, up to the remaining capacity.
  Future<void> _addMembers(
      BuildContext context, Set<String> existingIds) async {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _maxGroupMembers - existingIds.length;
    if (remaining <= 0) return;
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMembersSheet(
        existingIds: existingIds,
        currentUserId: currentUserId,
        remaining: remaining,
      ),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<AddGroupMembers>()(
      groupId: groupId,
      actorId: currentUserId,
      memberIds: picked,
    );
    result.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => messenger.showSnackBar(
          SnackBar(content: Text(l10n.groupAddedCount(picked.length)))),
    );
  }

  Future<void> _changeGroupPhoto(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    // Reject nudity / explicit content before uploading. On-device ML Kit is
    // native-only — skip on web (server-side moderation still applies).
    if (!kIsWeb) {
      final validation = await PhotoValidationService()
          .validateImageForSending(File(picked.path));
      if (!validation.isValid) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.photoExplicitContent),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.groupUploadingPhoto)),
    );
    try {
      final url = await sl<ProfileRemoteDataSource>()
          .uploadPhoto(currentUserId, picked, folder: 'groups');
      await sl<UpdateGroupInfo>()(groupId: groupId, photoUrl: url);
      // Optimistic: update own inbox row so my Groups list reflects it
      // immediately (the onGroupInfoChanged CF fans it out to other members).
      try {
        await FirebaseFirestore.instance
            .collection('user_group_inbox')
            .doc(currentUserId)
            .collection('threads')
            .doc(groupId)
            .set({'photoUrl': url}, SetOptions(merge: true));
      } catch (_) {}
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.groupPhotoUpdated)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.groupPhotoUpdateFailed)),
      );
    }
  }

  Future<void> _editGroupName(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupEditName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.groupNameLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.groupEditName)),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await sl<UpdateGroupInfo>()(groupId: groupId, name: name);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.groupEditName)));
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupLeaveConfirmTitle),
        content: Text(l10n.groupLeaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.groupCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.groupLeaveAction,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await sl<LeaveGroup>()(
      groupId: groupId,
      userId: currentUserId,
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => Navigator.of(context).popUntil((r) => r.isFirst),
    );
  }

  Future<void> _confirmReport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupReport),
        content: Text(l10n.groupReportConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.groupCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.groupReportAction,
                style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await sl<ReportUser>()(
      ReportUserParams(
        reporterId: currentUserId,
        reportedUserId: groupId,
        reason: 'group_report',
        conversationId: groupId,
        additionalDetails: 'Reported group conversation',
      ),
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupReportSubmitted)),
      ),
    );
  }
}

/// Admin sheet to invite members by nickname (prefix search on `profiles`),
/// capped to [remaining] free slots. Returns the chosen user ids.
class _AddMembersSheet extends StatefulWidget {
  const _AddMembersSheet({
    required this.existingIds,
    required this.currentUserId,
    required this.remaining,
  });

  final Set<String> existingIds;
  final String currentUserId;
  final int remaining;

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final _controller = TextEditingController();
  final _results = <UserBrief>[];
  final _resultIds = <String>[];
  final _selected = <String>{};
  bool _searching = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', whereIn: <String>{raw, raw.toLowerCase()}.toList())
          .limit(20)
          .get();
      _results.clear();
      _resultIds.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = doc.id;
        if (uid == widget.currentUserId) continue;
        if (data['isGhostMode'] == true) continue;
        // Business/storefront identities can't be added to groups (search-only).
        if (data['isBusiness'] == true) continue;
        if (widget.existingIds.contains(uid)) continue;
        final photos = (data['photoUrls'] as List?)?.cast<String>() ?? const [];
        final langs = (data['languages'] as List?)?.cast<String>() ?? const [];
        _results.add(UserBrief(
          name: (data['displayName'] ?? data['nickname'] ?? 'User') as String,
          photoUrl: photos.isNotEmpty ? photos.first : null,
          language: langs.isNotEmpty ? langs.first : null,
        ));
        _resultIds.add(uid);
      }
      setState(() {
        _searching = false;
        _message = _results.isEmpty ? l10n.groupNoOneFound : null;
      });
    } catch (_) {
      setState(() {
        _searching = false;
        _message = l10n.groupNoOneFound;
      });
    }
  }

  void _toggle(String uid) {
    setState(() {
      if (_selected.contains(uid)) {
        _selected.remove(uid);
      } else if (_selected.length < widget.remaining) {
        _selected.add(uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .groupMemberLimit(widget.existingIds.length + widget.remaining)),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.groupAddMembers,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: l10n.groupInviteByNickname,
                    prefixIcon: const Icon(Icons.alternate_email),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
            ],
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final b = _results[i];
                  final uid = _resultIds[i];
                  final flag = languageFlagEmoji(b.language);
                  return CheckboxListTile(
                    value: _selected.contains(uid),
                    onChanged: (_) => _toggle(uid),
                    secondary: CircleAvatar(
                      backgroundImage:
                          (b.photoUrl != null && b.photoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(b.photoUrl!)
                              : null,
                      child: (b.photoUrl == null || b.photoUrl!.isEmpty)
                          ? Text(b.name.isNotEmpty ? b.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(flag.isNotEmpty ? '$flag  ${b.name}' : b.name),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected.toList()),
              child: Text(l10n.groupAddSelected(_selected.length)),
            ),
          ),
        ],
      ),
    );
  }
}
