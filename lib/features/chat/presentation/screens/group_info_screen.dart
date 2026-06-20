import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/usecases/get_group_members.dart';
import '../../domain/usecases/group_membership.dart';

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
    final getMembers = sl<GetGroupMembers>();
    return Scaffold(
      appBar: AppBar(title: const Text('Group info')),
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
          return ListView(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${members.length} members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...members.map((m) => ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        m.userId.isNotEmpty ? m.userId[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(
                      m.userId == currentUserId ? 'You' : m.userId,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: m.isAdmin
                        ? const Chip(label: Text('Admin'))
                        : null,
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Leave group',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmLeave(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will stop receiving messages from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
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
}
