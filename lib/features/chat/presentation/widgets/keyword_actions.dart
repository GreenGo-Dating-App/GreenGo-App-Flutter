import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../core/services/chat_datasets/keyword_matcher.dart';
import '../../../../generated/app_localizations.dart';
import '../../../attractions/data/datasources/attractions_datasource.dart';
import '../../../attractions/domain/entities/attraction.dart';
import '../../../attractions/presentation/screens/attraction_detail_screen.dart';
import 'attraction_message.dart';

/// What happens when a highlighted keyword in a chat message is tapped.
class KeywordActions {
  KeywordActions._();

  static Future<void> open(BuildContext context, KeywordMatch m) async {
    switch (m.kind) {
      case KeywordKind.attraction:
        if (m.refs.length == 1) {
          await _openAttraction(context, int.tryParse(m.refs.single));
        } else {
          await _chooseAttraction(context, m.refs);
        }
      case KeywordKind.city:
        final ref = m.refs.first.split(':');
        if (ref.length != 2) return;
        final name = ChatDatasets.instance.keywords?.cities[m.refs.first] ?? ref[1];
        if (!context.mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CityAttractionsScreen(iso2: ref[0], citySlug: ref[1], cityName: name),
        ));
      case KeywordKind.country:
        await CountryTipsSheet.show(context, m.refs.first);
    }
  }

  static Future<void> _openAttraction(BuildContext context, int? id) async {
    if (id == null) return;
    final bucket = await AttractionsDataSource().bucket();
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AttractionDetailScreen(attractionId: id, bucket: bucket),
    ));
  }

  /// Same words, several attractions (e.g. two "Cathedral of Our Lady").
  static Future<void> _chooseAttraction(BuildContext context, List<String> ids) async {
    final kw = ChatDatasets.instance.keywords;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(ctx)!.chatKeywordWhichOne,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            for (final id in ids)
              ListTile(
                leading: const Icon(Icons.place_outlined, color: AppColors.richGold),
                title: Text(kw?.attractions[id]?.elementAtOrNull(2) ?? id,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                    kw?.cities['${kw.attractions[id]?.first}:${kw.attractions[id]?.elementAtOrNull(1)}'] ?? '',
                    style: const TextStyle(color: AppColors.textTertiary)),
                onTap: () => Navigator.pop(ctx, id),
              ),
          ],
        ),
      ),
    );
    if (id != null && context.mounted) await _openAttraction(context, int.tryParse(id));
  }
}

/// The attractions of one city (from the cached country list), best first.
class CityAttractionsScreen extends StatefulWidget {
  const CityAttractionsScreen({
    required this.iso2,
    required this.citySlug,
    required this.cityName,
    super.key,
  });

  final String iso2;
  final String citySlug;
  final String cityName;

  @override
  State<CityAttractionsScreen> createState() => _CityAttractionsScreenState();
}

class _CityAttractionsScreenState extends State<CityAttractionsScreen> {
  final _ds = AttractionsDataSource();
  late final Future<(List<Attraction>, String)> _load = () async {
    final all = await _ds.forCountry(widget.iso2);
    final bucket = await _ds.bucket();
    final list = all.where((a) => a.citySlug == widget.citySlug).toList()
      ..sort((a, b) => b.greengoScore.compareTo(a.greengoScore));
    return (list, bucket);
  }();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l10n.chatCityAttractionsTitle(widget.cityName)),
        actions: [
          IconButton(
            tooltip: l10n.chatCountryTipsTitle(
                ChatDatasets.instance.keywords?.countries[widget.iso2] ?? widget.iso2),
            icon: const Icon(Icons.tips_and_updates_outlined, color: AppColors.richGold),
            onPressed: () => CountryTipsSheet.show(context, widget.iso2),
          ),
        ],
      ),
      body: FutureBuilder<(List<Attraction>, String)>(
        future: _load,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          }
          final (list, bucket) = snap.data!;
          if (list.isEmpty) {
            return Center(
              child: Text(l10n.attrNoResults, style: const TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = list[i];
              return Material(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AttractionDetailScreen(attractionId: a.id, fallback: a, bucket: bucket),
                  )),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 72,
                        child: CachedNetworkImage(
                          imageUrl: a.imageUrl('thumb', bucket: bucket),
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          placeholder: (_, __) => Container(color: AppColors.backgroundInput),
                          errorWidget: (_, __, ___) => Container(color: AppColors.backgroundInput),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.nameFor(locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Text('${a.greengoScore}',
                            style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
                      ),
                      // Send it into the chat this screen was opened from.
                      ValueListenableBuilder<Future<void> Function(Attraction, String)?>(
                        valueListenable: ChatAttractionShare.sender,
                        builder: (context, send, _) => send == null
                            ? const SizedBox(width: 8)
                            : IconButton(
                                key: ValueKey('city-attraction-send-${a.id}'),
                                tooltip: l10n.chatSendAttraction,
                                icon: const Icon(Icons.send_rounded, color: AppColors.richGold, size: 20),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await send(a, bucket);
                                  messenger.showSnackBar(SnackBar(content: Text(l10n.chatAttractionSent)));
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Cultural tips of one country (offline dataset), in the app language.
class CountryTipsSheet {
  CountryTipsSheet._();

  /// Category order of the chips and sections (tools/chat_datasets/jobs/TEXTS.md).
  static const List<String> categories = [
    'greetings',
    'conversation',
    'dining',
    'tipping',
    'gifts',
    'dress',
    'religion_sites',
    'gestures',
    'punctuality',
    'public_behavior',
    'transport',
    'language',
    'festivals',
    'family',
    'money',
    'photography',
    'nightlife',
    'nature',
    'safety',
    'local_pride',
  ];

  static Future<void> show(BuildContext context, String iso2) async {
    final ready = ChatDatasets.instance.ensure('tips');
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => CountryTipsView(iso2: iso2, ready: ready, scroll: scroll),
      ),
    );
  }

  static String label(AppLocalizations l10n, String category) => switch (category) {
        'greetings' => l10n.chatTipCatGreetings,
        'conversation' => l10n.chatTipCatConversation,
        'dining' => l10n.chatTipCatDining,
        'tipping' => l10n.chatTipCatTipping,
        'gifts' => l10n.chatTipCatGifts,
        'dress' => l10n.chatTipCatDress,
        'religion_sites' => l10n.chatTipCatReligionSites,
        'gestures' => l10n.chatTipCatGestures,
        'punctuality' => l10n.chatTipCatPunctuality,
        'public_behavior' => l10n.chatTipCatPublicBehavior,
        'transport' => l10n.chatTipCatTransport,
        'language' => l10n.chatTipCatLanguage,
        'festivals' => l10n.chatTipCatFestivals,
        'family' => l10n.chatTipCatFamily,
        'money' => l10n.chatTipCatMoney,
        'photography' => l10n.chatTipCatPhotography,
        'nightlife' => l10n.chatTipCatNightlife,
        'nature' => l10n.chatTipCatNature,
        'safety' => l10n.chatTipCatSafety,
        'local_pride' => l10n.chatTipCatLocalPride,
        _ => l10n.chatTipCatOther,
      };

  static IconData icon(String category) => switch (category) {
        'greetings' => Icons.waving_hand_outlined,
        'conversation' => Icons.forum_outlined,
        'dining' => Icons.restaurant_outlined,
        'tipping' => Icons.volunteer_activism_outlined,
        'money' => Icons.payments_outlined,
        'gifts' => Icons.card_giftcard_outlined,
        'dress' => Icons.checkroom_outlined,
        'religion_sites' => Icons.account_balance_outlined,
        'gestures' => Icons.back_hand_outlined,
        'punctuality' => Icons.schedule_outlined,
        'public_behavior' => Icons.groups_outlined,
        'transport' => Icons.directions_bus_outlined,
        'language' => Icons.translate,
        'festivals' => Icons.celebration_outlined,
        'family' => Icons.family_restroom_outlined,
        'photography' => Icons.photo_camera_outlined,
        'nightlife' => Icons.nightlife_outlined,
        'nature' => Icons.park_outlined,
        'safety' => Icons.health_and_safety_outlined,
        'local_pride' => Icons.star_outline,
        _ => Icons.lightbulb_outline,
      };
}

/// Cultural tips of one country: category chips on top ("All" + one per
/// category, with counts); "All" shows the tips grouped under category
/// headings, a chip shows that category only. Each tip is its own card.
class CountryTipsView extends StatefulWidget {
  const CountryTipsView({super.key, required this.iso2, required this.ready, this.scroll});

  final String iso2;
  final Future<void> ready;
  final ScrollController? scroll;

  @override
  State<CountryTipsView> createState() => _CountryTipsViewState();
}

class _CountryTipsViewState extends State<CountryTipsView> {
  String? _category; // null = all

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: widget.ready,
      builder: (context, snap) {
        final l10n = AppLocalizations.of(context)!;
        final lang = Localizations.localeOf(context).toLanguageTag();
        final datasets = ChatDatasets.instance;
        final country = datasets.keywords?.countries[widget.iso2] ?? widget.iso2;
        final tips = datasets.tips?[widget.iso2] ?? const <CulturalTip>[];

        // Tips by category, in the fixed category order (unknown ones last).
        final byCat = <String, List<CulturalTip>>{};
        for (final t in tips) {
          (byCat[t.category] ??= []).add(t);
        }
        final cats = [
          ...CountryTipsSheet.categories.where(byCat.containsKey),
          ...byCat.keys.where((c) => !CountryTipsSheet.categories.contains(c)),
        ];
        final selected = _category != null && byCat.containsKey(_category) ? _category : null;

        final body = <Widget>[];
        if (snap.connectionState != ConnectionState.done && tips.isEmpty) {
          body.add(const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
          ));
        } else if (tips.isEmpty) {
          body.add(Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.chatCountryTipsEmpty, style: const TextStyle(color: AppColors.textSecondary)),
          ));
        } else {
          for (final c in selected == null ? cats : [selected]) {
            if (selected == null) body.add(_sectionHeader(l10n, c));
            for (final t in byCat[c]!) {
              body.add(_tipCard(t.text.of(lang)));
            }
          }
        }

        return CustomScrollView(
          controller: widget.scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.chatCountryTipsTitle(country),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            if (cats.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChipsHeader(
                  child: Container(
                    color: AppColors.backgroundCard,
                    height: 56,
                    child: ListView(
                      key: const ValueKey('tips-category-chips'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        _chip(l10n.filterAll, Icons.apps, tips.length, selected == null,
                            () => setState(() => _category = null)),
                        for (final c in cats)
                          _chip(CountryTipsSheet.label(l10n, c), CountryTipsSheet.icon(c), byCat[c]!.length,
                              selected == c, () => setState(() => _category = c)),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(delegate: SliverChildListDelegate(body)),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, IconData icon, int count, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          avatar: Icon(icon, size: 16, color: selected ? Colors.black : AppColors.richGold),
          label: Text('$label  $count'),
          labelStyle: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          selectedColor: AppColors.richGold,
          backgroundColor: AppColors.charcoal,
          side: BorderSide(color: selected ? AppColors.richGold : AppColors.textTertiary.withValues(alpha: 0.4)),
        ),
      );

  Widget _sectionHeader(AppLocalizations l10n, String c) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(
          children: [
            Icon(CountryTipsSheet.icon(c), size: 18, color: AppColors.richGold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(CountryTipsSheet.label(l10n, c).toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.richGold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ),
          ],
        ),
      );

  Widget _tipCard(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: AppColors.richGold.withValues(alpha: 0.7), width: 3)),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.45)),
      );
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  _ChipsHeader({required this.child});
  final Widget child;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_ChipsHeader oldDelegate) => oldDelegate.child != child;
}
