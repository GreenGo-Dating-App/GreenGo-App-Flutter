import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_controller.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_keys.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/tours_replay_section.dart';

/// Owner notes 2026-10-20:
///  * the Explore tour starts with the 4 stats tiles (coins, membership,
///    countries, followers), one step each, then the existing steps;
///  * the world map shows no tour, hint or empty-state text.
void main() {
  test('Explore tour: 4 stats tiles first, then search and My Space', () {
    expect(TourKeys.exploreTour, [
      TourKeys.exploreStatCoins,
      TourKeys.exploreStatMembership,
      TourKeys.exploreStatCountries,
      TourKeys.exploreStatFollowers,
      TourKeys.exploreSearch,
      TourKeys.exploreQr,
    ]);
    final src = File('lib/features/explore/presentation/screens/explore_screen.dart')
        .readAsStringSync();
    expect(src, contains('keys: TourKeys.exploreTour'));
    for (final k in [
      'TourKeys.exploreStatCoins',
      'TourKeys.exploreStatMembership',
      'TourKeys.exploreStatCountries',
      'TourKeys.exploreStatFollowers',
    ]) {
      expect(src, contains(k), reason: '$k is anchored on its tile');
    }
  });

  test('world map: no tour, no App Guide replay entry', () {
    expect(TourController.allTourIds, isNot(contains('world_map')));
    expect(tourEntries().map((e) => e.id), isNot(contains('world_map')));
  });

  test('world map screen: no tour anchors, hints or empty-state text', () {
    final src = File(
            'lib/features/globe_explore/presentation/screens/globe_screen.dart')
        .readAsStringSync();
    for (final banned in [
      'PageTourHost',
      'TourAnchor',
      'TourShowcase',
      'HelpfulEmptyState',
      'xplEmptyGlobe',
      'WhatsNew',
      'InfoButton',
    ]) {
      expect(src, isNot(contains(banned)), reason: banned);
    }
    expect(src, contains('GlobeFilterChips('), reason: 'filter chips stay');
  });
}
