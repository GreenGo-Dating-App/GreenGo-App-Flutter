import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/ai_coach_session.dart';

/// Service for interacting with Gemini 2.0 Flash API for the AI Conversation Coach.
///
/// API key is loaded from Firestore `app_config/api_keys` document.
/// Falls back to a placeholder constant if Firestore fetch fails.
class AiCoachService {
  static const String _geminiApiKeyPlaceholder = 'GEMINI_API_KEY';
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final Dio _dio;
  final FirebaseFirestore _firestore;

  String? _cachedApiKey;

  AiCoachService({
    Dio? dio,
    FirebaseFirestore? firestore,
  })  : _dio = dio ?? Dio(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Loads the Gemini API key from Firestore `app_config/api_keys` document.
  /// Caches the key after the first successful fetch.
  Future<String> _getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey != _geminiApiKeyPlaceholder) {
      return _cachedApiKey!;
    }

    try {
      final doc =
          await _firestore.collection('app_config').doc('api_keys').get();

      if (doc.exists && doc.data() != null) {
        final key = doc.data()!['gemini_api_key'] as String?;
        if (key != null && key.isNotEmpty) {
          _cachedApiKey = key;
          return key;
        }
      }
    } catch (e) {
      // Firestore fetch failed; fall through to placeholder
    }

    return _geminiApiKeyPlaceholder;
  }

  /// Builds the system prompt for the AI coach based on scenario and languages.
  String _buildSystemPrompt({
    required String targetLanguageName,
    required String nativeLanguage,
    required CoachScenario scenario,
  }) {
    return '''You are a friendly and patient language conversation coach for a dating app.
You are helping a user practice $targetLanguageName conversations.
The user's native language is $nativeLanguage.

SCENARIO: ${scenario.displayName}
CONTEXT: ${scenario.description}

YOUR ROLE:
- Act as a native $targetLanguageName speaker in a dating/social context
- Stay in character for the "${scenario.displayName}" scenario
- Respond primarily in $targetLanguageName
- After each response, provide corrections for any mistakes the user made
- Rate the user's grammar, vocabulary, and fluency for each message (0-100)
- Suggest 2-3 alternative ways the user could have expressed their message
- Be encouraging and supportive

RESPONSE FORMAT (JSON):
{
  "response": "Your in-character response in $targetLanguageName",
  "translation": "English translation of your response",
  "correction": "Correction of the user's message (null if no errors)",
  "feedback": "Brief feedback on their language use",
  "grammar_score": 85,
  "vocabulary_score": 75,
  "fluency_score": 80,
  "suggested_responses": ["suggestion 1 in $targetLanguageName", "suggestion 2", "suggestion 3"]
}

IMPORTANT: Always respond with valid JSON only. No markdown, no extra text.''';
  }

  /// Builds the system prompt for generating the opening message.
  String _buildOpeningPrompt({
    required String targetLanguageName,
    required String nativeLanguage,
    required CoachScenario scenario,
  }) {
    return '''You are a friendly language conversation coach for a dating app.
You are starting a "$targetLanguageName" practice session with the scenario: "${scenario.displayName}".
The user's native language is $nativeLanguage.

Generate an opening message as if you are the conversation partner in this scenario.
Speak in $targetLanguageName. Keep it natural and welcoming.

RESPONSE FORMAT (JSON):
{
  "response": "Your opening message in $targetLanguageName",
  "translation": "English translation of your opening message",
  "correction": null,
  "feedback": "Welcome! ${scenario.startingPrompt}",
  "grammar_score": null,
  "vocabulary_score": null,
  "fluency_score": null,
  "suggested_responses": ["suggestion 1 in $targetLanguageName", "suggestion 2", "suggestion 3"]
}

IMPORTANT: Always respond with valid JSON only. No markdown, no extra text.''';
  }

  /// Sends a message to Gemini and returns a parsed [CoachMessage].
  ///
  /// [conversationHistory] is the list of previous messages for context.
  /// [userMessage] is the latest message from the user.
  Future<CoachMessage> sendMessage({
    required String userMessage,
    required String targetLanguageName,
    required String nativeLanguage,
    required CoachScenario scenario,
    required List<CoachMessage> conversationHistory,
  }) async {
    try {
      final apiKey = await _getApiKey();
      final url = '$_geminiBaseUrl?key=$apiKey';

      final systemPrompt = _buildSystemPrompt(
        targetLanguageName: targetLanguageName,
        nativeLanguage: nativeLanguage,
        scenario: scenario,
      );

      // Build conversation context
      final contents = <Map<String, dynamic>>[];

      // Add system instruction as the first user turn
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                '{"response": "Understood. I will act as your conversation partner and provide feedback in the specified JSON format.", "translation": null, "correction": null, "feedback": null, "grammar_score": null, "vocabulary_score": null, "fluency_score": null, "suggested_responses": []}'
          }
        ],
      });

      // Add conversation history
      for (final msg in conversationHistory) {
        contents.add({
          'role': msg.isUserMessage ? 'user' : 'model',
          'parts': [
            {'text': msg.content}
          ],
        });
      }

      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      });

      final response = await _dio.post(
        url,
        data: {
          'contents': contents,
          'generationConfig': {
            'temperature': 0.8,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parseGeminiResponse(response.data);
    } catch (e) {
      return _buildFallbackResponse(userMessage);
    }
  }

  /// Generates the opening message for a new coach session.
  Future<CoachMessage> generateOpeningMessage({
    required String targetLanguageName,
    required String nativeLanguage,
    required CoachScenario scenario,
  }) async {
    try {
      final apiKey = await _getApiKey();
      final url = '$_geminiBaseUrl?key=$apiKey';

      final openingPrompt = _buildOpeningPrompt(
        targetLanguageName: targetLanguageName,
        nativeLanguage: nativeLanguage,
        scenario: scenario,
      );

      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': openingPrompt}
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topP': 0.95,
            'maxOutputTokens': 512,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parseGeminiResponse(response.data);
    } catch (e) {
      return _buildFallbackOpeningMessage(scenario);
    }
  }

  /// Generates a session score based on the conversation history.
  Future<CoachSessionScore> generateSessionScore({
    required List<CoachMessage> messages,
    required String targetLanguageName,
  }) async {
    try {
      final apiKey = await _getApiKey();
      final url = '$_geminiBaseUrl?key=$apiKey';

      // Collect user messages for scoring
      final userMessages =
          messages.where((m) => m.isUserMessage).map((m) => m.content).toList();

      if (userMessages.isEmpty) {
        return _buildDefaultScore();
      }

      final scoringPrompt = '''Analyze these $targetLanguageName conversation messages from a language learner and provide a final score.

USER MESSAGES:
${userMessages.map((m) => '- "$m"').join('\n')}

Provide a final assessment in this JSON format:
{
  "grammar_accuracy": 75,
  "vocabulary_usage": 80,
  "fluency": 70,
  "overall_score": 75,
  "strengths": ["Good use of greetings", "Natural sentence structure"],
  "areas_to_improve": ["Verb conjugation", "Use of articles"]
}

Scores should be 0-100. Provide 2-4 strengths and 2-4 areas to improve.
IMPORTANT: Always respond with valid JSON only. No markdown, no extra text.''';

      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': scoringPrompt}
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 512,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parseScoreResponse(response.data);
    } catch (e) {
      return _buildDefaultScore();
    }
  }

  /// Parses the Gemini API response into a [CoachMessage].
  CoachMessage _parseGeminiResponse(dynamic responseData) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return _buildFallbackResponse('');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return _buildFallbackResponse('');
      }

      final text = parts[0]['text'] as String;

      // Try to parse as JSON — strip markdown code fences if present
      String cleanText = text.trim();
      if (cleanText.startsWith('```')) {
        cleanText = cleanText
            .replaceFirst(RegExp(r'^```json?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final json = jsonDecode(cleanText) as Map<String, dynamic>;

      return CoachMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: json['response'] as String? ?? text,
        translation: json['translation'] as String?,
        isUserMessage: false,
        timestamp: DateTime.now(),
        correction: json['correction'] as String?,
        feedback: json['feedback'] as String?,
        suggestedResponses: (json['suggested_responses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
    } catch (e) {
      // If JSON parsing fails, use the raw text as the response
      try {
        final candidates = responseData['candidates'] as List<dynamic>?;
        final text =
            candidates?[0]['content']['parts'][0]['text'] as String? ?? '';
        return CoachMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          isUserMessage: false,
          timestamp: DateTime.now(),
        );
      } catch (_) {
        return _buildFallbackResponse('');
      }
    }
  }

  /// Parses the Gemini API response into a [CoachSessionScore].
  CoachSessionScore _parseScoreResponse(dynamic responseData) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return _buildDefaultScore();
      }

      final text =
          candidates[0]['content']['parts'][0]['text'] as String;

      // Strip markdown code fences if present
      String cleanText = text.trim();
      if (cleanText.startsWith('```')) {
        cleanText = cleanText
            .replaceFirst(RegExp(r'^```json?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final json = jsonDecode(cleanText) as Map<String, dynamic>;

      final grammarAccuracy =
          (json['grammar_accuracy'] as num?)?.toDouble() ?? 70.0;
      final vocabularyUsage =
          (json['vocabulary_usage'] as num?)?.toDouble() ?? 70.0;
      final fluency = (json['fluency'] as num?)?.toDouble() ?? 70.0;
      final overallScore =
          (json['overall_score'] as num?)?.toDouble() ?? 70.0;

      final strengths = (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Good effort!'];

      final areasToImprove = (json['areas_to_improve'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Keep practicing!'];

      return CoachSessionScore(
        grammarAccuracy: grammarAccuracy.clamp(0, 100),
        vocabularyUsage: vocabularyUsage.clamp(0, 100),
        fluency: fluency.clamp(0, 100),
        overallScore: overallScore.clamp(0, 100),
        strengths: strengths,
        areasToImprove: areasToImprove,
      );
    } catch (e) {
      return _buildDefaultScore();
    }
  }

  /// Builds a fallback response when the API call fails.
  CoachMessage _buildFallbackResponse(String userMessage) {
    return CoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'I understand what you said. Let me respond...',
      translation:
          'Sorry, I had trouble processing that. Please try again.',
      isUserMessage: false,
      timestamp: DateTime.now(),
      feedback:
          'There was a temporary issue. Your message was received. Please try again.',
      suggestedResponses: [
        'Can you repeat that?',
        'Let\'s try a different topic.',
      ],
    );
  }

  /// Builds a fallback opening message when the API call fails.
  CoachMessage _buildFallbackOpeningMessage(CoachScenario scenario) {
    return CoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: scenario.startingPrompt,
      translation: scenario.startingPrompt,
      isUserMessage: false,
      timestamp: DateTime.now(),
      feedback:
          'Welcome to the ${scenario.displayName} practice! Type your first message to begin.',
      suggestedResponses: _getDefaultSuggestionsForScenario(scenario),
    );
  }

  /// Returns default suggested responses for a given scenario.
  List<String> _getDefaultSuggestionsForScenario(CoachScenario scenario) {
    switch (scenario) {
      case CoachScenario.firstDate:
        return ['Hi, nice to meet you!', 'This place is lovely.', 'How was your day?'];
      case CoachScenario.gettingToKnow:
        return ['Tell me about yourself.', 'Where are you from?', 'What do you do?'];
      case CoachScenario.videoCallPrep:
        return ['Can you see me okay?', 'Hi! Great to finally see you!', 'How are you?'];
      case CoachScenario.askingOut:
        return ['Would you like to meet up?', 'Are you free this weekend?', 'I know a great place.'];
      case CoachScenario.complimenting:
        return ['You have a great smile.', 'I love your style.', 'You seem really interesting.'];
      case CoachScenario.discussingInterests:
        return ['What are your hobbies?', 'Do you like music?', 'I enjoy traveling.'];
      case CoachScenario.travelPlanning:
        return ['Where would you like to go?', 'Have you been to...?', 'I love the beach.'];
      case CoachScenario.casualChat:
        return ['How was your day?', 'What are you up to?', 'Have you seen anything good lately?'];
    }
  }

  /// Builds a default score for when API scoring fails.
  CoachSessionScore _buildDefaultScore() {
    return const CoachSessionScore(
      grammarAccuracy: 70,
      vocabularyUsage: 70,
      fluency: 70,
      overallScore: 70,
      strengths: ['Good effort!', 'Keep practicing to improve.'],
      areasToImprove: ['Try using more varied vocabulary.', 'Practice verb conjugation.'],
    );
  }

  /// Converts a numeric score (0-100) to an A-F grade.
  static String scoreToGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Returns a color-appropriate description for a grade.
  static String gradeDescription(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Needs Improvement';
      case 'F':
        return 'Keep Practicing';
      default:
        return 'Unknown';
    }
  }
}
