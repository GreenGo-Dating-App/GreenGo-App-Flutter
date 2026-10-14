import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/attractions_datasource.dart';
import '../../data/services/attraction_ratings_store.dart';
import '../../data/services/attraction_stats_service.dart';
import '../../domain/attraction_rating.dart';
import '../../domain/category_labels.dart';
import '../../domain/entities/attraction.dart';
import '../../../chat/presentation/widgets/keyword_actions.dart' show CountryTipsSheet;
import '../../../user_experiences/presentation/widgets/experience_widgets.dart'
    show StarRatingDisplay, StarRatingInput;

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

  /// Unique viewer-days (server-counted); null until loaded.
  int? _views;

  /// viewCount of the FIRST stats snapshot, and whether this open recorded a
  /// brand-new view (shown immediately as +1, before the trigger catches up).
  int? _firstViews;
  bool _newView = false;

  final AttractionStatsService _stats = AttractionStatsService();
  StreamSubscription<Map<String, dynamic>?>? _statsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _mineSub;

  // ---- GreenGo users' rating ----------------------------------------------
  /// Server aggregate (attraction_stats), null until the first snapshot.
  AttractionRatingSummary? _server;
  Timestamp? _serverRatingAt;

  /// The user's own rating as confirmed by the server (null = not rated).
  int? _myStars;
  bool _myDocExists = false;
  Timestamp? _myUpdatedAt;
  bool _mineLoaded = false;
  bool _signedIn = false;

  /// Optimistic overlay while a change of the user's rating is in flight or
  /// not yet reflected by the server aggregate.
  _PendingRating? _pending;
  int _pendingSeq = 0;
  Timer? _pendingTimer;

  /// A written rating the aggregate has not picked up within this long is
  /// dropped in favour of the server value.
  static const Duration _reconcileTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _a = widget.fallback;
    _load();
    _watchStats();
    _watchMine();
    _recordView();
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _mineSub?.cancel();
    _pendingTimer?.cancel();
    super.dispose();
  }

  /// ONE live listener on attraction_stats/{id} while the page is open: view
  /// count + rating aggregate, so the user's own rating reconciles as soon as
  /// the aggregate trigger has run.
  void _watchStats() {
    _statsSub = _stats.watchStats(widget.attractionId).listen((m) {
      if (!mounted) return;
      final views = (m?['viewCount'] as num?)?.toInt() ?? 0;
      final at = m?['ratingUpdatedAt'];
      setState(() {
        _firstViews ??= views;
        _views = views < 0 ? 0 : views;
        _server = AttractionRatingSummary.fromStats(m);
        _serverRatingAt = at is Timestamp ? at : null;
      });
      _reconcile();
    });
  }

  void _watchMine() {
    final stream = _stats.watchMyRating(widget.attractionId);
    _signedIn = stream != null;
    _mineSub = stream?.listen((snap) {
      if (!mounted) return;
      final d = snap.data();
      final stars = (d?['stars'] as num?)?.toInt();
      final at = d?['updatedAt'];
      setState(() {
        _mineLoaded = true;
        _myDocExists = snap.exists;
        // Local (pending) snapshots carry no server time yet.
        if (!snap.metadata.hasPendingWrites) {
          _myStars = snap.exists ? stars : null;
          _myUpdatedAt = at is Timestamp ? at : null;
        }
      });
      _reconcile();
    });
  }

  /// Record this view (one create per user/day).
  Future<void> _recordView() async {
    final isNew = await _stats.recordView(widget.attractionId);
    if (isNew && mounted) setState(() => _newView = true);
  }

  int? get _shownViews {
    final v = _views;
    if (v == null) return null;
    final floor = _newView ? (_firstViews ?? 0) + 1 : 0;
    return v > floor ? v : floor;
  }

  /// The aggregate to show: optimistic overlay > live server value > memo.
  AttractionRatingSummary? get _shownRating =>
      _pending?.summary ??
      _server ??
      AttractionRatingsStore.instance.peek(widget.attractionId);

  /// The user's stars to show (0 = not rated).
  int get _shownMyStars =>
      (_pending != null ? _pending!.stars : _myStars) ?? 0;

  /// Drops the optimistic overlay once the server aggregate reflects it: the
  /// aggregate equals the expected value, or was updated after the user's
  /// (server-confirmed) write. Otherwise mirrors the server value into the
  /// cards' memo.
  void _reconcile() {
    final p = _pending;
    final server = _server;
    if (p != null && p.acked && server != null) {
      final mine = _myUpdatedAt;
      final sa = _serverRatingAt;
      final caughtUp = server == p.summary ||
          (p.stars != null &&
              mine != null &&
              sa != null &&
              _myStars == p.stars &&
              sa.compareTo(mine) >= 0);
      if (caughtUp) _clearPending();
    }
    if (_pending == null && server != null) {
      AttractionRatingsStore.instance.put(widget.attractionId, server);
    }
  }

  void _clearPending() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    if (!mounted) {
      _pending = null;
      return;
    }
    setState(() => _pending = null);
    final server = _server;
    if (server != null) {
      AttractionRatingsStore.instance.put(widget.attractionId, server);
    }
  }

  /// Set ([stars] 1..5) or remove ([stars] null) the user's rating, shown
  /// immediately and reconciled with the server aggregate afterwards.
  Future<void> _rate(int? stars) async {
    if (!_mineLoaded) return;
    final old = _pending != null ? _pending!.stars : _myStars;
    if (stars == old) return;
    final base = _shownRating ?? AttractionRatingSummary.empty;
    final optimistic = base.withUserChange(old, stars);
    final seq = ++_pendingSeq;
    _pendingTimer?.cancel();
    setState(() => _pending = _PendingRating(optimistic, stars));
    AttractionRatingsStore.instance.put(widget.attractionId, optimistic);
    try {
      if (stars == null) {
        await _stats.removeRating(widget.attractionId);
      } else {
        await _stats.rate(widget.attractionId, stars, existed: _myDocExists);
      }
      if (!mounted || seq != _pendingSeq) return;
      _pending = _pending?.ackedCopy();
      _pendingTimer = Timer(_reconcileTimeout, () {
        if (seq == _pendingSeq) _clearPending();
      });
      _reconcile();
    } catch (_) {
      if (!mounted || seq != _pendingSeq) return;
      _clearPending();
      showUserErrorMessage(
          context, AppLocalizations.of(context)!.attrRatingFailed);
    }
  }

  Future<void> _load() async {
    final full = await AttractionsDataSource().byId(widget.attractionId);
    if (!mounted) return;
    setState(() {
      if (full != null) _a = full;
      _loading = false;
    });
  }

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

  /// "Source: Wikipedia (CC BY-SA 4.0)" under the about text; opens the article.
  Widget _aboutSource(AppLocalizations l10n, String? url, {bool translated = false}) {
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: InkWell(
        key: const ValueKey('attraction-about-source'),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            translated ? l10n.attrAboutSourceTranslated : l10n.attrAboutSource,
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 11, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }

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

  /// Numbered list (1-5) for the top curiosities.
  Widget _numbered(List<String> items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.richGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppColors.deepBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: Text(items[i],
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  /// Full-screen photo viewer: pinch/double-tap zoom, tap or X to close.
  void _openImage(BuildContext context, Attraction a) {
    final url = a.imageUrl('hero', bucket: widget.bucket);
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (ctx, _, __) => _AttractionImageViewer(
        url: url,
        heroTag: 'attraction-image-${a.id}',
        semanticLabel: a.textsFor(Localizations.localeOf(context)).altText ??
            a.nameFor(Localizations.localeOf(context)),
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

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

    // Every catalogue text is stored in all app languages (attractions/{id}.i18n):
    // a language switch only rebuilds, nothing is translated at runtime.
    final locale = Localizations.localeOf(context);
    final tx = a.textsFor(locale);
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
            // Cultural tips of the attraction's country: the same sheet as the
            // "<country>: cultural tips" chip in chats.
            IconButton(
              key: const ValueKey('attractionTipsButton'),
              tooltip: l10n.chatTipsFor(localizedCountryName(l10n, a.countryIso2)),
              icon: const Icon(Icons.lightbulb_outline, color: AppColors.richGold, size: 20),
              onPressed: () => CountryTipsSheet.show(context, a.countryIso2),
            ),
            // Share the attraction's link (/a/{id}): unfurls into a preview
            // card (photo when its licence allows, name, place, category).
            Builder(
              builder: (buttonContext) => IconButton(
                key: const ValueKey('attractionShareButton'),
                tooltip: l10n.attrShare,
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.richGold, size: 20),
                onPressed: () =>
                    shareAttractionLink(buttonContext, a.id,
                        name: a.nameFor(Localizations.localeOf(buttonContext))),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              // Tap the photo to open it full screen (pinch to zoom).
              Semantics(
                label: tx.altText ?? a.nameFor(locale),
                button: true,
                child: GestureDetector(
                  onTap: () => _openImage(context, a),
                  child: Hero(
                    tag: 'attraction-image-${a.id}',
                    child: CachedNetworkImage(
                      imageUrl: a.imageUrl('hero', bucket: widget.bucket),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.backgroundInput,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.richGold),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.backgroundInput),
                    ),
                  ),
                ),
              ),
              // Legibility scrim; must not swallow the tap on the photo.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0A0A0A)],
                    ),
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
                      child: Text(a.nameFor(Localizations.localeOf(context)),
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
                          [
                            a.cityFor(locale),
                            if (a.countryName != null)
                              localizedCountryName(l10n, a.countryName!),
                          ]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    if ((_shownViews ?? 0) > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.visibility_outlined,
                          size: 15, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                          l10n.attractionViewsCount(
                              _shownViews!,
                              formatCompactCount(_shownViews!,
                                  locale: Localizations.localeOf(context)
                                      .toString())),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ]),
                ],
              ),
            ),

            _ratingBlock(l10n),

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
            if (a.about.isNotEmpty) ...[
              _sectionTitle(l10n.attrAbout),
              _body(a.aboutIn(locale) ?? a.aboutAny ?? ''),
              _aboutSource(l10n, a.aboutSourceIn(locale),
                  translated: a.aboutIsTranslated(locale)),
            ] else if (tx.descriptionMedium != null || tx.descriptionShort != null) ...[
              _sectionTitle(l10n.attrAbout),
              _body(tx.descriptionMedium ?? tx.descriptionShort!),
            ],

            if (tx.curiosities.isNotEmpty) ...[
              _sectionTitle(l10n.attrTopCuriosities),
              _numbered(tx.curiosities),
            ],

            if (tx.topHighlights.isNotEmpty) ...[
              _sectionTitle(l10n.attrHighlights),
              _bullets(tx.topHighlights),
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
            if (tx.bestSeason != null || tx.bestTimeOfDay != null) ...[
              _sectionTitle(l10n.attrBestTimeTitle),
              if (tx.bestSeason != null)
                _factRow(Icons.wb_sunny, l10n.attrBestTimeTitle, tx.bestSeason!),
              if (tx.bestTimeOfDay != null)
                _factRow(Icons.schedule, l10n.attrVisitDuration, tx.bestTimeOfDay!),
            ],

            if (tx.historySummary != null) ...[
              _sectionTitle(l10n.attrHistoryTitle),
              _body(tx.historySummary!),
            ],
            if (tx.interestingFacts.isNotEmpty && tx.curiosities.isEmpty) ...[
              _sectionTitle(l10n.attrDidYouKnow),
              _bullets(tx.interestingFacts),
            ],
            if (tx.photographyTips != null) ...[
              _sectionTitle(l10n.attrPhotoTips),
              _body(tx.photographyTips!),
            ],

            // ---- practical --------------------------------------------------
            _sectionTitle(l10n.attrPractical),
            if (tx.openingHours != null)
              _factRow(Icons.access_time, l10n.attrOpeningHours, tx.openingHours!),
            if (tx.visitDuration != null)
              _factRow(Icons.timelapse, l10n.attrVisitDuration, tx.visitDuration!),
            if (price != null)
              _factRow(Icons.confirmation_number, l10n.attrTicketFrom, price),
            if (tx.wheelchairAccessible != null)
              _factRow(Icons.accessible, l10n.attrAccessibility,
                  tx.wheelchairAccessible!),
            if (tx.indoorOutdoor != null)
              _factRow(Icons.home_work, l10n.attrAccessibility, tx.indoorOutdoor!),
            if (tx.petFriendly != null)
              _factRow(Icons.pets, l10n.attrPets, tx.petFriendly!),
            if (tx.safetyLevel != null)
              _factRow(Icons.shield_outlined, l10n.attrSafety, tx.safetyLevel!),
            if (tx.annualVisitors != null)
              _factRow(Icons.groups, l10n.attrVisitorsPerYear, tx.annualVisitors!),
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

  /// GreenGo users' rating (stars + "4.6 · 23 ratings" / "No ratings yet")
  /// and the "Rate this attraction" stars with the user's current rating.
  Widget _ratingBlock(AppLocalizations l10n) {
    final r = _shownRating;
    final has = r != null && r.hasRatings;
    final mine = _shownMyStars;
    return Padding(
      key: const ValueKey('attrRatingBlock'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Text(l10n.attrRatingGreengoLabel,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
                if (has) ...[
                  StarRatingDisplay(rating: r.average, size: 15),
                  Text(
                    '${r.average.toStringAsFixed(1)} · '
                    '${l10n.attrRatingsCount(r.count)}',
                    key: const ValueKey('attrGreengoRating'),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ] else
                  Text(l10n.attrNoRatingsYet,
                      key: const ValueKey('attrNoRatings'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            if (_signedIn) ...[
              const SizedBox(height: 8),
              Text(mine > 0 ? l10n.attrYourRating : l10n.attrRateThis,
                  style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6)),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StarRatingInput(
                    key: const ValueKey('attrRateStars'),
                    value: mine,
                    size: 30,
                    onChanged: (v) => _rate(v),
                  ),
                  if (mine > 0)
                    TextButton(
                      onPressed: () => _rate(null),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                          visualDensity: VisualDensity.compact),
                      child: Text(l10n.attrRatingRemove,
                          style: const TextStyle(fontSize: 11.5)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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

class _AttractionImageViewer extends StatelessWidget {
  const _AttractionImageViewer({
    required this.url,
    required this.heroTag,
    required this.semanticLabel,
  });

  final String url;
  final String heroTag;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.richGold),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textTertiary,
                        size: 48),
                    imageBuilder: (_, provider) => Image(
                      image: provider,
                      fit: BoxFit.contain,
                      semanticLabel: semanticLabel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ]),
    );
  }
}

/// The user's not-yet-reconciled rating change.
class _PendingRating {
  const _PendingRating(this.summary, this.stars, {this.acked = false});

  /// Aggregate expected once the server has applied the change.
  final AttractionRatingSummary summary;

  /// The user's new stars (null = removed).
  final int? stars;

  /// True once the write itself succeeded.
  final bool acked;

  _PendingRating ackedCopy() => _PendingRating(summary, stars, acked: true);
}
