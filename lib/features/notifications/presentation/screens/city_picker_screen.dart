import 'package:flutter/material.dart';

import '../../../../core/services/place_search_service.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../../../generated/app_localizations.dart';

/// Full-screen city picker for event-alert subscriptions: the shared
/// [LocationPickerScreen] in city mode (city-only suggestions, tap or drag the
/// pin, current location). Pops the chosen city name.
///
/// Same flutter_map + CARTO basemap on every platform: the previous native
/// Google Map rendered blank on Android builds without a Maps SDK key.
class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key, this.repository});

  /// Defaults to [PlaceSearchRepository.instance].
  final PlaceSearchRepository? repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LocationPickerScreen(
      mode: PlaceSearchMode.city,
      title: l10n.cityPickerTitle,
      searchHint: l10n.cityPickerSearchHint,
      confirmLabel: l10n.cityPickerUseCity,
      repository: repository,
      onConfirm: (ctx, place) => Navigator.of(ctx).pop(place.city),
    );
  }
}
