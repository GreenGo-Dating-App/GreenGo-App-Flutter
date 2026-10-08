import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/country_flag_helper.dart';
import 'package:greengo_chat/core/utils/country_names_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/arb_loader.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));
  final deArb = loadArb('de');
  final enArb = loadArb('en');

  test('every CountryFlagHelper country resolves to its ARB name (en + de)', () {
    for (final c in CountryFlagHelper.allCountries) {
      final key = 'countryName${c.isoCode}';
      expect(enArb[key], isA<String>(), reason: 'missing en key $key');
      expect(deArb[key], isA<String>(), reason: 'missing de key $key');
      // By ISO code and by stored English name.
      expect(localizedCountryName(de, c.isoCode), deArb[key],
          reason: c.isoCode);
      expect(localizedCountryName(de, c.name), deArb[key], reason: c.name);
      expect(localizedCountryName(en, c.isoCode), enArb[key],
          reason: c.isoCode);
    }
  });

  test('German names differ from English where they should', () {
    expect(localizedCountryName(de, 'DE'), 'Deutschland');
    expect(localizedCountryName(de, 'Germany'), 'Deutschland');
    expect(localizedCountryName(de, 'United States'), 'Vereinigte Staaten');
    expect(localizedCountryName(de, 'it'), 'Italien');
    var differing = 0;
    for (final c in CountryFlagHelper.allCountries) {
      if (localizedCountryName(de, c.isoCode) !=
          localizedCountryName(en, c.isoCode)) {
        differing++;
      }
    }
    expect(differing, greaterThan(100));
  });

  test('aliases used by globe / geo data resolve', () {
    expect(localizedCountryName(de, 'Czechia'), 'Tschechien');
    expect(localizedCountryName(de, 'DR Congo'),
        'Demokratische Republik Kongo');
    expect(localizedCountryName(de, 'East Timor'), 'Osttimor');
    expect(localizedCountryName(de, 'USA'), 'Vereinigte Staaten');
    expect(localizedCountryName(de, 'Hong Kong'), 'Hongkong');
  });

  test('unknown input is returned unchanged', () {
    expect(localizedCountryName(de, 'Atlantis'), 'Atlantis');
    expect(localizedCountryName(de, 'Unknown'), 'Unknown');
    expect(localizedCountryName(de, 'QQ'), 'QQ');
    expect(localizedCountryName(de, ''), '');
  });

  test('countryMatchesQuery matches localized and English names', () {
    expect(countryMatchesQuery(de, 'Germany', 'deutsch'), isTrue);
    expect(countryMatchesQuery(de, 'Germany', 'germ'), isTrue);
    expect(countryMatchesQuery(de, 'Germany', 'fran'), isFalse);
    expect(countryMatchesQuery(de, 'Germany', ''), isTrue);
  });
}
