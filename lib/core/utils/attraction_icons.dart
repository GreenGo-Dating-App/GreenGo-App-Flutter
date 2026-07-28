import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Maps the icon keys stored in Firestore (`attraction_taxonomy.icon`,
/// `attractions.categoryIcon` / `.importanceIcon`) to concrete [IconData].
///
/// The keys are DATA, not code — a new category added in Firestore renders with
/// [fallbackCategoryIcon] until a matching key is added here, so content can be
/// extended without shipping an app release.
class AttractionIcons {
  const AttractionIcons._();

  static const IconData fallbackCategoryIcon = Icons.place;

  // One category -> one icon (26 dataset categories).
  static const Map<String, IconData> _category = {
    // TODO(design): `temple` is a placeholder. The dataset's "Religious"
    // category spans churches, mosques, temples and synagogues across 50
    // countries, and Material has no faith-neutral glyph. Replace with a custom
    // neutral asset when design supplies one.
    'temple': Icons.account_balance,
    'history_edu': Icons.history_edu,
    'museum': Icons.museum,
    'forest': Icons.forest,
    'holiday_village': Icons.holiday_village,
    'beach_access': Icons.beach_access,
    'local_florist': Icons.local_florist,
    'account_balance': Icons.account_balance,
    'location_city': Icons.location_city,
    'signpost': Icons.signpost,
    'apartment': Icons.apartment,
    'visibility': Icons.visibility,
    'castle': Icons.castle,
    'storefront': Icons.storefront,
    'terrain': Icons.terrain,
    'villa': Icons.villa,
    'water': Icons.water,
    'water_drop': Icons.water_drop,
    'park': Icons.park,
    'place': Icons.place,
    // No Material glyph for a bridge; `architecture` reads closest.
    'bridge': Icons.architecture,
    'attractions': Icons.attractions,
    'waves': Icons.waves,
    'pets': Icons.pets,
    'shopping_bag': Icons.shopping_bag,
    // No Material glyph for an aquarium.
    'aquarium': Icons.scuba_diving,
  };

  // ImportanceLevel ladder — 5 tiers, gold at the top.
  static const Map<String, IconData> _importance = {
    'public': Icons.public,
    'travel_explore': Icons.travel_explore,
    'flag': Icons.flag,
    'map': Icons.map,
    'place': Icons.place,
  };

  static const Map<String, Color> _importanceColor = {
    'world_icon': AppColors.richGold,
    'international': Color(0xFFE8B84B),
    'national': Color(0xFF4DB6AC),
    'regional': Color(0xFF90A4AE),
    'local': AppColors.textTertiary,
  };

  /// GreenGo Score tier -> colour. Same ramp as the importance ladder so the
  /// two badges read as one system.
  static const Map<String, Color> _tierColor = {
    'iconic': AppColors.richGold,
    'exceptional': Color(0xFFE8B84B),
    'excellent': Color(0xFF4DB6AC),
    'great': Color(0xFF90A4AE),
    'worth_visit': AppColors.textTertiary,
  };

  static IconData category(String? key) =>
      _category[key] ?? fallbackCategoryIcon;

  static IconData importance(String? iconKey) =>
      _importance[iconKey] ?? Icons.place;

  static Color importanceColor(String? importanceKey) =>
      _importanceColor[importanceKey] ?? AppColors.textTertiary;

  static Color tierColor(String? tierKey) =>
      _tierColor[tierKey] ?? AppColors.textTertiary;
}
