import 'package:flutter/foundation.dart';

/// Content Filter Service
///
/// Detects and filters sensitive content like emails, phone numbers,
/// and other contact information from messages
class ContentFilterService {
  static final ContentFilterService _instance = ContentFilterService._internal();
  factory ContentFilterService() => _instance;
  ContentFilterService._internal();

  // Email pattern - matches most common email formats
  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  // Phone patterns for various formats
  static final List<RegExp> _phonePatterns = [
    // International format with + (e.g., +1234567890, +39 123 456 7890)
    RegExp(r'\+\d{1,4}[\s.-]?\d{1,4}[\s.-]?\d{1,4}[\s.-]?\d{1,9}'),
    // Numbers with country code in parentheses (e.g., (1) 234-567-8901)
    RegExp(r'\(\d{1,4}\)[\s.-]?\d{1,4}[\s.-]?\d{1,9}'),
    // Standard formats (e.g., 123-456-7890, 123.456.7890, 123 456 7890)
    RegExp(r'\b\d{3}[\s.-]?\d{3}[\s.-]?\d{4}\b'),
    // Longer international numbers (e.g., 00 39 123 456 7890)
    RegExp(r'\b00[\s.-]?\d{1,3}[\s.-]?\d{1,4}[\s.-]?\d{1,4}[\s.-]?\d{1,9}\b'),
    // Numbers with at least 7 consecutive digits (could be phone)
    RegExp(r'\b\d{7,15}\b'),
  ];

  // Social media handles patterns
  static final List<RegExp> _socialMediaPatterns = [
    // @ handles (Instagram, Twitter, etc.)
    RegExp(r'@[a-zA-Z0-9._]{1,30}', caseSensitive: false),
    // URLs
    RegExp(r'https?://[^\s]+', caseSensitive: false),
    // www URLs
    RegExp(r'www\.[^\s]+', caseSensitive: false),
    // Social media platform mentions with username
    RegExp(r'\b(instagram|insta|ig|snapchat|snap|tiktok|twitter|telegram|whatsapp|facebook|fb|messenger|signal|discord|skype|viber|wechat|line)\s*[:\-]?\s*[a-zA-Z0-9._]{2,30}\b', caseSensitive: false),
    // "my [platform] is [username]" pattern
    RegExp(r'\b(my|add me on|find me on|contact me on|dm me on|message me on|hit me up on)\s+(instagram|insta|ig|snapchat|snap|tiktok|twitter|telegram|whatsapp|facebook|fb|messenger|discord)\s+(is\s+)?[a-zA-Z0-9._]{2,30}\b', caseSensitive: false),
    // "[platform] username/handle: [name]" pattern
    RegExp(r'\b(instagram|insta|ig|snapchat|snap|tiktok|twitter|telegram|whatsapp|facebook|fb|messenger|discord)\s+(username|handle|user|account|id)\s*[:\-]?\s*[a-zA-Z0-9._]{2,30}\b', caseSensitive: false),
  ];

  // Number words in multiple languages (unique keys only)
  static final Map<String, String> _numberWords = {
    // English
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'ten': '10',
    // Italian (unique words)
    'uno': '1', 'due': '2', 'tre': '3', 'quattro': '4',
    'cinque': '5', 'sei': '6', 'sette': '7', 'otto': '8', 'nove': '9',
    'dieci': '10',
    // Spanish (unique words)
    'cero': '0', 'una': '1', 'dos': '2', 'tres': '3', 'cuatro': '4',
    'cinco': '5', 'siete': '7', 'ocho': '8', 'nueve': '9',
    'diez': '10',
    // French (unique words)
    'zéro': '0', 'un': '1', 'deux': '2', 'trois': '3',
    'cinq': '5', 'sept': '7', 'huit': '8', 'neuf': '9',
    'dix': '10',
    // German (unique words)
    'null': '0', 'eins': '1', 'zwei': '2', 'drei': '3', 'vier': '4',
    'fünf': '5', 'sechs': '6', 'sieben': '7', 'acht': '8',
    'zehn': '10',
    // Portuguese (unique words)
    'um': '1', 'dois': '2', 'três': '3',
    'oito': '8',
    'dez': '10',
  };

  /// Check if message contains email address
  bool containsEmail(String text) {
    return _emailPattern.hasMatch(text);
  }

  /// Convert written number words to digits
  /// e.g., "three three four one one two" -> "334112"
  String _convertWordNumbersToDigits(String text) {
    String result = text.toLowerCase();

    // Sort by length (longest first) to avoid partial replacements
    final sortedWords = _numberWords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in sortedWords) {
      final digit = _numberWords[word]!;
      // Use word boundaries to avoid matching parts of words
      result = result.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), digit);
    }

    return result;
  }

  /// Check if message contains phone number (including written-out numbers)
  bool containsPhoneNumber(String text) {
    // First check the original text
    if (_checkPhonePatterns(text)) {
      return true;
    }

    // Convert written numbers to digits and check again
    final convertedText = _convertWordNumbersToDigits(text);
    if (convertedText != text.toLowerCase() && _checkPhonePatterns(convertedText)) {
      return true;
    }

    return false;
  }

  /// Helper to check phone patterns in text
  bool _checkPhonePatterns(String text) {
    for (final pattern in _phonePatterns) {
      if (pattern.hasMatch(text)) {
        // Additional validation to reduce false positives
        final matches = pattern.allMatches(text);
        for (final match in matches) {
          final matchedText = match.group(0) ?? '';
          // Must have at least 7 digits to be considered a phone number
          final digitCount = matchedText.replaceAll(RegExp(r'\D'), '').length;
          if (digitCount >= 7) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Check if message contains social media handles or URLs
  bool containsSocialMedia(String text) {
    for (final pattern in _socialMediaPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Check if message contains any contact information
  bool containsContactInfo(String text) {
    return containsEmail(text) || containsPhoneNumber(text) || containsSocialMedia(text);
  }

  /// Check if written phone numbers are in text (separate from digit check)
  bool containsWrittenPhoneNumber(String text) {
    final convertedText = _convertWordNumbersToDigits(text);
    // Only return true if conversion happened AND it contains a phone pattern
    return convertedText != text.toLowerCase() && _checkPhonePatterns(convertedText);
  }

  /// Get details about what contact info was found
  ContentFilterResult analyzeContent(String text) {
    final hasEmail = containsEmail(text);
    final hasPhone = containsPhoneNumber(text);
    final hasSocialMedia = containsSocialMedia(text);
    final hasWrittenPhone = containsWrittenPhoneNumber(text);
    final hasContactInfo = hasEmail || hasPhone || hasSocialMedia;

    List<String> violations = [];
    if (hasEmail) violations.add('email address');
    if (hasPhone) {
      if (hasWrittenPhone) {
        violations.add('phone number (written as words)');
      } else {
        violations.add('phone number');
      }
    }
    if (hasSocialMedia) violations.add('social media/link');

    return ContentFilterResult(
      hasContactInfo: hasContactInfo,
      hasEmail: hasEmail,
      hasPhone: hasPhone,
      hasSocialMedia: hasSocialMedia,
      violations: violations,
    );
  }

  /// Mask contact information in text
  String maskContactInfo(String text) {
    String maskedText = text;

    // Mask emails
    maskedText = maskedText.replaceAllMapped(
      _emailPattern,
      (match) => '[email hidden]',
    );

    // Mask phone numbers
    for (final pattern in _phonePatterns) {
      maskedText = maskedText.replaceAllMapped(
        pattern,
        (match) {
          final matchedText = match.group(0) ?? '';
          final digitCount = matchedText.replaceAll(RegExp(r'\D'), '').length;
          if (digitCount >= 7) {
            return '[phone hidden]';
          }
          return matchedText;
        },
      );
    }

    // Mask social media
    for (final pattern in _socialMediaPatterns) {
      maskedText = maskedText.replaceAllMapped(
        pattern,
        (match) => '[link hidden]',
      );
    }

    return maskedText;
  }

  /// Get the blocked message replacement text
  String getBlockedMessageText() {
    return 'This message has been blocked because it contains contact information. For your safety, sharing personal contact details is not allowed.';
  }

  /// Log filter action for debugging
  void logFilterAction(String originalText, ContentFilterResult result) {
    if (result.hasContactInfo) {
      debugPrint('Content Filter: Blocked message containing ${result.violations.join(', ')}');
    }
  }
}

/// Result of content filtering analysis
class ContentFilterResult {
  final bool hasContactInfo;
  final bool hasEmail;
  final bool hasPhone;
  final bool hasSocialMedia;
  final List<String> violations;

  const ContentFilterResult({
    required this.hasContactInfo,
    required this.hasEmail,
    required this.hasPhone,
    required this.hasSocialMedia,
    required this.violations,
  });

  @override
  String toString() {
    return 'ContentFilterResult(hasContactInfo: $hasContactInfo, violations: $violations)';
  }
}
