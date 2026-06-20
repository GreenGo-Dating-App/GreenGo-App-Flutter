import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/widgets/voice_message_widget.dart';
import '../../../../core/widgets/voice_record_send_button.dart';
import '../../../events/presentation/widgets/event_message_card.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/message.dart';
import '../bloc/group_chat_bloc.dart';
import '../bloc/group_chat_event.dart';
import '../bloc/group_chat_state.dart';
import 'group_info_screen.dart';

/// Group Chat Screen ("Culture Circle").
///
/// Reuses the [GroupChatBloc] (single message write; server-side fan-out).
/// Messages stream newest-first; the list is rendered reversed so new messages
/// appear at the bottom without re-sorting.
class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    this.groupPhotoUrl,
  });

  final String groupId;
  final String groupName;
  final String currentUserId;
  final String? groupPhotoUrl;

  static Route<void> route({
    required String groupId,
    required String groupName,
    required String currentUserId,
    String? groupPhotoUrl,
  }) {
    return MaterialPageRoute(
      builder: (_) => GroupChatScreen(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
        groupPhotoUrl: groupPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GroupChatBloc>(
      create: (_) => sl<GroupChatBloc>()
        ..add(GroupChatStarted(groupId: groupId, userId: currentUserId)),
      child: _GroupChatView(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
        groupPhotoUrl: groupPhotoUrl,
      ),
    );
  }
}

class _GroupChatView extends StatefulWidget {
  const _GroupChatView({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    this.groupPhotoUrl,
  });

  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;
  final String currentUserId;

  @override
  State<_GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<_GroupChatView> {
  final _controller = TextEditingController();
  final Set<String> _resolvingNames = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolves display names for any message senders not yet cached, then
  /// rebuilds so the bubbles show names instead of raw user ids.
  void _ensureNames(Iterable<String> ids) {
    final missing = ids
        .toSet()
        .where((id) =>
            id.isNotEmpty &&
            UserDirectoryService.instance.cached(id) == null &&
            !_resolvingNames.contains(id))
        .toList();
    if (missing.isEmpty) return;
    _resolvingNames.addAll(missing);
    UserDirectoryService.instance.resolve(missing).then((_) {
      if (mounted) setState(() => _resolvingNames.removeAll(missing));
    });
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context
        .read<GroupChatBloc>()
        .add(GroupChatMessageSent(content: text));
    _controller.clear();
  }

  Future<void> _sendVoice(BuildContext context, File file, Duration duration) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uuid = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_voice/${widget.groupId}/$uuid.m4a');
      await ref.putFile(file, SettableMetadata(contentType: 'audio/mp4'));
      final url = await ref.getDownloadURL();
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      bloc.add(GroupChatMessageSent(
        content: url,
        type: MessageType.voiceNote,
        metadata: {'durationMs': duration.inMilliseconds},
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.voiceFailedToSend),
      ));
    }
  }

  Future<void> _sendLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GroupChatBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final position = await const LocationShareService().getCurrentPosition();
    if (position == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatLocationDenied)));
      return;
    }
    bloc.add(GroupChatMessageSent(
      content: '${position.latitude},${position.longitude}',
      type: MessageType.location,
      metadata:
          LocationShareService.metadataFor(position.latitude, position.longitude),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
            GroupInfoScreen.route(
              groupId: widget.groupId,
              currentUserId: widget.currentUserId,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (widget.groupPhotoUrl != null &&
                        widget.groupPhotoUrl!.isNotEmpty)
                    ? NetworkImage(widget.groupPhotoUrl!)
                    : null,
                child: (widget.groupPhotoUrl == null ||
                        widget.groupPhotoUrl!.isEmpty)
                    ? Text(
                        widget.groupName.isNotEmpty
                            ? widget.groupName[0].toUpperCase()
                            : '#',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.groupName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: AppLocalizations.of(context)!.groupInfo,
            onPressed: () => Navigator.of(context).push(
              GroupInfoScreen.route(
                groupId: widget.groupId,
                currentUserId: widget.currentUserId,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<GroupChatBloc, GroupChatState>(
        listener: (context, state) {
          if (state is GroupChatActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GroupChatLeftSuccess) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        builder: (context, state) {
          if (state is GroupChatLoading || state is GroupChatInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GroupChatError) {
            return Center(child: Text(state.message));
          }
          final messages =
              state is GroupChatLoaded ? state.messages : <Message>[];
          _ensureNames(messages.map((m) => m.senderId));
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context)!.groupSayHello))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          return _GroupMessageBubble(
                            message: m,
                            isMine: m.senderId == widget.currentUserId,
                            currentUserId: widget.currentUserId,
                          );
                        },
                      ),
              ),
              _InputBar(
                controller: _controller,
                onSend: () => _send(context),
                onAttachLocation: () => _sendLocation(context),
                onSendVoice: (file, dur) => _sendVoice(context, file, dur),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({
    required this.message,
    required this.isMine,
    required this.currentUserId,
  });

  final Message message;
  final bool isMine;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.content,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  UserDirectoryService.instance.nameFor(message.senderId),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (message.type == MessageType.location)
              _LocationContent(message: message, isMine: isMine)
            else if (message.type == MessageType.event)
              EventMessageCard(
                metadata: message.metadata,
                currentUserId: currentUserId,
                onDark: isMine,
              )
            else if (message.type == MessageType.voiceNote)
              VoiceMessageWidget(
                isCurrentUser: isMine,
                audioUrl: message.content,
                duration: (message.metadata?['durationMs'] is int)
                    ? Duration(
                        milliseconds: message.metadata!['durationMs'] as int)
                    : null,
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isMine
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tappable shared-location card that opens the coordinates in Maps.
class _LocationContent extends StatelessWidget {
  const _LocationContent({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color =
        isMine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final loc = LocationShareService.parse(message.content);
    return InkWell(
      onTap: loc == null
          ? null
          : () => launchUrl(
                Uri.parse(LocationShareService.mapsUrl(loc.lat, loc.lng)),
                mode: LaunchMode.externalApplication,
              ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chatLocation,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              Text(
                l10n.chatOpenInMaps,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttachLocation,
    required this.onSendVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachLocation;
  final void Function(File file, Duration duration) onSendVoice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: AppLocalizations.of(context)!.chatShareLocation,
              onPressed: onAttachLocation,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.groupMessageHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            VoiceRecordSendButton(
              controller: controller,
              radius: 22,
              onSendText: onSend,
              onSendVoice: onSendVoice,
            ),
          ],
        ),
      ),
    );
  }
}
