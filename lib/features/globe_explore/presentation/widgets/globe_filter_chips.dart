import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart'
    show LocationMapColors;
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/globe_user.dart';
import 'globe_markers.dart';

/// The network map's filter chips (multi-select): Following, Followers,
/// Chats, Businesses. Scrolls horizontally on narrow screens.
class GlobeFilterChips extends StatelessWidget {
  const GlobeFilterChips({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<GlobeNetworkFilter> selected;
  final ValueChanged<GlobeNetworkFilter> onToggle;

  static String labelOf(AppLocalizations l10n, GlobeNetworkFilter f) =>
      switch (f) {
        GlobeNetworkFilter.following => l10n.globeFilterFollowing,
        GlobeNetworkFilter.followers => l10n.globeFilterFollowers,
        GlobeNetworkFilter.chats => l10n.globeFilterChats,
        GlobeNetworkFilter.businesses => l10n.globeFilterBusinesses,
      };

  static (IconData, Color) _iconOf(GlobeNetworkFilter f) => switch (f) {
        GlobeNetworkFilter.following => (
            globeRelationIcon(GlobeRelation.following),
            globeRelationColor(GlobeRelation.following)
          ),
        GlobeNetworkFilter.followers => (
            globeRelationIcon(GlobeRelation.follower),
            globeRelationColor(GlobeRelation.follower)
          ),
        GlobeNetworkFilter.chats => (
            globeRelationIcon(GlobeRelation.chatted),
            globeRelationColor(GlobeRelation.chatted)
          ),
        GlobeNetworkFilter.businesses => (Icons.storefront, kGlobeBusinessColor),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in GlobeNetworkFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                key: ValueKey('globe-filter-${f.name}'),
                selected: selected.contains(f),
                onSelected: (_) => onToggle(f),
                showCheckmark: false,
                avatar: Icon(_iconOf(f).$1,
                    size: 16,
                    color: selected.contains(f)
                        ? LocationMapColors.surface
                        : _iconOf(f).$2),
                label: Text(labelOf(l10n, f)),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected.contains(f)
                      ? LocationMapColors.surface
                      : LocationMapColors.text,
                ),
                selectedColor: _iconOf(f).$2,
                backgroundColor:
                    LocationMapColors.surface.withValues(alpha: 0.94),
                side: BorderSide(
                    color: selected.contains(f)
                        ? _iconOf(f).$2
                        : LocationMapColors.border),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}
