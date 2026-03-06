import 'package:flutter/material.dart';
import '../utils/country_flag_helper.dart';

/// Maps a language name to its most representative country ISO code.
const _languageToCountry = <String, String>{
  'English': 'GB',
  'Spanish': 'ES',
  'French': 'FR',
  'German': 'DE',
  'Italian': 'IT',
  'Portuguese': 'PT',
  'Portuguese (Brazil)': 'BR',
  'Russian': 'RU',
  'Chinese': 'CN',
  'Japanese': 'JP',
  'Korean': 'KR',
  'Arabic': 'SA',
  'Hindi': 'IN',
  'Dutch': 'NL',
  'Swedish': 'SE',
  'Norwegian': 'NO',
  'Danish': 'DK',
  'Finnish': 'FI',
  'Polish': 'PL',
  'Turkish': 'TR',
  'Greek': 'GR',
};

/// Displays flag emojis for the languages a user speaks.
class LanguageFlagBadge extends StatelessWidget {
  final List<String> languages;
  final double fontSize;
  final int maxFlags;

  const LanguageFlagBadge({
    super.key,
    required this.languages,
    this.fontSize = 14,
    this.maxFlags = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();

    final flags = <String>[];
    for (final lang in languages) {
      final code = _languageToCountry[lang];
      if (code != null) {
        flags.add(CountryFlagHelper.getFlag(code));
      }
      if (flags.length >= maxFlags) break;
    }

    if (flags.isEmpty) return const SizedBox.shrink();

    return Text(
      flags.join(''),
      style: TextStyle(fontSize: fontSize),
    );
  }
}
