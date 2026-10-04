import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/people_tags_service.dart';
import '../../../../core/utils/user_error.dart';

/// Opens the PRIVATE people-tags editor for a target person.
///
/// The [ownerId] is the current user; the tags belong to them alone and only
/// they ever see them. [targetUserId] is the person being tagged and
/// [targetName] titles the dialog. The owner's whole tag library (every
/// distinct tag they have created, most-recently-used first) is offered as
/// chips: tapping one applies/removes it for this person immediately, and the
/// text field below creates a new tag (or picks the existing one when the name
/// matches case-insensitively). The library comes from the session cache when
/// available (instant), otherwise one bounded doc read. Safe to call from a
/// long-press handler.
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

  var library = svc.cachedLibrary(ownerId);
  if (library == null) {
    try {
      library = await svc.getLibrary(ownerId);
    } catch (_) {
      // Non-fatal — start from an empty library.
      library = const PeopleTagsLibrary(peopleTags: {}, recent: []);
    }
    if (!context.mounted) return;
  }

  final result = await showDialog<_TagsEditResult>(
    context: context,
    builder: (_) => _EditPeopleTagsDialog(
      service: svc,
      ownerId: ownerId,
      targetUserId: targetUserId,
      targetName: targetName,
      library: library!.allTags,
      initial: library.tagsFor(targetUserId),
      messenger: messenger,
    ),
  );
  if (result == null) return;
  // Wait for in-flight writes so the confirmation reflects the real outcome.
  final ok = await result.done;
  if (ok && result.changed) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.groupTagsSaved)));
  }
}

class _TagsEditResult {
  const _TagsEditResult({required this.changed, required this.done});
  final bool changed;

  /// Completes with false if any write failed.
  final Future<bool> done;
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
    required this.service,
    required this.ownerId,
    required this.targetUserId,
    required this.targetName,
    required this.library,
    required this.initial,
    required this.messenger,
  });

  final PeopleTagsService service;
  final String ownerId;
  final String targetUserId;
  final String targetName;
  final List<String> library;
  final List<String> initial;
  final ScaffoldMessengerState messenger;

  @override
  State<_EditPeopleTagsDialog> createState() => _EditPeopleTagsDialogState();
}

class _EditPeopleTagsDialogState extends State<_EditPeopleTagsDialog> {
  /// Every tag offered as a chip. Stable while the dialog is open (a tag
  /// toggled off the only person using it stays visible so it can be
  /// re-applied).
  late final List<String> _library = _mergeLibrary();

  /// Tags applied to the target person, in apply order.
  late final List<String> _applied = [...widget.initial];

  final _controller = TextEditingController();

  /// Writes are chained so they land in order; completes false on any failure.
  Future<bool> _writes = Future.value(true);
  bool _changed = false;
  bool _closed = false;

  List<String> _mergeLibrary() {
    final seen = <String>{};
    final out = <String>[];
    // Tags already on this person are always offered, even past the cap.
    for (final t in [...widget.library, ...widget.initial]) {
      if (seen.add(t.toLowerCase())) out.add(t);
    }
    return out;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isApplied(String tag) {
    final key = tag.toLowerCase();
    return _applied.any((t) => t.toLowerCase() == key);
  }

  bool get _atLimit => _applied.length >= PeopleTagsService.maxTagsPerPerson;

  void _toggle(String tag) {
    if (_isApplied(tag)) {
      final key = tag.toLowerCase();
      setState(() => _applied.removeWhere((t) => t.toLowerCase() == key));
      _persist();
    } else {
      if (_atLimit) return;
      setState(() => _applied.add(tag));
      _persist(bump: [tag]);
    }
  }

  void _create() {
    final tag = PeopleTagsService.cleanTag(_controller.text);
    if (tag.isEmpty) return;
    final key = tag.toLowerCase();
    final existing = _library.firstWhere(
      (t) => t.toLowerCase() == key,
      orElse: () => '',
    );
    _controller.clear();
    if (existing.isNotEmpty) {
      // Same name as a tag they already have: select that one, never a dupe.
      if (!_isApplied(existing)) _toggle(existing);
      return;
    }
    if (_atLimit) return;
    setState(() {
      _library.insert(0, tag);
      _applied.add(tag);
    });
    _persist(bump: [tag]);
  }

  void _persist({List<String> bump = const []}) {
    _changed = true;
    final tags = List<String>.of(_applied);
    final failedText = AppLocalizations.of(context)!.groupTagsSaveFailed;
    _writes = _writes.then((okSoFar) async {
      try {
        await widget.service.setTagsForPerson(
          ownerId: widget.ownerId,
          targetUserId: widget.targetUserId,
          tags: tags,
          bump: bump,
        );
        return okSoFar;
      } catch (_) {
        if (mounted && !_closed) {
          showUserErrorMessage(context, failedText);
        } else {
          // The sheet is gone: no context to anchor a popup on.
          widget.messenger.showSnackBar(SnackBar(content: Text(failedText)));
        }
        if (mounted && !_closed) {
          // Re-sync with what is actually stored (the cache was rolled back).
          final stored = widget.service
                  .cachedLibrary(widget.ownerId)
                  ?.tagsFor(widget.targetUserId) ??
              const <String>[];
          setState(() {
            _applied
              ..clear()
              ..addAll(stored);
          });
        }
        return false;
      }
    });
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(_TagsEditResult(
      changed: _changed,
      done: _writes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final atLimit = _atLimit;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        scrollable: true,
        title: Text(l10n.peopleTagsEditTitle(widget.targetName)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.groupMyTagsSubtitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(
                l10n.groupMyTags,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              if (_library.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(l10n.groupNoTagsYet,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textTertiary)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in _library)
                          _TagChip(
                            label: t,
                            selected: _isApplied(t),
                            enabled: _isApplied(t) || !atLimit,
                            onTap: () => _toggle(t),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                enabled: !atLimit,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                maxLength: PeopleTagsService.maxTagLength,
                onSubmitted: (_) => _create(),
                decoration: InputDecoration(
                  hintText: atLimit
                      ? l10n.groupTagsLimitReached
                      : l10n.groupAddTagHint,
                  isDense: true,
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: atLimit ? null : _create,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Apply any name typed but not yet added via the "+" button.
              if (_controller.text.trim().isNotEmpty) _create();
              _close();
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

/// Selectable library chip: gold-tinted with a check when applied.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      showCheckmark: true,
      checkmarkColor: AppColors.richGold,
      selectedColor: AppColors.richGold.withValues(alpha: 0.22),
      side: BorderSide(
        color: selected ? AppColors.richGold : AppColors.divider,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.richGold : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
