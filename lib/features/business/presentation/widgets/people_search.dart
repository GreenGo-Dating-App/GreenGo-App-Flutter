import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/profile.dart';

/// Advanced search over a business's people (Followers, Contacts): owner
/// request 2026-10-15. Name, country, language, period and, for contacts, the
/// kind of contact. Applied on the device to a bounded, fully loaded list.
@immutable
class PeopleQuery {
  const PeopleQuery({this.text = '', this.country, this.language, this.sinceDays, this.leadType});

  final String text;
  final String? country;

  /// Language code or name as stored on profiles (spoken or native).
  final String? language;

  /// Only people added in the last N days (followed / contacted).
  final int? sinceDays;

  /// Contacts only: 'contact' | 'saved_event'.
  final String? leadType;

  bool get isActive =>
      text.trim().isNotEmpty || country != null || language != null || sinceDays != null || leadType != null;

  int get filterCount => [country, language, sinceDays, leadType].where((x) => x != null).length;

  PeopleQuery copyWith({
    String? text,
    String? country,
    String? language,
    int? sinceDays,
    String? leadType,
    bool clearCountry = false,
    bool clearLanguage = false,
    bool clearSince = false,
    bool clearLeadType = false,
  }) =>
      PeopleQuery(
        text: text ?? this.text,
        country: clearCountry ? null : (country ?? this.country),
        language: clearLanguage ? null : (language ?? this.language),
        sinceDays: clearSince ? null : (sinceDays ?? this.sinceDays),
        leadType: clearLeadType ? null : (leadType ?? this.leadType),
      );
}

/// One person of the list with what the filters look at.
@immutable
class PersonFacts {
  const PersonFacts({required this.uid, this.name = '', this.profile, this.addedAt, this.leadType});

  final String uid;
  final String name;
  final Profile? profile;
  final DateTime? addedAt;
  final String? leadType;

  String get country => profile?.location.country.trim() ?? '';

  List<String> get languages => {
        ...?profile?.languages.map((l) => l.trim()).where((l) => l.isNotEmpty),
        if ((profile?.nativeLanguage ?? '').trim().isNotEmpty) profile!.nativeLanguage!.trim(),
      }.toList();
}

bool _fold(String a, String b) => a.toLowerCase().contains(b.toLowerCase());

/// Does [p] match [q] at [now]?
bool matchesPeopleQuery(PersonFacts p, PeopleQuery q, DateTime now) {
  final t = q.text.trim();
  if (t.isNotEmpty) {
    final nick = p.profile?.nickname ?? '';
    if (!_fold(p.name, t) && !_fold(nick, t)) return false;
  }
  if (q.country != null && p.country.toLowerCase() != q.country!.toLowerCase()) return false;
  if (q.language != null && !p.languages.any((l) => l.toLowerCase() == q.language!.toLowerCase())) return false;
  if (q.sinceDays != null) {
    final at = p.addedAt;
    if (at == null || at.isBefore(now.subtract(Duration(days: q.sinceDays!)))) return false;
  }
  if (q.leadType != null && p.leadType != q.leadType) return false;
  return true;
}

/// Search field + Filters button + active-filter chips.
class PeopleSearchBar extends StatefulWidget {
  const PeopleSearchBar({
    required this.query,
    required this.onChanged,
    required this.people,
    this.showLeadType = false,
    this.showSince = true,
    super.key,
  });

  final PeopleQuery query;
  final ValueChanged<PeopleQuery> onChanged;

  /// Loaded people (filter options come from them; empty before loading).
  final List<PersonFacts> people;
  final bool showLeadType;
  final bool showSince;

  @override
  State<PeopleSearchBar> createState() => _PeopleSearchBarState();
}

class _PeopleSearchBarState extends State<PeopleSearchBar> {
  late final TextEditingController _text = TextEditingController(text: widget.query.text);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final l = AppLocalizations.of(context)!;
    final countries = (widget.people.map((p) => p.country).where((c) => c.isNotEmpty).toSet().toList()..sort());
    final languages = (widget.people.expand((p) => p.languages).toSet().toList()..sort());
    final q = await showModalBottomSheet<PeopleQuery>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      builder: (_) => _FiltersSheet(
        start: widget.query,
        countries: countries,
        languages: languages,
        showLeadType: widget.showLeadType,
        showSince: widget.showSince,
        l: l,
      ),
    );
    if (q != null) widget.onChanged(q.copyWith(text: _text.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final q = widget.query;
    final chips = <Widget>[
      if (q.country != null) _chip(q.country!, () => widget.onChanged(q.copyWith(clearCountry: true))),
      if (q.language != null) _chip(q.language!, () => widget.onChanged(q.copyWith(clearLanguage: true))),
      if (q.sinceDays != null)
        _chip(l.peopleSearchLastDays(q.sinceDays!), () => widget.onChanged(q.copyWith(clearSince: true))),
      if (q.leadType != null)
        _chip(q.leadType == 'saved_event' ? l.businessLeadSavedEvent : l.businessLeadContact,
            () => widget.onChanged(q.copyWith(clearLeadType: true))),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingL, 8, AppDimensions.paddingL, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              key: const ValueKey('people-search-text'),
              controller: _text,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: l.peopleSearchHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _text.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 18),
                        onPressed: () {
                          _text.clear();
                          widget.onChanged(q.copyWith(text: ''));
                        },
                      ),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => widget.onChanged(q.copyWith(text: v)),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: q.filterCount > 0,
            label: Text('${q.filterCount}'),
            backgroundColor: AppColors.richGold,
            textColor: AppColors.backgroundDark,
            child: IconButton(
              key: const ValueKey('people-search-filters'),
              tooltip: l.peopleSearchFilters,
              icon: const Icon(Icons.tune, color: AppColors.richGold),
              onPressed: _openFilters,
            ),
          ),
        ]),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ]),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) => InputChip(
        label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
        backgroundColor: AppColors.backgroundCard,
        side: const BorderSide(color: AppColors.divider),
        deleteIconColor: AppColors.textTertiary,
        onDeleted: onRemove,
      );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.start,
    required this.countries,
    required this.languages,
    required this.showLeadType,
    required this.showSince,
    required this.l,
  });

  final PeopleQuery start;
  final List<String> countries;
  final List<String> languages;
  final bool showLeadType;
  final bool showSince;
  final AppLocalizations l;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late PeopleQuery q = widget.start;

  Widget _section(String title, List<Widget> chips) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ]);

  Widget _choice<T>(String label, T value, T? current, ValueChanged<T?> set, {String? key}) => ChoiceChip(
        key: key == null ? null : ValueKey(key),
        label: Text(label),
        selected: current == value,
        selectedColor: AppColors.richGold.withValues(alpha: 0.25),
        backgroundColor: AppColors.backgroundDark,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
        onSelected: (on) => setState(() => set(on ? value : null)),
      );

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          key: const ValueKey('people-filters-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            Text(l.peopleSearchFilters,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            if (widget.showLeadType)
              _section(l.peopleSearchContactType, [
                _choice(l.businessLeadContact, 'contact', q.leadType,
                    (v) => q = v == null ? q.copyWith(clearLeadType: true) : q.copyWith(leadType: v),
                    key: 'people-filter-type-contact'),
                _choice(l.businessLeadSavedEvent, 'saved_event', q.leadType,
                    (v) => q = v == null ? q.copyWith(clearLeadType: true) : q.copyWith(leadType: v),
                    key: 'people-filter-type-saved'),
              ]),
            if (widget.showSince)
              _section(l.peopleSearchPeriod, [
                for (final d in const [7, 30, 90, 365])
                  _choice(l.peopleSearchLastDays(d), d, q.sinceDays,
                      (v) => q = v == null ? q.copyWith(clearSince: true) : q.copyWith(sinceDays: v),
                      key: 'people-filter-since-$d'),
              ]),
            if (widget.countries.isNotEmpty)
              _section(l.peopleSearchCountry, [
                for (final c in widget.countries)
                  _choice(c, c, q.country, (v) => q = v == null ? q.copyWith(clearCountry: true) : q.copyWith(country: v)),
              ]),
            if (widget.languages.isNotEmpty)
              _section(l.peopleSearchLanguage, [
                for (final c in widget.languages)
                  _choice(c, c, q.language, (v) => q = v == null ? q.copyWith(clearLanguage: true) : q.copyWith(language: v)),
              ]),
            const SizedBox(height: 18),
            Row(children: [
              TextButton(
                key: const ValueKey('people-filters-clear'),
                onPressed: () => Navigator.of(context).pop(PeopleQuery(text: q.text)),
                child: Text(l.peopleSearchClear, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              const Spacer(),
              ElevatedButton(
                key: const ValueKey('people-filters-apply'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold, foregroundColor: AppColors.backgroundDark),
                onPressed: () => Navigator.of(context).pop(q),
                child: Text(l.peopleSearchApply),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
