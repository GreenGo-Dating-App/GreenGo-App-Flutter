import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
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
  final _selected = <String>{};
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty &&
      _selected.isNotEmpty &&
      !_creating;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          TextButton(
            onPressed: _canCreate ? _create : null,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
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
              decoration: const InputDecoration(
                labelText: 'Group name',
                prefixIcon: Icon(Icons.groups_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_selected.length} selected'),
              ),
            ),
          const Divider(),
          Expanded(
            child: widget.candidates.isEmpty
                ? const Center(child: Text('No contacts to add yet'))
                : ListView.builder(
                    itemCount: widget.candidates.length,
                    itemBuilder: (context, index) {
                      final c = widget.candidates[index];
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
