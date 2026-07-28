import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/attractions_datasource.dart';
import '../../domain/category_labels.dart';
import '../../domain/entities/attraction.dart';

/// Full attraction page. Opens instantly from the compact record already in
/// memory, then upgrades in place once the full document arrives (1 read).
class AttractionDetailScreen extends StatefulWidget {
  const AttractionDetailScreen({
    super.key,
    required this.attractionId,
    required this.bucket,
    this.fallback,
  });

  final int attractionId;
  final String bucket;
  final Attraction? fallback;

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
  Attraction? _a;
  bool _loading = true;

  /// One toggle translates EVERY prose block on the page, rather than putting a
  /// separate "Translate" link under each of six sections. Uses the same shared
  /// [TranslationService] as chat, so its cache is shared and repeat views are
  /// free. Nothing is stored server-side — translation is per-viewer.
  bool _translated = false;
  bool _translating = false;
  final Map<String, String> _tr = {}; // original -> translated

  @override
  void initState() {
    super.initState();
    _a = widget.fallback;
    _load();
  }

  Future<void> _load() async {
    final full = await AttractionsDataSource().byId(widget.attractionId);
    if (!mounted) return;
    setState(() {
      if (full != null) _a = full;
      _loading = false;
    });
  }

  /// Collect every translatable prose field, translate what is not cached, and
  /// flip the page into the viewer's language.
  Future<void> _toggleTranslate(Attraction a, String target) async {
    if (_translating) return;
    if (_translated) {
      setState(() => _translated = false);
      return;
    }
    final texts = <String>[
      if (a.descriptionMedium != null) a.descriptionMedium!,
      if (a.descriptionLong != null) a.descriptionLong!,
      if (a.descriptionShort != null) a.descriptionShort!,
      if (a.historySummary != null) a.historySummary!,
      if (a.photographyTips != null) a.photographyTips!,
      if (a.bestSeason != null) a.bestSeason!,
      if (a.bestTimeOfDay != null) a.bestTimeOfDay!,
      if (a.visitDuration != null) a.visitDuration!,
      if (a.openingHours != null) a.openingHours!,
      ...a.topHighlights,
      ...a.interestingFacts,
    ].where((t) => t.trim().isNotEmpty).toSet();

    setState(() => _translating = true);
    final svc = TranslationService();
    for (final t in texts) {
      if (_tr.containsKey(t)) continue;
      try {
        final out = await svc.translate(
          text: t, sourceLanguage: 'auto', targetLanguage: target);
        if (out.trim().isNotEmpty) _tr[t] = out;
      } catch (_) {/* leave this block in the original language */}
    }
    if (!mounted) return;
    setState(() {
      _translating = false;
      _translated = true;
    });
  }

  /// Translated text when the toggle is on and we have one, else the original.
  String _t(String? original) {
    if (original == null) return '';
    if (!_translated) return original;
    return _tr[original] ?? original;
  }

  List<String> _tList(List<String> xs) =>
      _translated ? xs.map((e) => _tr[e] ?? e).toList() : xs;

  Future<void> _openMaps(Attraction a) async {
    final q = (a.lat != null && a.lng != null)
        ? '${a.lat},${a.lng}'
        : Uri.encodeComponent('${a.name} ${a.cityName}');
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      mode: LaunchMode.externalApplication,
    );
  }

  String _tierLabel(AppLocalizations l10n, String? t) {
    switch (t) {
      case 'iconic':
        return l10n.attrTierIconic;
      case 'exceptional':
        return l10n.attrTierExceptional;
      case 'excellent':
        return l10n.attrTierExcellent;
      case 'great':
        return l10n.attrTierGreat;
      default:
        return l10n.attrTierWorthVisit;
    }
  }

  String _importanceLabel(AppLocalizations l10n, Attraction a) {
    switch (a.importanceKey) {
      case 'world_icon':
        return l10n.attrImpWorldIcon;
      case 'international':
        return l10n.attrImpInternational;
      case 'national':
        return l10n.attrImpNational;
      case 'regional':
        return l10n.attrImpRegional;
      default:
        return l10n.attrImpLocal;
    }
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
      );

  Widget _body(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13.5, height: 1.45)),
      );

  Widget _factRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          SizedBox(
            width: 116,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12.5)),
          ),
        ]),
      );

  /// "Why visit" facet bar — turns the importance scores into something visual.
  Widget _facet(String label, int? value) {
    if (value == null || value <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 112,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: AppColors.backgroundInput,
              valueColor: const AlwaysStoppedAnimation(AppColors.richGold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 26,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _bullets(List<String> items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(color: AppColors.richGold)),
                          Expanded(
                            child: Text(h,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ]),
                  ))
              .toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = _a;
    if (a == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(backgroundColor: AppColors.deepBlack),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator(color: AppColors.richGold)
              : Text(l10n.attrLoadFailed,
                  style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final price = a.freeEntry
        ? l10n.attrFree
        : (a.ticketPrice != null && a.ticketPrice! > 0
            ? '${a.currency ?? ''} ${a.ticketPrice!.toStringAsFixed(0)}'
            : null);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.deepBlack,
          actions: [
            TextButton.icon(
              onPressed: _translating
                  ? null
                  : () => _toggleTranslate(
                      a, Localizations.localeOf(context).languageCode),
              icon: _translating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.richGold))
                  : Icon(_translated ? Icons.undo : Icons.translate,
                      size: 17, color: AppColors.richGold),
              label: Text(
                _translated ? l10n.attrShowOriginal : l10n.attrTranslate,
                style: const TextStyle(
                    color: AppColors.richGold, fontSize: 12.5),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Semantics(
                label: a.altText ?? a.name,
                child: CachedNetworkImage(
                  imageUrl: a.imageUrl('hero', bucket: widget.bucket),
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.backgroundInput),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.backgroundInput),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0A0A0A)],
                  ),
                ),
              ),
            ]),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            // ---- title block ------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(a.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AttractionIcons.tierColor(a.scoreTier),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(children: [
                        Text('${a.greengoScore}',
                            style: const TextStyle(
                                color: AppColors.deepBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(l10n.attrScoreLabel,
                            style: const TextStyle(
                                color: AppColors.deepBlack, fontSize: 7)),
                      ]),
                    ),
                  ]),
                  if (a.officialName != null && a.officialName != a.name)
                    Text(a.officialName!,
                        style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _chip(AttractionIcons.category(a.categoryIcon),
                        CategoryLabels.of(l10n, a.category)),
                    _chip(AttractionIcons.importance(a.importanceIcon),
                        _importanceLabel(l10n, a),
                        color: AttractionIcons.importanceColor(a.importanceKey)),
                    _chip(Icons.emoji_events, _tierLabel(l10n, a.scoreTier),
                        color: AttractionIcons.tierColor(a.scoreTier)),
                    if (a.unesco) _chip(Icons.verified, l10n.attrUnesco),
                    if (a.mustVisit) _chip(Icons.push_pin, l10n.attrMustVisit),
                    if (a.top10Country) _chip(Icons.looks_one, l10n.attrTop10),
                    if ((a.photographyScore ?? 0) >= 80)
                      _chip(Icons.photo_camera, l10n.attrPhotoSpot),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.place, size: 15, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          [a.cityName, a.countryName]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    if (a.googleRating != null) ...[
                      const Icon(Icons.star, size: 15, color: AppColors.richGold),
                      const SizedBox(width: 2),
                      Text('${a.googleRating}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ]),
                ],
              ),
            ),

            if (a.needsAttribution)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                    l10n.attrPhotoBy(
                        a.attributionAuthor!, a.attributionLicense ?? ''),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 10)),
              ),

            // ---- about ------------------------------------------------------
            if (a.descriptionMedium != null || a.descriptionShort != null) ...[
              _sectionTitle(l10n.attrAbout),
              _body(_t(a.descriptionMedium ?? a.descriptionShort)),
            ],

            if (a.topHighlights.isNotEmpty) ...[
              _sectionTitle(l10n.attrHighlights),
              _bullets(_tList(a.topHighlights)),
            ],

            // ---- why visit --------------------------------------------------
            if ((a.historicalScore ?? 0) > 0 ||
                (a.architecturalScore ?? 0) > 0 ||
                (a.naturalScore ?? 0) > 0 ||
                (a.photographyScore ?? 0) > 0) ...[
              _sectionTitle(l10n.attrWhyVisit),
              _facet(l10n.attrScoreHistorical, a.historicalScore),
              _facet(l10n.attrScoreArchitectural, a.architecturalScore),
              _facet(l10n.attrScoreNatural, a.naturalScore),
              _facet(l10n.attrScorePhotography, a.photographyScore),
            ],

            // ---- best time --------------------------------------------------
            if (a.bestSeason != null || a.bestTimeOfDay != null) ...[
              _sectionTitle(l10n.attrBestTimeTitle),
              if (a.bestSeason != null)
                _factRow(Icons.wb_sunny, l10n.attrBestTimeTitle, _t(a.bestSeason)),
              if (a.bestTimeOfDay != null)
                _factRow(Icons.schedule, l10n.attrVisitDuration, _t(a.bestTimeOfDay)),
            ],

            if (a.historySummary != null) ...[
              _sectionTitle(l10n.attrHistoryTitle),
              _body(_t(a.historySummary)),
            ],
            if (a.interestingFacts.isNotEmpty) ...[
              _sectionTitle(l10n.attrDidYouKnow),
              _bullets(_tList(a.interestingFacts)),
            ],
            if (a.photographyTips != null) ...[
              _sectionTitle(l10n.attrPhotoTips),
              _body(_t(a.photographyTips)),
            ],

            // ---- practical --------------------------------------------------
            _sectionTitle(l10n.attrPractical),
            if (a.openingHours != null)
              _factRow(Icons.access_time, l10n.attrOpeningHours, _t(a.openingHours)),
            if (a.visitDuration != null)
              _factRow(Icons.timelapse, l10n.attrVisitDuration, _t(a.visitDuration)),
            if (price != null)
              _factRow(Icons.confirmation_number, l10n.attrTicketFrom, price),
            if (a.wheelchairAccessible != null)
              _factRow(Icons.accessible, l10n.attrAccessibility,
                  a.wheelchairAccessible!),
            if (a.indoorOutdoor != null)
              _factRow(Icons.home_work, l10n.attrAccessibility, a.indoorOutdoor!),
            if (a.petFriendly != null)
              _factRow(Icons.pets, l10n.attrPets, a.petFriendly!),
            if (a.safetyLevel != null)
              _factRow(Icons.shield_outlined, l10n.attrSafety, a.safetyLevel!),
            if (a.annualVisitors != null)
              _factRow(Icons.groups, l10n.attrVisitorsPerYear, a.annualVisitors!),
            if (a.streetAddress != null)
              _factRow(Icons.location_on, l10n.attrOpenInMaps, a.streetAddress!),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMaps(a),
                  icon: const Icon(Icons.map, size: 18),
                  label: Text(l10n.attrOpenInMaps),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = AppColors.richGold}) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11.5)),
      ]),
    );
  }
}
