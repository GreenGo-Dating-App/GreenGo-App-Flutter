import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../buddy_labels.dart';

/// The Buddy category: a searchable combobox of the 121 topics. Each entry
/// shows its group; typing filters on the localized topic AND group labels.
class BuddyCategoryField extends StatelessWidget {
  const BuddyCategoryField({required this.onSelected, this.selected, super.key});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupOf = <String, String>{
      for (final t in kBuddyTopics) t.id: buddyTopicGroupLabel(l10n, t.group),
    };
    final entries = <DropdownMenuEntry<String>>[
      for (final t in kBuddyTopics)
        DropdownMenuEntry<String>(
          value: t.id,
          label: buddyTopicLabel(l10n, t.id),
          trailingIcon: Text(
            groupOf[t.id]!,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
    ];
    final selectedLabel = selected == null ? null : buddyTopicLabel(l10n, selected!);
    return DropdownMenu<String>(
      key: const ValueKey('buddy-category'),
      initialSelection: selected,
      dropdownMenuEntries: entries,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      label: Text(l10n.buddyCategoryLabel),
      hintText: l10n.buddyCategoryHint,
      leadingIcon: const Icon(Icons.search, color: AppColors.textTertiary),
      textStyle: const TextStyle(color: AppColors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.backgroundCard),
      ),
      filterCallback: (all, filter) {
        final q = filter.trim().toLowerCase();
        // Opening the menu with a category already chosen shows everything.
        if (q.isEmpty || filter == selectedLabel) return all;
        return [
          for (final e in all)
            if (e.label.toLowerCase().contains(q) || groupOf[e.value]!.toLowerCase().contains(q)) e,
        ];
      },
      onSelected: (id) {
        if (id != null) onSelected(id);
      },
    );
  }
}

/// Category picker dialog (quick settings). Pops the chosen topic id.
Future<String?> showBuddyCategoryDialog(BuildContext context, {String? selected}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundDark,
      title: Text(l10n.buddyCategoryLabel, style: const TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: BuddyCategoryField(
          selected: selected,
          onSelected: (id) => Navigator.of(ctx).pop(id),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
      ],
    ),
  );
}
