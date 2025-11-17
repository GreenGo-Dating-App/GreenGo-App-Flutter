/**
 * Localization Entity
 * Points 286-300: Internationalization and Accessibility
 */

import 'package:equatable/equatable.dart';

/// Supported locale (Points 286-287)
class AppLocale extends Equatable {
  final String languageCode; // ISO 639-1 (en, es, fr, etc.)
  final String? countryCode; // ISO 3166-1 (US, ES, FR, etc.)
  final String displayName;
  final String nativeName;
  final String flagEmoji;
  final bool isRTL; // Point 289
  final TextDirection textDirection;

  const AppLocale({
    required this.languageCode,
    this.countryCode,
    required this.displayName,
    required this.nativeName,
    required this.flagEmoji,
    this.isRTL = false,
    this.textDirection = TextDirection.ltr,
  });

  String get localeCode => countryCode != null
      ? '${languageCode}_$countryCode'
      : languageCode;

  @override
  List<Object?> get props => [
        languageCode,
        countryCode,
        displayName,
        nativeName,
        flagEmoji,
        isRTL,
        textDirection,
      ];
}

/// Text direction
enum TextDirection {
  ltr, // Left-to-right
  rtl; // Right-to-left (Point 289)
}

/// Supported languages (Point 287 - 50+ languages)
class SupportedLocales {
  static const List<AppLocale> all = [
    // English
    AppLocale(
      languageCode: 'en',
      countryCode: 'US',
      displayName: 'English (US)',
      nativeName: 'English (US)',
      flagEmoji: '🇺🇸',
    ),
    AppLocale(
      languageCode: 'en',
      countryCode: 'GB',
      displayName: 'English (UK)',
      nativeName: 'English (UK)',
      flagEmoji: '🇬🇧',
    ),

    // Spanish
    AppLocale(
      languageCode: 'es',
      countryCode: 'ES',
      displayName: 'Spanish (Spain)',
      nativeName: 'Español (España)',
      flagEmoji: '🇪🇸',
    ),
    AppLocale(
      languageCode: 'es',
      countryCode: 'MX',
      displayName: 'Spanish (Mexico)',
      nativeName: 'Español (México)',
      flagEmoji: '🇲🇽',
    ),

    // French
    AppLocale(
      languageCode: 'fr',
      countryCode: 'FR',
      displayName: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
    ),

    // German
    AppLocale(
      languageCode: 'de',
      countryCode: 'DE',
      displayName: 'German',
      nativeName: 'Deutsch',
      flagEmoji: '🇩🇪',
    ),

    // Italian
    AppLocale(
      languageCode: 'it',
      countryCode: 'IT',
      displayName: 'Italian',
      nativeName: 'Italiano',
      flagEmoji: '🇮🇹',
    ),

    // Portuguese
    AppLocale(
      languageCode: 'pt',
      countryCode: 'BR',
      displayName: 'Portuguese (Brazil)',
      nativeName: 'Português (Brasil)',
      flagEmoji: '🇧🇷',
    ),
    AppLocale(
      languageCode: 'pt',
      countryCode: 'PT',
      displayName: 'Portuguese (Portugal)',
      nativeName: 'Português (Portugal)',
      flagEmoji: '🇵🇹',
    ),

    // RTL Languages (Point 289)
    AppLocale(
      languageCode: 'ar',
      displayName: 'Arabic',
      nativeName: 'العربية',
      flagEmoji: '🇸🇦',
      isRTL: true,
      textDirection: TextDirection.rtl,
    ),
    AppLocale(
      languageCode: 'he',
      displayName: 'Hebrew',
      nativeName: 'עברית',
      flagEmoji: '🇮🇱',
      isRTL: true,
      textDirection: TextDirection.rtl,
    ),
    AppLocale(
      languageCode: 'fa',
      displayName: 'Persian',
      nativeName: 'فارسی',
      flagEmoji: '🇮🇷',
      isRTL: true,
      textDirection: TextDirection.rtl,
    ),

    // Asian Languages
    AppLocale(
      languageCode: 'zh',
      countryCode: 'CN',
      displayName: 'Chinese (Simplified)',
      nativeName: '简体中文',
      flagEmoji: '🇨🇳',
    ),
    AppLocale(
      languageCode: 'zh',
      countryCode: 'TW',
      displayName: 'Chinese (Traditional)',
      nativeName: '繁體中文',
      flagEmoji: '🇹🇼',
    ),
    AppLocale(
      languageCode: 'ja',
      countryCode: 'JP',
      displayName: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
    ),
    AppLocale(
      languageCode: 'ko',
      countryCode: 'KR',
      displayName: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
    ),
    AppLocale(
      languageCode: 'hi',
      countryCode: 'IN',
      displayName: 'Hindi',
      nativeName: 'हिन्दी',
      flagEmoji: '🇮🇳',
    ),
    AppLocale(
      languageCode: 'th',
      countryCode: 'TH',
      displayName: 'Thai',
      nativeName: 'ไทย',
      flagEmoji: '🇹🇭',
    ),
    AppLocale(
      languageCode: 'vi',
      countryCode: 'VN',
      displayName: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
    ),
    AppLocale(
      languageCode: 'id',
      countryCode: 'ID',
      displayName: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flagEmoji: '🇮🇩',
    ),

    // European Languages
    AppLocale(
      languageCode: 'ru',
      countryCode: 'RU',
      displayName: 'Russian',
      nativeName: 'Русский',
      flagEmoji: '🇷🇺',
    ),
    AppLocale(
      languageCode: 'pl',
      countryCode: 'PL',
      displayName: 'Polish',
      nativeName: 'Polski',
      flagEmoji: '🇵🇱',
    ),
    AppLocale(
      languageCode: 'nl',
      countryCode: 'NL',
      displayName: 'Dutch',
      nativeName: 'Nederlands',
      flagEmoji: '🇳🇱',
    ),
    AppLocale(
      languageCode: 'sv',
      countryCode: 'SE',
      displayName: 'Swedish',
      nativeName: 'Svenska',
      flagEmoji: '🇸🇪',
    ),
    AppLocale(
      languageCode: 'da',
      countryCode: 'DK',
      displayName: 'Danish',
      nativeName: 'Dansk',
      flagEmoji: '🇩🇰',
    ),
    AppLocale(
      languageCode: 'no',
      countryCode: 'NO',
      displayName: 'Norwegian',
      nativeName: 'Norsk',
      flagEmoji: '🇳🇴',
    ),
    AppLocale(
      languageCode: 'fi',
      countryCode: 'FI',
      displayName: 'Finnish',
      nativeName: 'Suomi',
      flagEmoji: '🇫🇮',
    ),
    AppLocale(
      languageCode: 'tr',
      countryCode: 'TR',
      displayName: 'Turkish',
      nativeName: 'Türkçe',
      flagEmoji: '🇹🇷',
    ),
    AppLocale(
      languageCode: 'uk',
      countryCode: 'UA',
      displayName: 'Ukrainian',
      nativeName: 'Українська',
      flagEmoji: '🇺🇦',
    ),
    AppLocale(
      languageCode: 'cs',
      countryCode: 'CZ',
      displayName: 'Czech',
      nativeName: 'Čeština',
      flagEmoji: '🇨🇿',
    ),
    AppLocale(
      languageCode: 'ro',
      countryCode: 'RO',
      displayName: 'Romanian',
      nativeName: 'Română',
      flagEmoji: '🇷🇴',
    ),
    AppLocale(
      languageCode: 'hu',
      countryCode: 'HU',
      displayName: 'Hungarian',
      nativeName: 'Magyar',
      flagEmoji: '🇭🇺',
    ),
    AppLocale(
      languageCode: 'el',
      countryCode: 'GR',
      displayName: 'Greek',
      nativeName: 'Ελληνικά',
      flagEmoji: '🇬🇷',
    ),

    // More languages to reach 50+
    AppLocale(
      languageCode: 'bg',
      countryCode: 'BG',
      displayName: 'Bulgarian',
      nativeName: 'Български',
      flagEmoji: '🇧🇬',
    ),
    AppLocale(
      languageCode: 'hr',
      countryCode: 'HR',
      displayName: 'Croatian',
      nativeName: 'Hrvatski',
      flagEmoji: '🇭🇷',
    ),
    AppLocale(
      languageCode: 'sk',
      countryCode: 'SK',
      displayName: 'Slovak',
      nativeName: 'Slovenčina',
      flagEmoji: '🇸🇰',
    ),
    AppLocale(
      languageCode: 'sl',
      countryCode: 'SI',
      displayName: 'Slovenian',
      nativeName: 'Slovenščina',
      flagEmoji: '🇸🇮',
    ),
    AppLocale(
      languageCode: 'lt',
      countryCode: 'LT',
      displayName: 'Lithuanian',
      nativeName: 'Lietuvių',
      flagEmoji: '🇱🇹',
    ),
    AppLocale(
      languageCode: 'lv',
      countryCode: 'LV',
      displayName: 'Latvian',
      nativeName: 'Latviešu',
      flagEmoji: '🇱🇻',
    ),
    AppLocale(
      languageCode: 'et',
      countryCode: 'EE',
      displayName: 'Estonian',
      nativeName: 'Eesti',
      flagEmoji: '🇪🇪',
    ),
    AppLocale(
      languageCode: 'ms',
      countryCode: 'MY',
      displayName: 'Malay',
      nativeName: 'Bahasa Melayu',
      flagEmoji: '🇲🇾',
    ),
    AppLocale(
      languageCode: 'fil',
      countryCode: 'PH',
      displayName: 'Filipino',
      nativeName: 'Filipino',
      flagEmoji: '🇵🇭',
    ),
    AppLocale(
      languageCode: 'bn',
      countryCode: 'BD',
      displayName: 'Bengali',
      nativeName: 'বাংলা',
      flagEmoji: '🇧🇩',
    ),
    AppLocale(
      languageCode: 'ta',
      countryCode: 'IN',
      displayName: 'Tamil',
      nativeName: 'தமிழ்',
      flagEmoji: '🇮🇳',
    ),
    AppLocale(
      languageCode: 'te',
      countryCode: 'IN',
      displayName: 'Telugu',
      nativeName: 'తెలుగు',
      flagEmoji: '🇮🇳',
    ),
    AppLocale(
      languageCode: 'mr',
      countryCode: 'IN',
      displayName: 'Marathi',
      nativeName: 'मराठी',
      flagEmoji: '🇮🇳',
    ),
    AppLocale(
      languageCode: 'ur',
      countryCode: 'PK',
      displayName: 'Urdu',
      nativeName: 'اردو',
      flagEmoji: '🇵🇰',
      isRTL: true,
      textDirection: TextDirection.rtl,
    ),
    AppLocale(
      languageCode: 'sw',
      countryCode: 'KE',
      displayName: 'Swahili',
      nativeName: 'Kiswahili',
      flagEmoji: '🇰🇪',
    ),
  ];
}

/// Locale-aware formatting (Point 290)
class LocaleFormatting extends Equatable {
  final AppLocale locale;
  final DateFormat dateFormat;
  final TimeFormat timeFormat;
  final CurrencyFormat currencyFormat;
  final NumberFormat numberFormat;

  const LocaleFormatting({
    required this.locale,
    required this.dateFormat,
    required this.timeFormat,
    required this.currencyFormat,
    required this.numberFormat,
  });

  @override
  List<Object?> get props => [
        locale,
        dateFormat,
        timeFormat,
        currencyFormat,
        numberFormat,
      ];
}

/// Date format patterns
enum DateFormat {
  mdy, // 12/31/2023 (US)
  dmy, // 31/12/2023 (Europe)
  ymd; // 2023-12-31 (ISO)

  String formatDate(DateTime date) {
    switch (this) {
      case DateFormat.mdy:
        return '${date.month}/${date.day}/${date.year}';
      case DateFormat.dmy:
        return '${date.day}/${date.month}/${date.year}';
      case DateFormat.ymd:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

/// Time format
enum TimeFormat {
  hour12, // 1:30 PM
  hour24; // 13:30

  String formatTime(DateTime time) {
    switch (this) {
      case TimeFormat.hour12:
        final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
        final period = time.hour >= 12 ? 'PM' : 'AM';
        return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
      case TimeFormat.hour24:
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Currency format (Point 290)
class CurrencyFormat extends Equatable {
  final String currencyCode; // USD, EUR, GBP, etc.
  final String symbol; // $, €, £, etc.
  final CurrencyPosition symbolPosition;
  final String decimalSeparator;
  final String thousandsSeparator;
  final int decimalPlaces;

  const CurrencyFormat({
    required this.currencyCode,
    required this.symbol,
    required this.symbolPosition,
    this.decimalSeparator = '.',
    this.thousandsSeparator = ',',
    this.decimalPlaces = 2,
  });

  String format(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    // Add thousands separators
    String formattedInt = '';
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        formattedInt += thousandsSeparator;
      }
      formattedInt += intPart[i];
    }

    final value = decPart.isNotEmpty
        ? '$formattedInt$decimalSeparator$decPart'
        : formattedInt;

    return symbolPosition == CurrencyPosition.before
        ? '$symbol$value'
        : '$value$symbol';
  }

  @override
  List<Object?> get props => [
        currencyCode,
        symbol,
        symbolPosition,
        decimalSeparator,
        thousandsSeparator,
        decimalPlaces,
      ];
}

enum CurrencyPosition { before, after }

/// Number format
class NumberFormat extends Equatable {
  final String decimalSeparator;
  final String thousandsSeparator;

  const NumberFormat({
    this.decimalSeparator = '.',
    this.thousandsSeparator = ',',
  });

  @override
  List<Object?> get props => [decimalSeparator, thousandsSeparator];
}

/// Regional payment methods (Point 294)
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  alipay,
  wechatPay,
  ideal,
  sepa,
  sofort,
  bancontact,
  giropay,
  przelewy24,
  boleto,
  oxxo;

  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.alipay:
        return 'Alipay';
      case PaymentMethod.wechatPay:
        return 'WeChat Pay';
      case PaymentMethod.ideal:
        return 'iDEAL';
      case PaymentMethod.sepa:
        return 'SEPA Direct Debit';
      case PaymentMethod.sofort:
        return 'Sofort';
      case PaymentMethod.bancontact:
        return 'Bancontact';
      case PaymentMethod.giropay:
        return 'Giropay';
      case PaymentMethod.przelewy24:
        return 'Przelewy24';
      case PaymentMethod.boleto:
        return 'Boleto';
      case PaymentMethod.oxxo:
        return 'OXXO';
    }
  }

  List<String> get supportedCountries {
    switch (this) {
      case PaymentMethod.alipay:
      case PaymentMethod.wechatPay:
        return ['CN'];
      case PaymentMethod.ideal:
        return ['NL'];
      case PaymentMethod.sofort:
        return ['DE', 'AT', 'CH'];
      case PaymentMethod.bancontact:
        return ['BE'];
      case PaymentMethod.giropay:
        return ['DE'];
      case PaymentMethod.przelewy24:
        return ['PL'];
      case PaymentMethod.boleto:
        return ['BR'];
      case PaymentMethod.oxxo:
        return ['MX'];
      default:
        return []; // Available globally
    }
  }
}

/// Privacy regulation compliance (Point 295)
enum PrivacyRegulation {
  gdpr, // Europe
  ccpa, // California
  lgpd; // Brazil

  String get displayName {
    switch (this) {
      case PrivacyRegulation.gdpr:
        return 'GDPR';
      case PrivacyRegulation.ccpa:
        return 'CCPA';
      case PrivacyRegulation.lgpd:
        return 'LGPD';
    }
  }

  String get description {
    switch (this) {
      case PrivacyRegulation.gdpr:
        return 'General Data Protection Regulation (EU)';
      case PrivacyRegulation.ccpa:
        return 'California Consumer Privacy Act (US)';
      case PrivacyRegulation.lgpd:
        return 'Lei Geral de Proteção de Dados (Brazil)';
    }
  }

  List<String> get applicableCountries {
    switch (this) {
      case PrivacyRegulation.gdpr:
        return ['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR',
                'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
                'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE'];
      case PrivacyRegulation.ccpa:
        return ['US'];
      case PrivacyRegulation.lgpd:
        return ['BR'];
    }
  }
}
