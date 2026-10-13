import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_basemap.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../core/services/chat_datasets/keyword_matcher.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/widgets/interactive_location_map.dart' show MapAttribution, LocationMapColors;
import '../../../../core/widgets/map_basemap_layer.dart';
import '../../../../generated/app_localizations.dart';
import '../../../attractions/data/datasources/attractions_datasource.dart';
import '../../../attractions/domain/entities/attraction.dart';
import '../../domain/chat_places.dart';
import '../widgets/keyword_actions.dart';

/// Every place named in a chat as a list (attractions, cities, countries)
/// and on a map, with a share button. Offline data: message metadata + the
/// attractions catalogue (cache-first).
class ChatTripScreen extends StatefulWidget {
  const ChatTripScreen({super.key, required this.places, this.dataSource, this.onRemove});

  final List<ChatPlace> places;

  /// Removes a wrongly detected place (false positive) from the chat's
  /// message metadata; null hides the bin buttons.
  final Future<void> Function(ChatPlace place)? onRemove;

  /// Injectable for tests.
  final AttractionsDataSource? dataSource;

  @override
  State<ChatTripScreen> createState() => _ChatTripScreenState();
}

/// One row of the trip (a resolved place).
class _TripItem {
  _TripItem({required this.place, required this.title, this.subtitle, this.point, this.attraction});
  final ChatPlace place;
  final String title;
  final String? subtitle;
  final LatLng? point;
  final Attraction? attraction;
}

class _ChatTripScreenState extends State<ChatTripScreen> {
  late final AttractionsDataSource _ds = widget.dataSource ?? AttractionsDataSource();
  Future<List<_TripItem>>? _items;

  /// Places removed here (hidden at once; the chat metadata follows).
  final Set<String> _removed = {};
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_items == null || locale != _locale) {
      _locale = locale;
      _items = _resolve(AppLocalizations.of(context)!, locale);
    }
  }

  Future<List<_TripItem>> _resolve(AppLocalizations l10n, Locale locale) async {
    final kw = ChatDatasets.instance.keywords;
    final out = <_TripItem>[];
    final countryLists = <String, Future<List<Attraction>>>{};
    Future<List<Attraction>> country(String iso) => countryLists[iso] ??= _ds.forCountry(iso).catchError((Object _) => <Attraction>[]);

    for (final p in widget.places) {
      switch (p.kind) {
        case KeywordKind.attraction:
          final id = p.attractionIds.firstOrNull;
          final a = id == null ? null : await _ds.byId(id);
          out.add(_TripItem(
            place: p,
            title: a?.nameFor(locale) ?? p.label,
            subtitle: a == null ? null : '${a.cityName}, ${localizedCountryName(l10n, a.countryIso2)}',
            point: a?.lat != null && a?.lng != null ? LatLng(a!.lat!, a.lng!) : null,
            attraction: a,
          ));
        case KeywordKind.city:
          final ref = p.match.refs.first.split(':');
          LatLng? point;
          if (ref.length == 2) {
            final inCity = (await country(ref[0])).where((a) => a.citySlug == ref[1] && a.lat != null && a.lng != null).toList();
            if (inCity.isNotEmpty) {
              point = LatLng(
                inCity.map((a) => a.lat!).reduce((x, y) => x + y) / inCity.length,
                inCity.map((a) => a.lng!).reduce((x, y) => x + y) / inCity.length,
              );
            }
          }
          out.add(_TripItem(
            place: p,
            title: kw?.cities[p.match.refs.first] ?? p.label,
            subtitle: p.iso2 == null ? null : localizedCountryName(l10n, p.iso2!),
            point: point,
          ));
        case KeywordKind.country:
          out.add(_TripItem(place: p, title: localizedCountryName(l10n, p.match.refs.first)));
      }
    }
    return out;
  }

  Future<void> _remove(AppLocalizations l10n, ChatPlace place) async {
    setState(() => _removed.add(place.key));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onRemove?.call(place);
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatTripRemoved(place.label))));
    } catch (_) {
      if (mounted) setState(() => _removed.remove(place.key));
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatTripRemoveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(l10n.chatTripTitle),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: const Icon(Icons.list), text: l10n.chatTripList),
              Tab(icon: const Icon(Icons.map_outlined), text: l10n.chatTripMap),
            ],
          ),
        ),
        body: FutureBuilder<List<_TripItem>>(
          future: _items,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
            }
            final items = snap.data!.where((i) => !_removed.contains(i.place.key)).toList();
            if (items.isEmpty) {
              return _message(l10n.chatTripEmpty);
            }
            return TabBarView(
              physics: const NeverScrollableScrollPhysics(), // the map pans
              children: [_list(l10n, items), _map(l10n, items)],
            );
          },
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );

  Widget _list(AppLocalizations l10n, List<_TripItem> items) {
    final groups = <(String, KeywordKind)>[
      (l10n.chatTripAttractions, KeywordKind.attraction),
      (l10n.chatTripCities, KeywordKind.city),
      (l10n.chatTripCountries, KeywordKind.country),
    ];
    return ListView(
      key: const ValueKey('chat-trip-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final (title, kind) in groups)
          if (items.any((i) => i.place.kind == kind)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.richGold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ),
            for (final i in items.where((i) => i.place.kind == kind))
              Card(
                color: AppColors.charcoal,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Icon(
                    switch (kind) {
                      KeywordKind.attraction => Icons.place_outlined,
                      KeywordKind.city => Icons.location_city_outlined,
                      KeywordKind.country => Icons.public,
                    },
                    color: AppColors.richGold,
                  ),
                  title: Text(i.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: i.subtitle == null
                      ? null
                      : Text(i.subtitle!, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.onRemove != null)
                      IconButton(
                        key: ValueKey('chat-trip-remove-${i.place.key}'),
                        tooltip: l10n.chatTripRemove,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _remove(l10n, i.place),
                      ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ]),
                  onTap: () => KeywordActions.open(context, i.place.match),
                ),
              ),
          ],
      ],
    );
  }

  Widget _map(AppLocalizations l10n, List<_TripItem> items) {
    final pinned = items.where((i) => i.point != null).toList();
    if (pinned.isEmpty) return _message(l10n.chatTripNoMap);
    final points = [for (final i in pinned) i.point!];
    final fit = points.length == 1
        ? null
        : CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 14);
    return Stack(
      children: [
        FlutterMap(
          key: const ValueKey('chat-trip-map'),
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 12,
            initialCameraFit: fit,
            minZoom: 2,
            maxZoom: MapBasemap.lightMaxZoom,
            backgroundColor: LocationMapColors.background,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            const MapBasemapLayer.light(),
            MarkerLayer(markers: [
              for (final i in pinned)
                Marker(
                  point: i.point!,
                  width: 170,
                  height: 64,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => KeywordActions.open(context, i.place.match),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.richGold),
                          ),
                          child: Text(i.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5)),
                        ),
                        Icon(
                          i.place.kind == KeywordKind.city ? Icons.location_city : Icons.location_on,
                          color: AppColors.richGold,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
            ]),
          ],
        ),
        const Positioned(right: 4, bottom: 2, child: MapAttribution()),
      ],
    );
  }
}
