import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/distance_bucket.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  group('distanceBucketFor', () {
    test('bucket edges are lower-inclusive, upper-exclusive', () {
      expect(distanceBucketFor(0), DistanceBucket.under2Km);
      expect(distanceBucketFor(0.3), DistanceBucket.under2Km);
      expect(distanceBucketFor(1.999), DistanceBucket.under2Km);
      expect(distanceBucketFor(2), DistanceBucket.from2To5Km);
      expect(distanceBucketFor(4.99), DistanceBucket.from2To5Km);
      expect(distanceBucketFor(5), DistanceBucket.from5To10Km);
      expect(distanceBucketFor(9.99), DistanceBucket.from5To10Km);
      expect(distanceBucketFor(10), DistanceBucket.from10To25Km);
      expect(distanceBucketFor(24.99), DistanceBucket.from10To25Km);
      expect(distanceBucketFor(25), DistanceBucket.over25Km);
      expect(distanceBucketFor(12000), DistanceBucket.over25Km);
    });

    test('unknown distances have no bucket', () {
      expect(distanceBucketFor(null), isNull);
      expect(distanceBucketFor(double.nan), isNull);
      expect(distanceBucketFor(double.infinity), isNull);
      expect(distanceBucketFor(-1), isNull);
    });
  });

  group('distanceLabel', () {
    final en = lookupAppLocalizations(const Locale('en'));

    test('English labels', () {
      expect(distanceLabel(en, 0.4), '< 2 km');
      expect(distanceLabel(en, 3), '2-5 km');
      expect(distanceLabel(en, 7.5), '5-10 km');
      expect(distanceLabel(en, 18), '10-25 km');
      expect(distanceLabel(en, 300), '25+ km');
    });

    test('never shows the exact figure', () {
      for (final km in [0.37, 1.3, 3.14159, 8.2, 13.7, 42.0]) {
        final label = distanceLabel(en, km);
        expect(label, isNot(contains(km.toString())));
        expect(label, isNot(contains(km.toStringAsFixed(1))));
      }
    });

    test('0 is "unknown" by default (candidate models), a bucket on request',
        () {
      expect(distanceLabel(en, 0), '');
      expect(distanceLabel(en, 0, zeroIsUnknown: false), '< 2 km');
      expect(distanceLabel(en, null), '');
    });

    test('every supported locale has all five labels', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        final labels = DistanceBucket.values
            .map((b) => distanceBucketText(l10n, b))
            .toList();
        expect(labels.every((l) => l.trim().isNotEmpty), isTrue,
            reason: '$locale');
        expect(labels.toSet().length, DistanceBucket.values.length,
            reason: '$locale labels must be distinct');
      }
    });
  });
}
