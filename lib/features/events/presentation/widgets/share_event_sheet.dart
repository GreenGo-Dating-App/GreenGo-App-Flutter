import 'package:dartz/dartz.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/failures.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/domain/usecases/get_user_groups.dart';
import '../../../chat/domain/usecases/send_group_message.dart';
import '../../domain/entities/event.dart';

/// Bottom sheet to share an event into the user's groups and 1:1 chats.
/// Sends a `MessageType.event` card (content = eventId, metadata carries
/// title + image) reusing the existing chat/group send paths.
Future<void> showShareEventSheet(
  BuildContext context, {
  required Event event,
  required String currentUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ShareEventSheet(event: event, currentUserId: currentUserId),
  );
}

class _ShareEventSheet extends StatelessWidget {
  const _ShareEventSheet({required this.event, required this.currentUserId});

  final Event event;
  final String currentUserId;

  Map<String, dynamic> get _metadata => {
        'eventId': event.id,
        'eventTitle': event.title,
        'eventImageUrl': event.imageUrl,
      };

  Future<void> _shareToGroup(BuildContext context, String groupId) async {
    await di.sl<SendGroupMessage>()(
      SendGroupMessageParams(
        groupId: groupId,
        senderId: currentUserId,
        content: event.id,
        type: MessageType.event,
        metadata: _metadata,
      ),
    );
    _done(context);
  }

  Future<void> _shareToChat(BuildContext context, Conversation c) async {
    await di.sl<ChatRepository>().sendMessage(
          matchId: c.matchId,
          senderId: currentUserId,
          receiverId: c.getOtherUserId(currentUserId),
          content: event.id,
          type: MessageType.event,
          metadata: _metadata,
        );
    _done(context);
  }

  void _done(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.eventShared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.eventShare,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Groups
                  StreamBuilder<Either<Failure, List<Conversation>>>(
                    stream: di.sl<GetUserGroups>()(currentUserId),
                    builder: (context, snap) {
                      final groups = (snap.data?.fold((_) => <Conversation>[],
                              (g) => g) ??
                          <Conversation>[])
                        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
                            .compareTo(a.lastMessageAt ?? DateTime(0)));
                      if (groups.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(l10n.groupNewGroup),
                          ...groups.map((g) {
                            final photo = g.groupInfo?.photoUrl;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    (photo != null && photo.isNotEmpty)
                                        ? CachedNetworkImageProvider(photo)
                                        : null,
                                child: (photo == null || photo.isEmpty)
                                    ? const Icon(Icons.groups)
                                    : null,
                              ),
                              title: Text(
                                g.groupInfo?.name ?? 'Group',
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                              ),
                              onTap: () =>
                                  _shareToGroup(context, g.conversationId),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  // 1:1 chats
                  StreamBuilder<Either<Failure, List<Conversation>>>(
                    stream:
                        di.sl<ChatRepository>().getConversationsStream(currentUserId),
                    builder: (context, snap) {
                      final sorted = (snap.data?.fold((_) => <Conversation>[],
                              (c) => c) ??
                          <Conversation>[])
                        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
                            .compareTo(a.lastMessageAt ?? DateTime(0)));
                      // One row per other user (keep most recent conversation).
                      final seen = <String>{};
                      final chats = <Conversation>[];
                      for (final c in sorted) {
                        if (seen.add(c.getOtherUserId(currentUserId))) {
                          chats.add(c);
                        }
                      }
                      if (chats.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(l10n.messages),
                          ...chats.map((c) {
                            final otherId = c.getOtherUserId(currentUserId);
                            return FutureBuilder<Map<String, UserBrief>>(
                              future: UserDirectoryService.instance
                                  .resolve([otherId]),
                              builder: (context, s) {
                                final brief = s.data?[otherId] ??
                                    UserDirectoryService.instance.cached(otherId);
                                final name = brief?.name ?? otherId;
                                final photo = brief?.photoUrl;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        (photo != null && photo.isNotEmpty)
                                            ? CachedNetworkImageProvider(photo)
                                            : null,
                                    child: (photo == null || photo.isEmpty)
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                  ),
                                  onTap: () => _shareToChat(context, c),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
