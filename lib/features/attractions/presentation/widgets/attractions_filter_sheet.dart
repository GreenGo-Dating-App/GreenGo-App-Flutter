import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/attraction_filters.dart';
import '../../domain/category_labels.dart';
import '../../domain/entities/attraction.dart';

/// Bridge between the screen that hosts the Attractions filter icon (the
/// Events search bar) and the [AttractionsTab] that owns the data and state.
///
/// The tab attaches its sheet opener and publishes whether any filter is
/// non-default; the host listens to show the badge and calls [open].
class AttractionsFilterController extends ChangeNotifier {
  bool _active = false;
  Future<void> Function()? _opener;

  /// True when any filter differs from its default.
  bool get active => _active;

  /// Opens the filter sheet. No-op until the tab has attached.
  Future<void> open() async => _opener?.call();

  void attach(Future<void> Function() opener) => _opener = opener;

  void detach(Future<void> Function() opener) {
    // Method tear-offs are == (not necessarily identical) across calls.
    if (_opener == opener) _opener = null;
  }

  void setActive(bool value) {
    if (value == _active) return;
    _active = value;
    notifyListeners();
  }
}

/// A country the sheet can offer: its ISO code and display label.
typedef AttractionCountryOption = ({String iso, String label});

/// Draft-state filter sheet: GreenGo Score, category, country -> city.
///
/// Changes apply only on Done; Clear returns [defaults] immediately. Pops with
/// the chosen [AttractionFilterSelection] (or null when dismissed).
class AttractionsFilterSheet extends StatefulWidget {
  const AttractionsFilterSheet({
    super.key,
    required this.initial,
    required this.defaults,
    required this.countries,
    required this.currentPool,
    required this.loadCountry,
  });

  final AttractionFilterSelection initial;
  final AttractionFilterSelection defaults;
  final List<AttractionCountryOption> countries;

  /// The list the tab is showing for [initial]'s country (search results
  /// while searching) BEFORE any sheet filter is applied.
  final List<Attraction> currentPool;

  /// Memoised per-country loader (the tab's data source), used to list the
  /// cities and categories of a country picked in the sheet.
  final Future<List<Attraction>> Function(String iso) loadCountry;

  static Future<AttractionFilterSelection?> show(
    BuildContext context, {
    required AttractionFilterSelection initial,
    required AttractionFilterSelection defaults,
    required List<AttractionCountryOption> countries,
    required List<Attraction> currentPool,
    required Future<List<Attraction>> Function(String iso) loadCountry,
  }) {
    // A centered dialog (not a bottom sheet), capped in width for tablets
    // and the web.
    return showDialog<AttractionFilterSelection>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.backgroundCard,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AttractionsFilterSheet(
            initial: initial,
            defaults: defaults,
            countries: countries,
            currentPool: currentPool,
            loadCountry: loadCountry,
          ),
        ),
      ),
    );
  }

  @override
  State<AttractionsFilterSheet> createState() => _AttractionsFilterSheetState();
}

class _AttractionsFilterSheetState extends State<AttractionsFilterSheet> {
  late RangeValues _score;
  String? _iso;
  String? _category;
  String? _city;
  late List<Attraction> _pool;
  bool _loadingPool = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _score = RangeValues(i.minScore.toDouble(), i.maxScore.toDouble());
    _iso = i.countryIso;
    _category = i.category;
    _city = i.city;
    _pool = widget.currentPool;
  }

  /// A different country resets city + category and loads that country's
  /// list (memoised, one bounded read) so its cities/categories can be shown.
  Future<void> _pickCountry(String? iso) async {
    if (iso == null || iso == _iso) return;
    setState(() {
      _iso = iso;
      _city = null;
      _category = null;
      _loadingPool = true;
      _pool = const [];
    });
    final list = iso == widget.initial.countryIso
        ? widget.currentPool
        : await widget.loadCountry(iso);
    if (!mounted || _iso != iso) return;
    setState(() {
      _pool = list;
      _loadingPool = false;
    });
  }

  AttractionFilterSelection get _draft => AttractionFilterSelection(
        countryIso: _iso,
        minScore: _score.start.round(),
        maxScore: _score.end.round(),
        category: _category,
        city: _city,
      );

  TextStyle get _sectionStyle => const TextStyle(
      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lo = _score.start.round(), hi = _score.end.round();

    // Cities: the chosen country narrowed by score. Categories: additionally
    // narrowed by city, so every count matches what Done would show.
    final byScore = filterAttractions(_pool, minScore: lo, maxScore: hi);
    final cities = cityFacets(byScore);
    if (_city != null && !cities.any((c) => c.key == _city)) _city = null;
    final byCity = filterAttractions(byScore, city: _city);
    final cats = categoryFacets(byCity,
        labelOf: (c) => CategoryLabels.of(l10n, c));
    if (_category != null && !cats.any((c) => c.key == _category)) {
      _category = null;
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.tune, color: AppColors.richGold, size: 20),
                const SizedBox(width: 8),
                Text(l10n.filters,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- GreenGo Score
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child:
                                Text(l10n.attrScoreLabel, style: _sectionStyle)),
                        Text('$lo – $hi',
                            style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ]),
                      RangeSlider(
                        values: _score,
                        min: kAttrScoreMin.toDouble(),
                        max: kAttrScoreMax.toDouble(),
                        divisions: kAttrScoreMax - kAttrScoreMin,
                        activeColor: AppColors.richGold,
                        inactiveColor: AppColors.richGold.withValues(alpha: 0.2),
                        labels: RangeLabels('$lo', '$hi'),
                        onChanged: (v) => setState(() => _score = v),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$kAttrScoreMin',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12)),
                          Text('$kAttrScoreMax',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 28, color: AppColors.divider),

                      // ---- Category
                      Text(l10n.attrFilterCategory, style: _sectionStyle),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _chip(
                          label: '${l10n.attrAllCategories}  ${byCity.length}',
                          icon: Icons.apps,
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        ...cats.map((c) => _chip(
                              label: '${c.label}  ${c.count}',
                              icon: AttractionIcons.category(c.icon),
                              selected: _category == c.key,
                              onTap: () => setState(() => _category = c.key),
                            )),
                      ]),
                      const Divider(height: 28, color: AppColors.divider),

                      // ---- Country -> City
                      Text(l10n.attrFilterCountry, style: _sectionStyle),
                      const SizedBox(height: 6),
                      _dropdown<String>(
                        value: widget.countries.any((c) => c.iso == _iso)
                            ? _iso
                            : null,
                        icon: Icons.public,
                        items: [
                          for (final c in widget.countries)
                            DropdownMenuItem(
                              value: c.iso,
                              child: Text(c.label,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _pickCountry,
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child:
                                Text(l10n.attrFilterCity, style: _sectionStyle)),
                        if (_loadingPool)
                          const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.richGold)),
                      ]),
                      const SizedBox(height: 6),
                      _dropdown<String?>(
                        value: _city,
                        icon: Icons.location_city,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                                '${l10n.attrAllCities}  ${byScore.length}'),
                          ),
                          for (final c in cities)
                            DropdownMenuItem<String?>(
                              value: c.key,
                              child: Text('${c.label}  ${c.count}',
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _loadingPool
                            ? null
                            : (v) => setState(() {
                                  _city = v;
                                }),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, widget.defaults),
                  child: Text(l10n.clearFilters,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _draft),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.attrApplyFilter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fg = selected ? AppColors.deepBlack : AppColors.textPrimary;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon,
          size: 15, color: selected ? AppColors.deepBlack : AppColors.richGold),
      label: Text(label),
      labelStyle:
          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
      backgroundColor: AppColors.backgroundInput,
      selectedColor: AppColors.richGold,
      side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.35)),
      onSelected: (_) => onTap(),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.richGold),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              menuMaxHeight: 420,
              dropdownColor: AppColors.backgroundCard,
              iconEnabledColor: AppColors.richGold,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}
