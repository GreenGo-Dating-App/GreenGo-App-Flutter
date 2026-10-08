import '../../generated/app_localizations.dart';
import 'country_flag_helper.dart';

/// Alternative English spellings (geo data, older profiles, map datasets)
/// mapped to ISO codes, for names that differ from
/// [CountryFlagHelper.allCountries]. Keys are lower-case.
const Map<String, String> _englishAliases = {
  'czechia': 'CZ',
  'congo': 'CG',
  'republic of the congo': 'CG',
  'dr congo': 'CD',
  'democratic republic of the congo': 'CD',
  'east timor': 'TL',
  'cape verde': 'CV',
  'turkiye': 'TR',
  'swaziland': 'SZ',
  'macedonia': 'MK',
  'burma': 'MM',
  'usa': 'US',
  'united states of america': 'US',
  'uk': 'GB',
  'great britain': 'GB',
  'russian federation': 'RU',
  "cote d'ivoire": 'CI',
  "côte d'ivoire": 'CI',
  'vatican': 'VA',
  'holy see': 'VA',
  'hong kong': 'HK',
  'puerto rico': 'PR',
};

/// ISO 3166-1 alpha-2 code for a country code or English country name, or
/// null when it is not recognised.
String? countryCodeFor(String codeOrEnglishName) {
  final raw = codeOrEnglishName.trim();
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  final alias = _englishAliases[lower];
  if (alias != null) return alias;
  if (raw.length == 2) return raw.toUpperCase();
  return CountryFlagHelper.getCodeFromName(raw);
}

/// Localized display name for a country.
///
/// [codeOrEnglishName] may be an ISO 3166-1 alpha-2 code ("IT") or the English
/// name used in [CountryFlagHelper.allCountries] ("Italy"). Stored values stay
/// in English / ISO form; only the DISPLAY is localized. Unknown input is
/// returned unchanged (e.g. a free-text country typed by a user).
String localizedCountryName(AppLocalizations l10n, String codeOrEnglishName) {
  final raw = codeOrEnglishName.trim();
  if (raw.isEmpty) return codeOrEnglishName;
  final code = countryCodeFor(raw);
  if (code == null) return codeOrEnglishName;
  final localized = _localizedByCode(l10n, code);
  if (localized != null) return localized;
  if (raw.length != 2) return codeOrEnglishName;
  for (final c in CountryFlagHelper.allCountries) {
    if (c.isoCode == code) return c.name;
  }
  return codeOrEnglishName;
}

/// True when [query] matches the country either by its localized display name
/// or by its stored English name / code (case-insensitive substring).
bool countryMatchesQuery(
    AppLocalizations l10n, String codeOrEnglishName, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return codeOrEnglishName.toLowerCase().contains(q) ||
      localizedCountryName(l10n, codeOrEnglishName).toLowerCase().contains(q);
}

/// ISO code -> localized name. Returns null for codes without an ARB entry.
String? _localizedByCode(AppLocalizations l10n, String code) {
  switch (code) {
    case 'AD':
      return l10n.countryNameAD;
    case 'AE':
      return l10n.countryNameAE;
    case 'AF':
      return l10n.countryNameAF;
    case 'AG':
      return l10n.countryNameAG;
    case 'AL':
      return l10n.countryNameAL;
    case 'AM':
      return l10n.countryNameAM;
    case 'AO':
      return l10n.countryNameAO;
    case 'AR':
      return l10n.countryNameAR;
    case 'AT':
      return l10n.countryNameAT;
    case 'AU':
      return l10n.countryNameAU;
    case 'AZ':
      return l10n.countryNameAZ;
    case 'BA':
      return l10n.countryNameBA;
    case 'BB':
      return l10n.countryNameBB;
    case 'BD':
      return l10n.countryNameBD;
    case 'BE':
      return l10n.countryNameBE;
    case 'BF':
      return l10n.countryNameBF;
    case 'BG':
      return l10n.countryNameBG;
    case 'BH':
      return l10n.countryNameBH;
    case 'BI':
      return l10n.countryNameBI;
    case 'BJ':
      return l10n.countryNameBJ;
    case 'BN':
      return l10n.countryNameBN;
    case 'BO':
      return l10n.countryNameBO;
    case 'BR':
      return l10n.countryNameBR;
    case 'BS':
      return l10n.countryNameBS;
    case 'BT':
      return l10n.countryNameBT;
    case 'BW':
      return l10n.countryNameBW;
    case 'BY':
      return l10n.countryNameBY;
    case 'BZ':
      return l10n.countryNameBZ;
    case 'CA':
      return l10n.countryNameCA;
    case 'CD':
      return l10n.countryNameCD;
    case 'CF':
      return l10n.countryNameCF;
    case 'CG':
      return l10n.countryNameCG;
    case 'CH':
      return l10n.countryNameCH;
    case 'CI':
      return l10n.countryNameCI;
    case 'CL':
      return l10n.countryNameCL;
    case 'CM':
      return l10n.countryNameCM;
    case 'CN':
      return l10n.countryNameCN;
    case 'CO':
      return l10n.countryNameCO;
    case 'CR':
      return l10n.countryNameCR;
    case 'CU':
      return l10n.countryNameCU;
    case 'CV':
      return l10n.countryNameCV;
    case 'CY':
      return l10n.countryNameCY;
    case 'CZ':
      return l10n.countryNameCZ;
    case 'DE':
      return l10n.countryNameDE;
    case 'DJ':
      return l10n.countryNameDJ;
    case 'DK':
      return l10n.countryNameDK;
    case 'DM':
      return l10n.countryNameDM;
    case 'DO':
      return l10n.countryNameDO;
    case 'DZ':
      return l10n.countryNameDZ;
    case 'EC':
      return l10n.countryNameEC;
    case 'EE':
      return l10n.countryNameEE;
    case 'EG':
      return l10n.countryNameEG;
    case 'ER':
      return l10n.countryNameER;
    case 'ES':
      return l10n.countryNameES;
    case 'ET':
      return l10n.countryNameET;
    case 'FI':
      return l10n.countryNameFI;
    case 'FJ':
      return l10n.countryNameFJ;
    case 'FM':
      return l10n.countryNameFM;
    case 'FR':
      return l10n.countryNameFR;
    case 'GA':
      return l10n.countryNameGA;
    case 'GB':
      return l10n.countryNameGB;
    case 'GD':
      return l10n.countryNameGD;
    case 'GE':
      return l10n.countryNameGE;
    case 'GH':
      return l10n.countryNameGH;
    case 'GM':
      return l10n.countryNameGM;
    case 'GN':
      return l10n.countryNameGN;
    case 'GQ':
      return l10n.countryNameGQ;
    case 'GR':
      return l10n.countryNameGR;
    case 'GT':
      return l10n.countryNameGT;
    case 'GW':
      return l10n.countryNameGW;
    case 'GY':
      return l10n.countryNameGY;
    case 'HK':
      return l10n.countryNameHK;
    case 'HN':
      return l10n.countryNameHN;
    case 'HR':
      return l10n.countryNameHR;
    case 'HT':
      return l10n.countryNameHT;
    case 'HU':
      return l10n.countryNameHU;
    case 'ID':
      return l10n.countryNameID;
    case 'IE':
      return l10n.countryNameIE;
    case 'IL':
      return l10n.countryNameIL;
    case 'IN':
      return l10n.countryNameIN;
    case 'IQ':
      return l10n.countryNameIQ;
    case 'IR':
      return l10n.countryNameIR;
    case 'IS':
      return l10n.countryNameIS;
    case 'IT':
      return l10n.countryNameIT;
    case 'JM':
      return l10n.countryNameJM;
    case 'JO':
      return l10n.countryNameJO;
    case 'JP':
      return l10n.countryNameJP;
    case 'KE':
      return l10n.countryNameKE;
    case 'KG':
      return l10n.countryNameKG;
    case 'KH':
      return l10n.countryNameKH;
    case 'KI':
      return l10n.countryNameKI;
    case 'KM':
      return l10n.countryNameKM;
    case 'KN':
      return l10n.countryNameKN;
    case 'KP':
      return l10n.countryNameKP;
    case 'KR':
      return l10n.countryNameKR;
    case 'KW':
      return l10n.countryNameKW;
    case 'KZ':
      return l10n.countryNameKZ;
    case 'LA':
      return l10n.countryNameLA;
    case 'LB':
      return l10n.countryNameLB;
    case 'LC':
      return l10n.countryNameLC;
    case 'LI':
      return l10n.countryNameLI;
    case 'LK':
      return l10n.countryNameLK;
    case 'LR':
      return l10n.countryNameLR;
    case 'LS':
      return l10n.countryNameLS;
    case 'LT':
      return l10n.countryNameLT;
    case 'LU':
      return l10n.countryNameLU;
    case 'LV':
      return l10n.countryNameLV;
    case 'LY':
      return l10n.countryNameLY;
    case 'MA':
      return l10n.countryNameMA;
    case 'MC':
      return l10n.countryNameMC;
    case 'MD':
      return l10n.countryNameMD;
    case 'ME':
      return l10n.countryNameME;
    case 'MG':
      return l10n.countryNameMG;
    case 'MH':
      return l10n.countryNameMH;
    case 'MK':
      return l10n.countryNameMK;
    case 'ML':
      return l10n.countryNameML;
    case 'MM':
      return l10n.countryNameMM;
    case 'MN':
      return l10n.countryNameMN;
    case 'MR':
      return l10n.countryNameMR;
    case 'MT':
      return l10n.countryNameMT;
    case 'MU':
      return l10n.countryNameMU;
    case 'MV':
      return l10n.countryNameMV;
    case 'MW':
      return l10n.countryNameMW;
    case 'MX':
      return l10n.countryNameMX;
    case 'MY':
      return l10n.countryNameMY;
    case 'MZ':
      return l10n.countryNameMZ;
    case 'NA':
      return l10n.countryNameNA;
    case 'NE':
      return l10n.countryNameNE;
    case 'NG':
      return l10n.countryNameNG;
    case 'NI':
      return l10n.countryNameNI;
    case 'NL':
      return l10n.countryNameNL;
    case 'NO':
      return l10n.countryNameNO;
    case 'NP':
      return l10n.countryNameNP;
    case 'NR':
      return l10n.countryNameNR;
    case 'NZ':
      return l10n.countryNameNZ;
    case 'OM':
      return l10n.countryNameOM;
    case 'PA':
      return l10n.countryNamePA;
    case 'PE':
      return l10n.countryNamePE;
    case 'PG':
      return l10n.countryNamePG;
    case 'PH':
      return l10n.countryNamePH;
    case 'PK':
      return l10n.countryNamePK;
    case 'PL':
      return l10n.countryNamePL;
    case 'PR':
      return l10n.countryNamePR;
    case 'PS':
      return l10n.countryNamePS;
    case 'PT':
      return l10n.countryNamePT;
    case 'PW':
      return l10n.countryNamePW;
    case 'PY':
      return l10n.countryNamePY;
    case 'QA':
      return l10n.countryNameQA;
    case 'RO':
      return l10n.countryNameRO;
    case 'RS':
      return l10n.countryNameRS;
    case 'RU':
      return l10n.countryNameRU;
    case 'RW':
      return l10n.countryNameRW;
    case 'SA':
      return l10n.countryNameSA;
    case 'SB':
      return l10n.countryNameSB;
    case 'SC':
      return l10n.countryNameSC;
    case 'SD':
      return l10n.countryNameSD;
    case 'SE':
      return l10n.countryNameSE;
    case 'SG':
      return l10n.countryNameSG;
    case 'SI':
      return l10n.countryNameSI;
    case 'SK':
      return l10n.countryNameSK;
    case 'SL':
      return l10n.countryNameSL;
    case 'SM':
      return l10n.countryNameSM;
    case 'SN':
      return l10n.countryNameSN;
    case 'SO':
      return l10n.countryNameSO;
    case 'SR':
      return l10n.countryNameSR;
    case 'SS':
      return l10n.countryNameSS;
    case 'ST':
      return l10n.countryNameST;
    case 'SV':
      return l10n.countryNameSV;
    case 'SY':
      return l10n.countryNameSY;
    case 'SZ':
      return l10n.countryNameSZ;
    case 'TD':
      return l10n.countryNameTD;
    case 'TG':
      return l10n.countryNameTG;
    case 'TH':
      return l10n.countryNameTH;
    case 'TJ':
      return l10n.countryNameTJ;
    case 'TL':
      return l10n.countryNameTL;
    case 'TM':
      return l10n.countryNameTM;
    case 'TN':
      return l10n.countryNameTN;
    case 'TO':
      return l10n.countryNameTO;
    case 'TR':
      return l10n.countryNameTR;
    case 'TT':
      return l10n.countryNameTT;
    case 'TV':
      return l10n.countryNameTV;
    case 'TW':
      return l10n.countryNameTW;
    case 'TZ':
      return l10n.countryNameTZ;
    case 'UA':
      return l10n.countryNameUA;
    case 'UG':
      return l10n.countryNameUG;
    case 'US':
      return l10n.countryNameUS;
    case 'UY':
      return l10n.countryNameUY;
    case 'UZ':
      return l10n.countryNameUZ;
    case 'VA':
      return l10n.countryNameVA;
    case 'VC':
      return l10n.countryNameVC;
    case 'VE':
      return l10n.countryNameVE;
    case 'VN':
      return l10n.countryNameVN;
    case 'VU':
      return l10n.countryNameVU;
    case 'WS':
      return l10n.countryNameWS;
    case 'XK':
      return l10n.countryNameXK;
    case 'YE':
      return l10n.countryNameYE;
    case 'ZA':
      return l10n.countryNameZA;
    case 'ZM':
      return l10n.countryNameZM;
    case 'ZW':
      return l10n.countryNameZW;
    default:
      return null;
  }
}
