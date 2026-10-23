import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../buddy_labels.dart';

/// Searchable, grouped list of the 121 Buddy topics (12 groups). Searching
/// matches the localized topic AND group labels.
class BuddyTopicPicker extends StatefulWidget {
  const BuddyTopicPicker({required this.onSelected, this.selected, this.header, super.key});

  final String? selected;
  final ValueChanged<String> onSelected;

  /// Shown above the topics while not searching (e.g. ready-made suggestions).
  final Widget? header;

  @override
  State<BuddyTopicPicker> createState() => _BuddyTopicPickerState();
}

class _BuddyTopicPickerState extends State<BuddyTopicPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = _query.trim().toLowerCase();
    final slivers = <Widget>[];
    var any = false;
    for (final g in kBuddyTopicGroups) {
      final groupLabel = buddyTopicGroupLabel(l10n, g);
      final groupHit = q.isNotEmpty && groupLabel.toLowerCase().contains(q);
      final topics = kBuddyTopics
          .where((t) => t.group == g)
          .where((t) =>
              q.isEmpty || groupHit || buddyTopicLabel(l10n, t.id).toLowerCase().contains(q))
          .toList();
      if (topics.isEmpty) continue;
      any = true;
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(groupLabel,
              style: const TextStyle(
                  color: AppColors.richGold, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ));
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in topics)
                ChoiceChip(
                  key: ValueKey('buddy-topic-${t.id}'),
                  label: Text(buddyTopicLabel(l10n, t.id)),
                  selected: widget.selected == t.id,
                  onSelected: (_) => widget.onSelected(t.id),
                  selectedColor: AppColors.richGold,
                  backgroundColor: AppColors.backgroundCard,
                  labelStyle: TextStyle(
                    color: widget.selected == t.id ? AppColors.deepBlack : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const ValueKey('buddy-topic-search'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.buddyTopicSearchHint,
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (q.isEmpty && widget.header != null) SliverToBoxAdapter(child: widget.header),
              ...slivers,
              if (!any)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(l10n.buddyNoTopicsFound,
                        style: const TextStyle(color: AppColors.textTertiary)),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen topic picker (quick settings). Pops the chosen topic id.
class BuddyTopicPickerScreen extends StatelessWidget {
  const BuddyTopicPickerScreen({this.selected, super.key});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.buddySettingTopic),
      ),
      body: BuddyTopicPicker(
        selected: selected,
        onSelected: (id) => Navigator.of(context).pop(id),
      ),
    );
  }
}
