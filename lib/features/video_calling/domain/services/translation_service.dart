import 'dart:async';
// speech_to_text disabled for development
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:translator/translator.dart';

// Stub types for when speech_to_text is disabled
class SpeechToText {
  Future<bool> initialize({Function(String)? onStatus, Function(dynamic)? onError}) async => false;
  Future<List<LocaleName>> locales() async => [];
  Future<void> listen({
    Function(SpeechRecognitionResult)? onResult,
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
    bool? partialResults,
    bool? cancelOnError,
    ListenMode? listenMode,
  }) async {}
  Future<void> stop() async {}
}

class SpeechRecognitionResult {
  final String recognizedWords;
  final bool finalResult;
  const SpeechRecognitionResult({this.recognizedWords = '', this.finalResult = false});
}

class LocaleName {
  final String localeId;
  final String name;
  const LocaleName(this.localeId, this.name);
}

enum ListenMode { dictation }

/// Subtitle data class
class SubtitleData {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isFinal;
  final DateTime timestamp;

  SubtitleData({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isFinal,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Translation Service for real-time video call subtitles
class TranslationService {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator _translator = GoogleTranslator();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isEnabled = true;

  String _sourceLanguage = 'en';
  String _targetLanguage = 'en';

  final _subtitleController = StreamController<SubtitleData>.broadcast();
  Stream<SubtitleData> get subtitleStream => _subtitleController.stream;

  final _statusController = StreamController<TranslationStatus>.broadcast();
  Stream<TranslationStatus> get statusStream => _statusController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;

  /// Initialize the speech-to-text engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );

      if (_isInitialized) {
        _statusController.add(TranslationStatus.ready);
      } else {
        _statusController.add(TranslationStatus.unavailable);
      }

      return _isInitialized;
    } catch (e) {
      _statusController.add(TranslationStatus.error);
      return false;
    }
  }

  /// Set source and target languages
  void setLanguages({required String source, required String target}) {
    _sourceLanguage = source;
    _targetLanguage = target;
  }

  /// Enable/disable translation
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isListening) {
      stopListening();
    }
    _statusController.add(enabled
        ? TranslationStatus.ready
        : TranslationStatus.disabled);
  }

  /// Toggle translation on/off
  void toggleEnabled() {
    setEnabled(!_isEnabled);
  }

  /// Start listening for speech
  Future<bool> startListening() async {
    if (!_isInitialized || !_isEnabled) return false;
    if (_isListening) return true;

    try {
      _isListening = true;
      _statusController.add(TranslationStatus.listening);

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _sourceLanguage,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );

      return true;
    } catch (e) {
      _isListening = false;
      _statusController.add(TranslationStatus.error);
      return false;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
    _statusController.add(TranslationStatus.ready);
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) async {
    if (!_isEnabled || result.recognizedWords.isEmpty) return;

    final originalText = result.recognizedWords;

    // If source and target languages are the same, no translation needed
    if (_sourceLanguage == _targetLanguage) {
      _subtitleController.add(SubtitleData(
        originalText: originalText,
        translatedText: originalText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        isFinal: result.finalResult,
      ));
      return;
    }

    // Translate the text
    try {
      final translation = await _translator.translate(
        originalText,
        from: _sourceLanguage,
        to: _targetLanguage,
      );

      _subtitleController.add(SubtitleData(
        originalText: originalText,
        translatedText: translation.text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        isFinal: result.finalResult,
      ));
    } catch (e) {
      // If translation fails, show original text
      _subtitleController.add(SubtitleData(
        originalText: originalText,
        translatedText: originalText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        isFinal: result.finalResult,
      ));
    }

    // Auto-restart listening if final result and still enabled
    if (result.finalResult && _isEnabled) {
      await Future.delayed(const Duration(milliseconds: 100));
      startListening();
    }
  }

  void _onStatus(String status) {
    if (status == 'done' && _isEnabled) {
      // Restart listening after pause
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isEnabled) startListening();
      });
    }
  }

  void _onError(dynamic error) {
    _statusController.add(TranslationStatus.error);
    // Try to recover
    Future.delayed(const Duration(seconds: 1), () {
      if (_isEnabled) startListening();
    });
  }

  /// Get available languages for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _subtitleController.close();
    _statusController.close();
  }
}

/// Translation service status
enum TranslationStatus {
  initializing,
  ready,
  listening,
  disabled,
  unavailable,
  error,
}

/// Supported language codes mapping
class SupportedLanguages {
  static const Map<String, String> languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'pl': 'Polish',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
    'ro': 'Romanian',
    'hu': 'Hungarian',
    'cs': 'Czech',
    'sk': 'Slovak',
    'uk': 'Ukrainian',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sr': 'Serbian',
    'sl': 'Slovenian',
    'lt': 'Lithuanian',
    'lv': 'Latvian',
    'et': 'Estonian',
  };

  static String getLanguageName(String code) {
    return languages[code] ?? code;
  }

  static List<MapEntry<String, String>> getAllLanguages() {
    return languages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }
}
