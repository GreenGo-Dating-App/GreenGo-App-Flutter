import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/compact_count.dart';

void main() {
  group('formatCompactCount', () {
    test('small numbers are shown as-is', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(7), '7');
      expect(formatCompactCount(999), '999');
    });

    test('negative values clamp to 0', () {
      expect(formatCompactCount(-5), '0');
    });

    test('thousands use k with one truncated decimal below 10k', () {
      expect(formatCompactCount(1000, locale: 'en'), '1k');
      expect(formatCompactCount(1200, locale: 'en'), '1.2k');
      expect(formatCompactCount(1299, locale: 'en'), '1.2k');
      expect(formatCompactCount(1999, locale: 'en'), '1.9k');
      expect(formatCompactCount(9999, locale: 'en'), '9.9k');
    });

    test('10k and above drop the decimal (never rounds up)', () {
      expect(formatCompactCount(10000, locale: 'en'), '10k');
      expect(formatCompactCount(12500, locale: 'en'), '12k');
      expect(formatCompactCount(999999, locale: 'en'), '999k');
    });

    test('millions and billions', () {
      expect(formatCompactCount(1000000, locale: 'en'), '1M');
      expect(formatCompactCount(1250000, locale: 'en'), '1.2M');
      expect(formatCompactCount(45000000, locale: 'en'), '45M');
      expect(formatCompactCount(3000000000, locale: 'en'), '3B');
    });

    test('uses the locale decimal separator', () {
      expect(formatCompactCount(1200, locale: 'de'), '1,2k');
      expect(formatCompactCount(1200, locale: 'it'), '1,2k');
    });
  });
}
