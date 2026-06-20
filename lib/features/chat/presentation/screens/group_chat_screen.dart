import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
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
  });

  final String groupId;
  final String groupName;
  final String currentUserId;

  static Route<void> route({
    required String groupId,
    required String groupName,
    required String currentUserId,
  }) {
    return MaterialPageRoute(
      builder: (_) => GroupChatScreen(
        groupId: groupId,
        groupName: groupName,
        currentUserId: currentUserId,
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
      ),
    );
  }
}

class _GroupChatView extends StatefulWidget {
  const _GroupChatView({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  final String groupId;
  final String groupName;
  final String currentUserId;

  @override
  State<_GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<_GroupChatView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context
        .read<GroupChatBloc>()
        .add(GroupChatMessageSent(content: text));
    _controller.clear();
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
                child: Text(
                  widget.groupName.isNotEmpty
                      ? widget.groupName[0].toUpperCase()
                      : '#',
                ),
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
            tooltip: 'Group info',
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
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('Say hello to the group 👋'))
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
                          );
                        },
                      ),
              ),
              _InputBar(controller: _controller, onSend: () => _send(context)),
            ],
          );
        },
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  const _GroupMessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

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
                  message.senderId,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
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

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
