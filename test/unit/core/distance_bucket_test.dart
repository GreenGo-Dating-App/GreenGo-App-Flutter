import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/distance_bucket.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('distanceUpperLimitFor (owner scale: 2,5,10,30,50,100,200,500,1000,2000,5000,5000+)', () {
    test('maps each distance to the first step above it', () {
      expect(distanceUpperLimitFor(0), 2);
      expect(distanceUpperLimitFor(1.99), 2);
      expect(distanceUpperLimitFor(2), 5);
      expect(distanceUpperLimitFor(9.99), 10);
      expect(distanceUpperLimitFor(10), 30);
      expect(distanceUpperLimitFor(29.9), 30);
      expect(distanceUpperLimitFor(30), 50);
      expect(distanceUpperLimitFor(99), 100);
      expect(distanceUpperLimitFor(199), 200);
      expect(distanceUpperLimitFor(499), 500);
      expect(distanceUpperLimitFor(999), 1000);
      expect(distanceUpperLimitFor(1999), 2000);
      expect(distanceUpperLimitFor(4999), 5000);
    });
    test('beyond 5000 km is the open-ended bucket (0)', () {
      expect(distanceUpperLimitFor(5000), 0);
      expect(distanceUpperLimitFor(19000), 0);
    });
    test('unknown distances', () {
      expect(distanceUpperLimitFor(null), isNull);
      expect(distanceUpperLimitFor(double.nan), isNull);
      expect(distanceUpperLimitFor(-1), isNull);
      expect(distanceUpperLimitFor(double.infinity), isNull);
    });
  });

  group('distance filter steps', () {
    test('index <-> km round trip; last index = no limit', () {
      for (var i = 0; i < kDistanceStepsKm.length; i++) {
        expect(distanceFilterIndexFor(distanceFilterKmForIndex(i)), i);
      }
      expect(distanceFilterKmForIndex(kDistanceStepsKm.length), isNull);
      expect(distanceFilterIndexFor(null), kDistanceStepsKm.length);
    });
    test('old free-slider values snap UP (never narrower)', () {
      expect(distanceFilterKmForIndex(distanceFilterIndexFor(1)), 2);
      expect(distanceFilterKmForIndex(distanceFilterIndexFor(37)), 50);
      expect(distanceFilterKmForIndex(distanceFilterIndexFor(150)), 200);
      expect(distanceFilterKmForIndex(distanceFilterIndexFor(9000)), isNull);
    });
  });

  testWidgets('labels are localized "< N km" / "5,000+ km"', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) { l10n = AppLocalizations.of(c)!; return const SizedBox(); }),
    ));
    expect(distanceLabel(l10n, 0.5), '< 2 km');
    expect(distanceLabel(l10n, 0), '');
    expect(distanceLabel(l10n, 0, zeroIsUnknown: false), '< 2 km');
    expect(distanceLabel(l10n, 40), '< 50 km');
    expect(distanceLabel(l10n, 1500), '< 2,000 km');
    expect(distanceLabel(l10n, 8000), '5,000+ km');
    expect(distanceFilterLabel(l10n, null), '5,000+ km');
    expect(distanceFilterLabel(l10n, 37), '< 50 km');
  });

  group('precise distance (globeDiscoverability exact, ±100 m)', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));
    final it = lookupAppLocalizations(const Locale('it'));

    test('boundaries: 100 m resolution < 1 km, one decimal to 10 km, whole km after', () {
      expect(preciseDistanceLabel(en, 0.04), '100 m');
      expect(preciseDistanceLabel(en, 0.0), '100 m');
      expect(preciseDistanceLabel(en, 0.149), '100 m');
      expect(preciseDistanceLabel(en, 0.35), '400 m');
      expect(preciseDistanceLabel(en, 0.94), '900 m');
      expect(preciseDistanceLabel(en, 0.95), '1.0 km');
      expect(preciseDistanceLabel(en, 1.0), '1.0 km');
      expect(preciseDistanceLabel(en, 1.24), '1.2 km');
      expect(preciseDistanceLabel(en, 9.94), '9.9 km');
      expect(preciseDistanceLabel(en, 9.95), '10 km');
      expect(preciseDistanceLabel(en, 10.4), '10 km');
      expect(preciseDistanceLabel(en, 23.4), '23 km');
      expect(preciseDistanceLabel(en, 1234.4), '1,234 km');
    });

    test('unknown distances stay empty', () {
      expect(preciseDistanceLabel(en, null), '');
      expect(preciseDistanceLabel(en, double.nan), '');
      expect(preciseDistanceLabel(en, -1), '');
    });

    test('localized number formatting', () {
      expect(preciseDistanceLabel(de, 1.24), '1,2 km');
      expect(preciseDistanceLabel(it, 9.94), '9,9 km');
      expect(preciseDistanceLabel(de, 1234.4), '1.234 km');
      expect(preciseDistanceLabel(de, 0.35), '400 m');
    });

    test('distanceLabel: precise flag switches format; buckets unchanged otherwise', () {
      expect(distanceLabel(en, 0.35, precise: true), '400 m');
      expect(distanceLabel(en, 0.35), '< 2 km');
      expect(distanceLabel(en, 4.81, precise: true), '4.8 km');
      expect(distanceLabel(en, 4.81), '< 5 km');
      // 0 = "no location" for candidates, precise or not.
      expect(distanceLabel(en, 0, precise: true), '');
      expect(distanceLabel(en, 0, zeroIsUnknown: false, precise: true), '100 m');
    });
  });
}
