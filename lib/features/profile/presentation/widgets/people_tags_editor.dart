import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/people_tags_service.dart';

/// Opens the PRIVATE people-tags editor for a target person and persists the
/// result via [PeopleTagsService].
///
/// The [ownerId] is the current user; the tags belong to them alone and only
/// they ever see them. [targetUserId] is the person being tagged and
/// [targetName] titles the sheet. Reads the owner's current tags for this
/// person once, shows the chip editor, and writes back on save. Shows a
/// snackbar on success/failure. Safe to call from a long-press handler.
Future<void> showPeopleTagsEditor(
  BuildContext context, {
  required String ownerId,
  required String targetUserId,
  required String targetName,
  PeopleTagsService? service,
}) async {
  final svc = service ?? PeopleTagsService();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;

  List<String> current = const <String>[];
  try {
    final all = await svc.getAll(ownerId);
    current = all[targetUserId] ?? const <String>[];
  } catch (_) {
    // Non-fatal — start from an empty set.
  }
  if (!context.mounted) return;

  final updated = await showEditPeopleTagsDialog(
    context,
    current: current,
    targetName: targetName,
  );
  if (updated == null) return;

  try {
    await svc.setTagsForPerson(
      ownerId: ownerId,
      targetUserId: targetUserId,
      tags: updated,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.groupTagsSaved)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.groupTagsSaveFailed)));
  }
}

/// Modal to add/remove the owner's personal tags for a person. Returns the new
/// tag list, or null if cancelled.
Future<List<String>?> showEditPeopleTagsDialog(
  BuildContext context, {
  required List<String> current,
  required String targetName,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _EditPeopleTagsDialog(
      initial: current,
      targetName: targetName,
    ),
  );
}

/// Group Info-style tile that shows the owner's PRIVATE tags for a person and
/// opens the editor on tap. Mirrors `MyGroupTagsTile` but keyed by target user.
class MyPeopleTagsTile extends StatelessWidget {
  MyPeopleTagsTile({
    super.key,
    required this.ownerId,
    required this.targetUserId,
    required this.targetName,
    PeopleTagsService? service,
  }) : service = service ?? PeopleTagsService();

  final String ownerId;
  final String targetUserId;
  final String targetName;
  final PeopleTagsService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<Map<String, List<String>>>(
      stream: service.watchAll(ownerId),
      builder: (context, snap) {
        final tags = snap.data?[targetUserId] ?? const <String>[];
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
          onTap: () => showPeopleTagsEditor(
            context,
            ownerId: ownerId,
            targetUserId: targetUserId,
            targetName: targetName,
            service: service,
          ),
        );
      },
    );
  }
}

class _EditPeopleTagsDialog extends StatefulWidget {
  const _EditPeopleTagsDialog({
    required this.initial,
    required this.targetName,
  });

  final List<String> initial;
  final String targetName;

  @override
  State<_EditPeopleTagsDialog> createState() => _EditPeopleTagsDialogState();
}

class _EditPeopleTagsDialogState extends State<_EditPeopleTagsDialog> {
  late final List<String> _tags = [...widget.initial];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text;
    final merged = PeopleTagsService.normalize([..._tags, raw]);
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
    final atLimit = _tags.length >= PeopleTagsService.maxTagsPerPerson;
    return AlertDialog(
      title: Text(l10n.peopleTagsEditTitle(widget.targetName)),
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
            maxLength: PeopleTagsService.maxTagLength,
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
                PeopleTagsService.normalize([..._tags, _controller.text]);
            Navigator.of(context).pop(merged);
          },
          child: Text(l10n.groupTagsSave),
        ),
      ],
    );
  }
}
