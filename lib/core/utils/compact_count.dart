import 'package:intl/intl.dart';

/// Compact social-style count: 999 → "999", 1234 → "1.2k", 12_500 → "12k",
/// 1_250_000 → "1.2M", 3_000_000_000 → "3B".
///
/// Truncates (never rounds up) so a count is never overstated — 1_999 reads
/// "1.9k", not "2k". One decimal only below 10 of a unit. Negative input is
/// treated as 0. [locale] picks the decimal separator ("1,2k" in de/fr/…).
String formatCompactCount(int value, {String? locale}) {
  final n = value < 0 ? 0 : value;
  if (n < 1000) return '$n';

  const units = <(int, String)>[
    (1000000000, 'B'),
    (1000000, 'M'),
    (1000, 'k'),
  ];
  for (final (size, suffix) in units) {
    if (n < size) continue;
    final whole = n ~/ size;
    if (whole >= 10) return '$whole$suffix';
    final tenth = (n % size) * 10 ~/ size;
    if (tenth == 0) return '$whole$suffix';
    return '$whole${_decimalSeparator(locale)}$tenth$suffix';
  }
  return '$n';
}

String _decimalSeparator(String? locale) {
  try {
    return NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  } catch (_) {
    return '.';
  }
}
