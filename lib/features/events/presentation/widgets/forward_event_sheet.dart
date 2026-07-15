import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
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

/// Forwards an already-shared event card (its existing [metadata]) to other
/// chats and/or groups — used by the chooser on an EventMessageCard so any
/// shared event (native/community or external) can be re-shared anywhere.
/// [mode]: 'all' | 'chats' | 'groups'.
Future<void> showForwardEventSheet(
  BuildContext context, {
  required Map<String, dynamic> metadata,
  required String currentUserId,
  String mode = 'all',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ForwardEventSheet(
        metadata: metadata, currentUserId: currentUserId, mode: mode),
  );
}

class _ForwardEventSheet extends StatelessWidget {
  const _ForwardEventSheet(
      {required this.metadata, required this.currentUserId, this.mode = 'all'});

  final Map<String, dynamic> metadata;
  final String currentUserId;
  final String mode;

  String get _content =>
      (metadata['eventId'] as String?)?.isNotEmpty == true
          ? metadata['eventId'] as String
          : (metadata['externalUrl'] as String? ?? '');

  // Close + confirm immediately, send in the background (don't block the UI).
  void _toGroup(BuildContext context, String groupId) {
    _done(context);
    di
        .sl<SendGroupMessage>()(
          SendGroupMessageParams(
            groupId: groupId,
            senderId: currentUserId,
            content: _content,
            type: MessageType.event,
            metadata: metadata,
          ),
        )
        .catchError((_) {});
  }

  void _toChat(BuildContext context, Conversation c) {
    _done(context);
    di
        .sl<ChatRepository>()
        .sendMessage(
          matchId: c.matchId,
          senderId: currentUserId,
          receiverId: c.getOtherUserId(currentUserId),
          content: _content,
          type: MessageType.event,
          metadata: metadata,
        )
        .catchError((_) {});
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
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.eventShare,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (mode != 'chats')
                    StreamBuilder<Either<Failure, List<Conversation>>>(
                      stream: di.sl<GetUserGroups>()(currentUserId),
                      builder: (context, snap) {
                        final groups = (snap.data
                                    ?.fold((_) => <Conversation>[], (g) => g) ??
                                <Conversation>[])
                          ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
                              .compareTo(a.lastMessageAt ?? DateTime(0)));
                        if (groups.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(l10n.groupNewGroup),
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
                                title: Text(g.groupInfo?.name ?? 'Group',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary)),
                                onTap: () =>
                                    _toGroup(context, g.conversationId),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  if (mode != 'groups')
                    StreamBuilder<Either<Failure, List<Conversation>>>(
                      stream: di
                          .sl<ChatRepository>()
                          .getConversationsStream(currentUserId),
                      builder: (context, snap) {
                        final sorted = (snap.data
                                    ?.fold((_) => <Conversation>[], (c) => c) ??
                                <Conversation>[])
                          ..sort((a, b) => (b.lastMessageAt ?? DateTime(0))
                              .compareTo(a.lastMessageAt ?? DateTime(0)));
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
                            _header(l10n.messages),
                            ...chats.map((c) {
                              final otherId = c.getOtherUserId(currentUserId);
                              return FutureBuilder<Map<String, UserBrief>>(
                                future: UserDirectoryService.instance
                                    .resolve([otherId]),
                                builder: (context, s) {
                                  final brief = s.data?[otherId] ??
                                      UserDirectoryService.instance
                                          .cached(otherId);
                                  // Hide until resolved, and hide DELETED users
                                  // entirely — never surface a raw uid.
                                  if (brief == null || !brief.isActive) {
                                    return const SizedBox.shrink();
                                  }
                                  final name = brief.name.isNotEmpty
                                      ? brief.name
                                      : l10n.chatUnknown;
                                  final photo = brief.photoUrl;
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
                                    title: Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary)),
                                    onTap: () => _toChat(context, c),
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

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      );
}
