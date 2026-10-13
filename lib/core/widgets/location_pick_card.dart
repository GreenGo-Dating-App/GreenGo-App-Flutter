import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../generated/app_localizations.dart';
import '../config/map_basemap.dart';
import '../constants/app_colors.dart';
import 'interactive_location_map.dart' show InteractiveLocationMap, LocationMapColors;
import 'map_basemap_layer.dart';

/// The map picker inside a create / edit form (events, experiences): a map
/// preview with the chosen pin, or a "Choose on the map" area before one is
/// picked. Tapping it calls [onPick] (which opens LocationPickerScreen).
class LocationPickCard extends StatelessWidget {
  const LocationPickCard({super.key, this.lat, this.lng, required this.onPick, this.height = 160});

  final double? lat;
  final double? lng;
  final VoidCallback onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final picked = InteractiveLocationMap.validCoordinates(lat, lng);
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('location-pick-card'),
        onTap: onPick,
        child: SizedBox(
          height: height,
          child: picked
              ? Stack(children: [
                  // Static preview: taps go to the card (the picker), not the map.
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat!, lng!),
                        initialZoom: 15,
                        maxZoom: MapBasemap.lightMaxZoom,
                        backgroundColor: LocationMapColors.background,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        const MapBasemapLayer.light(),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(lat!, lng!),
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_on, color: AppColors.richGold, size: 40),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.richGold),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_location_alt_outlined, size: 16, color: AppColors.richGold),
                        const SizedBox(width: 6),
                        Text(l10n.locPickCardChange,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ])
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map_outlined, color: AppColors.richGold, size: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.locPickCardChoose,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
        ),
      ),
    );
  }
}
