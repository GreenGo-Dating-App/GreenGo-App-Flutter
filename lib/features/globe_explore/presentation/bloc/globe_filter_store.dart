import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/globe_user.dart';

/// Remembers the network map's filter chips on this device
/// (SharedPreferences, like the app's other per-device view settings).
/// Never throws: an unreadable / unwritable store means "all on".
class GlobeFilterStore {
  const GlobeFilterStore();

  static const String prefsKey = 'globe_network_filters_v1';

  Future<Set<GlobeNetworkFilter>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(prefsKey);
      if (saved == null) return kAllGlobeFilters;
      return {
        for (final f in GlobeNetworkFilter.values)
          if (saved.contains(f.name)) f,
      };
    } catch (_) {
      return kAllGlobeFilters;
    }
  }

  Future<void> save(Set<GlobeNetworkFilter> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          prefsKey, [for (final f in filters) f.name]);
    } catch (_) {/* best effort */}
  }
}
