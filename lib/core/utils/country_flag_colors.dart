import 'package:flutter/material.dart';

/// Maps a country (ISO-3166 alpha-2 code *or* a country name) to a tasteful,
/// flag-derived gradient for the Explore "backdrop band".
///
/// The colours are intentionally *toned down* — darkened and slightly
/// desaturated versions of each flag's hues — so that white text and the app's
/// frosted glass stay readable when layered on top (the Explore band also
/// applies a black scrim over this gradient). We never use pure, fully
/// saturated flag primaries because they blow out under white type.
///
/// Coverage: ~40 common countries plus a neutral brand default. Both alpha-2
/// codes (e.g. `PT`) and English country names (e.g. `Portugal`) resolve.
class CountryFlagColors {
  CountryFlagColors._();

  /// Toned flag palettes keyed by ISO-3166 alpha-2 code. Each is 2–3 colours,
  /// ordered for a top-left → bottom-right gradient.
  static const Map<String, List<Color>> _byCode = <String, List<Color>>{
    // Europe
    'PT': [Color(0xFF1F6B3B), Color(0xFF2E7D46), Color(0xFF8E1B22)], // green→red
    'ES': [Color(0xFF8E1B22), Color(0xFF9C7A16)], // red→gold
    'IT': [Color(0xFF1F6B3B), Color(0xFF6B6B6B), Color(0xFF8E1B22)], // grn/wht/red
    'FR': [Color(0xFF1B2A6B), Color(0xFF5A5A5A), Color(0xFF8E1B22)], // blu/wht/red
    'DE': [Color(0xFF1A1A1A), Color(0xFF7A1418), Color(0xFF9C7A16)], // blk/red/gold
    'GB': [Color(0xFF16255C), Color(0xFF7A1418)], // navy→red
    'IE': [Color(0xFF1F6B3B), Color(0xFF9C7A16)], // green→orange
    'NL': [Color(0xFF7A1418), Color(0xFF16255C)], // red→blue
    'BE': [Color(0xFF1A1A1A), Color(0xFF9C7A16), Color(0xFF7A1418)],
    'CH': [Color(0xFF8E1B22), Color(0xFF5A5A5A)],
    'AT': [Color(0xFF8E1B22), Color(0xFF5A5A5A)],
    'SE': [Color(0xFF16255C), Color(0xFF9C7A16)], // blue→gold
    'NO': [Color(0xFF16255C), Color(0xFF7A1418)],
    'DK': [Color(0xFF7A1418), Color(0xFF5A5A5A)],
    'FI': [Color(0xFF16255C), Color(0xFF3A4A6B)],
    'PL': [Color(0xFF6B6B6B), Color(0xFF8E1B22)],
    'GR': [Color(0xFF16255C), Color(0xFF3A4A6B)],
    'RU': [Color(0xFF16255C), Color(0xFF7A1418)],
    'UA': [Color(0xFF16255C), Color(0xFF9C7A16)], // blue→yellow
    'TR': [Color(0xFF8E1B22), Color(0xFF6B1216)],
    'RO': [Color(0xFF16255C), Color(0xFF9C7A16), Color(0xFF7A1418)],
    'HU': [Color(0xFF8E1B22), Color(0xFF1F6B3B)],
    'CZ': [Color(0xFF16255C), Color(0xFF7A1418)],

    // Americas
    'US': [Color(0xFF16255C), Color(0xFF7A1418)],
    'CA': [Color(0xFF8E1B22), Color(0xFF6B1216)],
    'BR': [Color(0xFF1F6B3B), Color(0xFF9C7A16), Color(0xFF16255C)],
    'MX': [Color(0xFF1F6B3B), Color(0xFF8E1B22)],
    'AR': [Color(0xFF3A4A6B), Color(0xFF9C7A16)],
    'CO': [Color(0xFF9C7A16), Color(0xFF16255C), Color(0xFF8E1B22)],
    'CL': [Color(0xFF16255C), Color(0xFF7A1418)],
    'PE': [Color(0xFF8E1B22), Color(0xFF6B1216)],

    // Asia / Middle East
    'JP': [Color(0xFF8E1B22), Color(0xFF3A3A3A)],
    'CN': [Color(0xFF8E1B22), Color(0xFF9C7A16)],
    'KR': [Color(0xFF16255C), Color(0xFF7A1418)],
    'IN': [Color(0xFF9C5A16), Color(0xFF1F6B3B)], // saffron→green
    'ID': [Color(0xFF8E1B22), Color(0xFF5A5A5A)],
    'TH': [Color(0xFF8E1B22), Color(0xFF16255C)],
    'VN': [Color(0xFF8E1B22), Color(0xFF9C7A16)],
    'PH': [Color(0xFF16255C), Color(0xFF7A1418), Color(0xFF9C7A16)],
    'AE': [Color(0xFF1F6B3B), Color(0xFF7A1418)],
    'SA': [Color(0xFF1F6B3B), Color(0xFF14512C)],
    'IL': [Color(0xFF16255C), Color(0xFF3A4A6B)],

    // Africa & Oceania
    'ZA': [Color(0xFF1F6B3B), Color(0xFF9C7A16), Color(0xFF16255C)],
    'EG': [Color(0xFF8E1B22), Color(0xFF9C7A16)],
    'NG': [Color(0xFF1F6B3B), Color(0xFF14512C)],
    'MA': [Color(0xFF8E1B22), Color(0xFF1F6B3B)],
    'AU': [Color(0xFF16255C), Color(0xFF7A1418)],
    'NZ': [Color(0xFF16255C), Color(0xFF7A1418)],
  };

  /// Neutral brand fallback — deep gold-over-charcoal so the band still reads as
  /// "GreenGo" when the country is unknown.
  static const List<Color> _neutral = <Color>[
    Color(0xFF3A2E12),
    Color(0xFF241D0E),
    Color(0xFF1A1A1A),
  ];

  /// Common English country names → alpha-2, so a profile `location.country`
  /// stored as a display name still resolves to a flag palette.
  static const Map<String, String> _nameToCode = <String, String>{
    'portugal': 'PT',
    'spain': 'ES',
    'italy': 'IT',
    'france': 'FR',
    'germany': 'DE',
    'united kingdom': 'GB',
    'great britain': 'GB',
    'england': 'GB',
    'scotland': 'GB',
    'wales': 'GB',
    'ireland': 'IE',
    'netherlands': 'NL',
    'holland': 'NL',
    'belgium': 'BE',
    'switzerland': 'CH',
    'austria': 'AT',
    'sweden': 'SE',
    'norway': 'NO',
    'denmark': 'DK',
    'finland': 'FI',
    'poland': 'PL',
    'greece': 'GR',
    'russia': 'RU',
    'ukraine': 'UA',
    'turkey': 'TR',
    'turkiye': 'TR',
    'romania': 'RO',
    'hungary': 'HU',
    'czechia': 'CZ',
    'czech republic': 'CZ',
    'united states': 'US',
    'united states of america': 'US',
    'usa': 'US',
    'america': 'US',
    'canada': 'CA',
    'brazil': 'BR',
    'brasil': 'BR',
    'mexico': 'MX',
    'argentina': 'AR',
    'colombia': 'CO',
    'chile': 'CL',
    'peru': 'PE',
    'japan': 'JP',
    'china': 'CN',
    'south korea': 'KR',
    'korea': 'KR',
    'india': 'IN',
    'indonesia': 'ID',
    'thailand': 'TH',
    'vietnam': 'VN',
    'philippines': 'PH',
    'united arab emirates': 'AE',
    'uae': 'AE',
    'saudi arabia': 'SA',
    'israel': 'IL',
    'south africa': 'ZA',
    'egypt': 'EG',
    'nigeria': 'NG',
    'morocco': 'MA',
    'australia': 'AU',
    'new zealand': 'NZ',
  };

  /// Resolve [country] (an alpha-2 code like `PT` or a name like `Portugal`) to
  /// an alpha-2 code, or `null` if it can't be resolved.
  static String? resolveCode(String? country) {
    if (country == null) return null;
    final raw = country.trim();
    if (raw.isEmpty) return null;
    final upper = raw.toUpperCase();
    if (raw.length == 2 && _byCode.containsKey(upper)) return upper;
    return _nameToCode[raw.toLowerCase()];
  }

  /// Toned flag colours (2–3) for [country]; the neutral brand palette when the
  /// country is unknown.
  static List<Color> colorsFor(String? country) {
    final code = resolveCode(country);
    return _byCode[code] ?? _neutral;
  }

  /// A ready-to-use flag-derived [LinearGradient] for the Explore backdrop band.
  static LinearGradient gradientFor(
    String? country, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final colors = colorsFor(country);
    return LinearGradient(begin: begin, end: end, colors: colors);
  }
}
