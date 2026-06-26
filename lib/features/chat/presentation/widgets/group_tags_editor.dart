import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/group_tags_service.dart';

/// Group Info section: the current user's PRIVATE tags for this group.
///
/// Shows the user's own tags as chips (or an empty hint) and an edit action.
/// Changes are written to the per-user `user_group_tags` doc and affect only
/// this user — never the group or other members.
class MyGroupTagsTile extends StatelessWidget {
  MyGroupTagsTile({
    super.key,
    required this.groupId,
    required this.userId,
    GroupTagsService? service,
  }) : service = service ?? GroupTagsService();

  final String groupId;
  final String userId;
  final GroupTagsService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Map<String, List<String>>>(
      stream: service.watchAll(userId),
      builder: (context, snap) {
        final tags = snap.data?[groupId] ?? const <String>[];
        return ListTile(
          leading: Icon(Icons.sell_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: Text(l10n.groupMyTags),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.groupMyTagsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in tags)
                      Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(l10n.groupNoTagsYet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary)),
              ],
            ],
          ),
          trailing: const Icon(Icons.edit_outlined),
          isThreeLine: tags.isNotEmpty,
          onTap: () => _edit(context, tags),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, List<String> current) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final updated = await showEditGroupTagsDialog(context, current);
    if (updated == null) return;
    try {
      await service.setTagsForGroup(userId, groupId, updated);
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupTagsSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupTagsSaveFailed)));
    }
  }
}

/// Modal to add/remove the user's personal tags for a group. Returns the new
/// tag list, or null if cancelled.
Future<List<String>?> showEditGroupTagsDialog(
  BuildContext context,
  List<String> current,
) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _EditGroupTagsDialog(initial: current),
  );
}

class _EditGroupTagsDialog extends StatefulWidget {
  const _EditGroupTagsDialog({required this.initial});

  final List<String> initial;

  @override
  State<_EditGroupTagsDialog> createState() => _EditGroupTagsDialogState();
}

class _EditGroupTagsDialogState extends State<_EditGroupTagsDialog> {
  late final List<String> _tags = [...widget.initial];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text;
    final merged = GroupTagsService.normalize([..._tags, raw]);
    setState(() {
      _tags
        ..clear()
        ..addAll(merged);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final atLimit = _tags.length >= GroupTagsService.maxTagsPerGroup;
    return AlertDialog(
      title: Text(l10n.groupTagsEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.groupMyTagsSubtitle,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_tags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l10n.groupNoTagsYet,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in _tags)
                  Chip(
                    label: Text(t),
                    onDeleted: () => setState(() => _tags.remove(t)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            enabled: !atLimit,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            maxLength: GroupTagsService.maxTagLength,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText:
                  atLimit ? l10n.groupTagsLimitReached : l10n.groupAddTagHint,
              isDense: true,
              counterText: '',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: atLimit ? null : _add,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.groupCancel),
        ),
        TextButton(
          onPressed: () {
            // Include any tag typed but not yet added via the "+" button.
            final merged =
                GroupTagsService.normalize([..._tags, _controller.text]);
            Navigator.of(context).pop(merged);
          },
          child: Text(l10n.groupTagsSave),
        ),
      ],
    );
  }
}
