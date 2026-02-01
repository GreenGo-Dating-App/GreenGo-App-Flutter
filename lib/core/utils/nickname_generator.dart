import 'dart:math';

/// Utility class for generating and validating unique nicknames
class NicknameGenerator {
  static final Random _random = Random();

  /// Adjectives for nickname generation
  static const List<String> _adjectives = [
    'Happy', 'Lucky', 'Sunny', 'Brave', 'Cool', 'Sweet', 'Bright', 'Swift',
    'Calm', 'Bold', 'Clever', 'Kind', 'Gentle', 'Wild', 'Free', 'Noble',
    'Vivid', 'Cosmic', 'Mystic', 'Golden', 'Silver', 'Crystal', 'Radiant',
    'Serene', 'Vibrant', 'Dreamy', 'Mellow', 'Zen', 'Funky', 'Groovy',
    'Stellar', 'Epic', 'Dazzling', 'Charming', 'Witty', 'Snazzy', 'Sparkly',
    'Tropical', 'Arctic', 'Blazing', 'Chill', 'Jazzy', 'Breezy', 'Cozy',
  ];

  /// Nouns for nickname generation
  static const List<String> _nouns = [
    'Panda', 'Tiger', 'Eagle', 'Dolphin', 'Phoenix', 'Dragon', 'Wolf',
    'Bear', 'Lion', 'Fox', 'Hawk', 'Owl', 'Raven', 'Star', 'Moon', 'Sun',
    'Ocean', 'River', 'Mountain', 'Forest', 'Storm', 'Thunder', 'Sky',
    'Cloud', 'Wave', 'Flame', 'Spirit', 'Soul', 'Heart', 'Dreamer',
    'Voyager', 'Explorer', 'Wanderer', 'Seeker', 'Knight', 'Guardian',
    'Maverick', 'Pioneer', 'Visionary', 'Nomad', 'Sage', 'Wizard', 'Ninja',
    'Samurai', 'Viking', 'Spartan', 'Titan', 'Atlas', 'Phoenix', 'Griffin',
  ];

  /// Generate a random nickname
  /// Format: Adjective + Noun + Number (e.g., "HappyPanda42")
  static String generate() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    final number = _random.nextInt(999) + 1; // 1-999

    return '$adjective$noun$number';
  }

  /// Generate a nickname based on user ID for consistency
  static String generateFromUserId(String userId) {
    if (userId.isEmpty) return generate();

    // Use userId hash to pick consistent adjective and noun
    final hash = userId.hashCode.abs();
    final adjective = _adjectives[hash % _adjectives.length];
    final noun = _nouns[(hash ~/ _adjectives.length) % _nouns.length];
    final number = (hash % 999) + 1;

    return '$adjective$noun$number';
  }

  /// Generate multiple nickname suggestions
  static List<String> generateSuggestions({int count = 5}) {
    final suggestions = <String>{};
    while (suggestions.length < count) {
      suggestions.add(generate());
    }
    return suggestions.toList();
  }

  /// Validate nickname format
  /// Rules:
  /// - 3-20 characters
  /// - Only letters, numbers, and underscores
  /// - Must start with a letter
  /// - No consecutive underscores
  static NicknameValidationResult validate(String nickname) {
    if (nickname.isEmpty) {
      return NicknameValidationResult(
        isValid: false,
        error: 'Nickname cannot be empty',
      );
    }

    if (nickname.length < 3) {
      return NicknameValidationResult(
        isValid: false,
        error: 'Nickname must be at least 3 characters',
      );
    }

    if (nickname.length > 20) {
      return NicknameValidationResult(
        isValid: false,
        error: 'Nickname must be 20 characters or less',
      );
    }

    // Check for valid characters (letters, numbers, underscores)
    final validPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if (!validPattern.hasMatch(nickname)) {
      if (!RegExp(r'^[a-zA-Z]').hasMatch(nickname)) {
        return NicknameValidationResult(
          isValid: false,
          error: 'Nickname must start with a letter',
        );
      }
      return NicknameValidationResult(
        isValid: false,
        error: 'Nickname can only contain letters, numbers, and underscores',
      );
    }

    // Check for consecutive underscores
    if (nickname.contains('__')) {
      return NicknameValidationResult(
        isValid: false,
        error: 'Nickname cannot contain consecutive underscores',
      );
    }

    // Check for reserved words
    final reservedWords = [
      'admin', 'administrator', 'greengo', 'support', 'help', 'system',
      'moderator', 'mod', 'official', 'staff', 'team', 'root', 'null',
    ];
    final lowerNickname = nickname.toLowerCase();
    for (final word in reservedWords) {
      if (lowerNickname.contains(word)) {
        return NicknameValidationResult(
          isValid: false,
          error: 'Nickname cannot contain reserved words',
        );
      }
    }

    return NicknameValidationResult(isValid: true);
  }

  /// Normalize nickname for comparison (lowercase)
  static String normalize(String nickname) {
    return nickname.toLowerCase().trim();
  }

  /// Check if two nicknames are the same (case-insensitive)
  static bool areEqual(String nickname1, String nickname2) {
    return normalize(nickname1) == normalize(nickname2);
  }
}

/// Result of nickname validation
class NicknameValidationResult {
  final bool isValid;
  final String? error;

  const NicknameValidationResult({
    required this.isValid,
    this.error,
  });
}
