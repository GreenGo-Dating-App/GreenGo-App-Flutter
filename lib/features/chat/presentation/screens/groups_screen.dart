import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../bloc/groups_bloc.dart';
import '../bloc/groups_event.dart';
import '../bloc/groups_state.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

/// Groups tab — lists the user's group conversations ("Culture Circles").
/// Backed by [GroupsBloc] (per-user inbox index, scales to millions).
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider<GroupsBloc>(
      create: (_) =>
          di.sl<GroupsBloc>()..add(GroupsLoadRequested(userId)),
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
        body: BlocBuilder<GroupsBloc, GroupsState>(
          builder: (context, state) {
            if (state is GroupsLoading || state is GroupsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }
            if (state is GroupsError) {
              return Center(
                child: Text(state.message,
                    style: const TextStyle(color: AppColors.textSecondary)),
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
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            final groups =
                state is GroupsLoaded ? state.groups : [];
            return ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.backgroundCard),
              itemBuilder: (context, index) {
                final g = groups[index];
                final name = g.groupInfo?.name ?? 'Group';
                final unread = g.unreadCountFor(userId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    backgroundImage: (g.groupInfo?.photoUrl != null &&
                            g.groupInfo!.photoUrl!.isNotEmpty)
                        ? NetworkImage(g.groupInfo!.photoUrl!)
                        : null,
                    child: (g.groupInfo?.photoUrl == null ||
                            g.groupInfo!.photoUrl!.isEmpty)
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '#')
                        : null,
                  ),
                  title: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    g.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: unread > 0
                      ? CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.richGold,
                          child: Text('$unread',
                              style: const TextStyle(
                                  color: AppColors.deepBlack, fontSize: 12)),
                        )
                      : null,
                  onTap: () => Navigator.of(context).push(
                    GroupChatScreen.route(
                      groupId: g.conversationId,
                      groupName: name,
                      currentUserId: userId,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
