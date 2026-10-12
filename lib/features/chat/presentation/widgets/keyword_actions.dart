import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../core/services/chat_datasets/keyword_matcher.dart';
import '../../../../generated/app_localizations.dart';
import '../../../attractions/data/datasources/attractions_datasource.dart';
import '../../../attractions/domain/entities/attraction.dart';
import '../../../attractions/presentation/screens/attraction_detail_screen.dart';

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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${a.greengoScore}',
                            style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
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

  static Future<void> show(BuildContext context, String iso2) async {
    final datasets = ChatDatasets.instance;
    final ready = datasets.ensure('tips');
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => FutureBuilder<void>(
          future: ready,
          builder: (ctx, snap) {
            final l10n = AppLocalizations.of(ctx)!;
            final lang = Localizations.localeOf(ctx).toLanguageTag();
            final country = datasets.keywords?.countries[iso2] ?? iso2;
            final tips = datasets.tips?[iso2] ?? const <CulturalTip>[];
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.chatCountryTipsTitle(country),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (snap.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator(color: AppColors.richGold))
                else if (tips.isEmpty)
                  Text(l10n.chatCountryTipsEmpty, style: const TextStyle(color: AppColors.textSecondary))
                else
                  for (final t in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_tipIcon(t.category), size: 18, color: AppColors.richGold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(t.text.of(lang),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _tipIcon(String category) => switch (category) {
        'greetings' => Icons.waving_hand_outlined,
        'conversation' => Icons.forum_outlined,
        'dining' => Icons.restaurant_outlined,
        'tipping' || 'money' => Icons.payments_outlined,
        'gifts' => Icons.card_giftcard_outlined,
        'dress' => Icons.checkroom_outlined,
        'religion_sites' => Icons.account_balance_outlined,
        'gestures' => Icons.back_hand_outlined,
        'punctuality' => Icons.schedule_outlined,
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
