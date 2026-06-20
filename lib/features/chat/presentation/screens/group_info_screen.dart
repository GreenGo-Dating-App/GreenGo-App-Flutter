import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/usecases/get_group_members.dart';
import '../../domain/usecases/group_membership.dart';
import '../../domain/usecases/report_user.dart';

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
                final displayName = m.userId == currentUserId
                    ? l10n.groupYou
                    : (brief?.name ?? m.userId);
                final photo = brief?.photoUrl;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  title: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: m.isAdmin
                      ? Chip(label: Text(l10n.groupAdmin))
                      : null,
                );
              }),
              const Divider(),
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
            ],
          );
  }

  Future<void> _changeGroupPhoto(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    // Reject nudity / explicit content before uploading.
    final validation = await PhotoValidationService()
        .validateImageForSending(File(picked.path));
    if (!validation.isValid) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.photoExplicitContent),
        backgroundColor: Colors.red,
      ));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.groupUploadingPhoto)),
    );
    try {
      final url = await sl<ProfileRemoteDataSource>()
          .uploadPhoto(currentUserId, File(picked.path), folder: 'groups');
      await sl<UpdateGroupInfo>()(groupId: groupId, photoUrl: url);
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
