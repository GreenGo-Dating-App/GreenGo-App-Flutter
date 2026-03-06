import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../coins/domain/entities/coin_reward.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../domain/entities/lesson.dart';
import '../bloc/language_learning_bloc.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  /// Galaxy map node ID (e.g. 'u0_n0') — if set, also marks this node as
  /// completed when the lesson finishes.
  final String? galaxyNodeId;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    this.galaxyNodeId,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with TickerProviderStateMixin {
  // Navigation state
  int _currentSectionIndex = 0;
  int _currentContentIndex = 0;
  bool _showingExercise = false;
  int _currentExerciseIndex = 0;
  int _correctAnswers = 0;

  // Exercise answer state
  String? _selectedAnswer;
  bool _showExplanation = false;
  String _textInputAnswer = '';
  final TextEditingController _textController = TextEditingController();

  // Hint toggle state
  bool _hintExpanded = false;

  // Capitalization warning state
  bool _showCapWarning = false;
  String? _correctCapitalization;

  // Fill-in-blank state
  String _fillBlankAnswer = '';
  final TextEditingController _fillBlankController = TextEditingController();

  // Reorder words state
  List<String> _reorderedWords = [];
  List<String> _availableWords = [];

  // Matching state
  Map<String, String> _matchedPairs = {};
  String? _selectedMatchLeft;

  // TTS
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsInitialized = false;

  // Animations
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _correctController;
  late Animation<double> _correctAnimation;

  static const _gold = Color(0xFFD4AF37);
  static const _bgDark = Color(0xFF0A0A0A);
  static const _cardBg = Color(0xFF1A1A2E);
  static const _cardBg2 = Color(0xFF2D2D44);

  @override
  void initState() {
    super.initState();
    _initTts();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _correctController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _correctAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _correctController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      // Map language code to TTS locale
      final langCode = widget.lesson.languageCode;
      final ttsLang = _mapToTtsLanguage(langCode);
      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _ttsInitialized = true;
    } catch (_) {
      _ttsInitialized = false;
    }
  }

  String _mapToTtsLanguage(String code) {
    const mapping = {
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-BR',
      'pt_BR': 'pt-BR',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'zh-CN',
      'ar': 'ar-SA',
      'ru': 'ru-RU',
      'hi': 'hi-IN',
      'tr': 'tr-TR',
      'nl': 'nl-NL',
      'pl': 'pl-PL',
      'sv': 'sv-SE',
      'en': 'en-US',
    };
    return mapping[code] ?? '$code-${code.toUpperCase()}';
  }

  Future<void> _speak(String text) async {
    if (!_ttsInitialized) return;
    // Remove placeholder braces if any
    final cleanText = text.replaceAll(RegExp(r'[{}]'), '');
    if (cleanText.isEmpty) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    await _flutterTts.speak(cleanText);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _particleController.dispose();
    _pulseController.dispose();
    _correctController.dispose();
    _textController.dispose();
    _fillBlankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final currentSection = lesson.sections.isNotEmpty
        ? lesson.sections[_currentSectionIndex]
        : null;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Section ${_currentSectionIndex + 1} of ${lesson.sections.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: _gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${lesson.xpReward} XP',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _LessonParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: _calculateProgress(),
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(_gold),
                minHeight: 4,
              ),

              // Content
              Expanded(
                child: currentSection == null
                    ? _buildEmptySection()
                    : _showingExercise
                        ? _buildExerciseView(currentSection)
                        : _buildContentView(currentSection),
              ),

              // Next arrow button
              _buildNextArrowBar(),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    final totalSections = widget.lesson.sections.length;
    if (totalSections == 0) return 0;

    double sectionProgress = _currentSectionIndex / totalSections;
    final section = widget.lesson.sections[_currentSectionIndex];

    if (_showingExercise && section.exercises.isNotEmpty) {
      sectionProgress +=
          (_currentExerciseIndex / section.exercises.length) / totalSections;
    } else if (section.contents.isNotEmpty) {
      sectionProgress +=
          (_currentContentIndex / section.contents.length) / totalSections;
    }

    return sectionProgress.clamp(0.0, 1.0);
  }

  Widget _buildEmptySection() {
    return const Center(
      child: Text(
        'No content available',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTENT VIEW (learning material — text, phrases, dialogues)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContentView(LessonSection section) {
    if (section.contents.isEmpty) {
      return _buildSectionIntro(section);
    }

    final content = section.contents[_currentContentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(section.type.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.type.displayName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        section.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentContentIndex + 1}/${section.contents.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content item with audio button
          _buildContentItem(content),
        ],
      ),
    );
  }

  Widget _buildSectionIntro(LessonSection section) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(section.type.icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              section.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (section.introduction != null) ...[
              const SizedBox(height: 16),
              Text(
                section.introduction!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startExercises,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Practice',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(LessonContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji for vocabulary nouns
        if (content.imageEmoji != null && content.imageEmoji!.isNotEmpty) ...[
          Center(child: Text(content.imageEmoji!, style: const TextStyle(fontSize: 48))),
          const SizedBox(height: 8),
        ],
        // Main text with audio button
        if (content.text != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_cardBg, _cardBg2]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        content.text!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // TTS audio button
                    _buildAudioButton(content.text!),
                  ],
                ),
                if (content.pronunciation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.record_voice_over,
                          color: Colors.white.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        content.pronunciation!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

        // Translation
        if (content.translation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.translate,
                    color: Colors.white.withOpacity(0.5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.translation!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Compact audio/TTS button
  Widget _buildAudioButton(String text) {
    return GestureDetector(
      onTap: () => _speak(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isSpeaking ? _gold : _gold.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: _isSpeaking
              ? [
                  BoxShadow(
                    color: _gold.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Icon(
          _isSpeaking ? Icons.stop : Icons.volume_up,
          color: _isSpeaking ? Colors.black : _gold,
          size: 20,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISE VIEW — Dispatches to 10 different exercise type renderers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildExerciseView(LessonSection section) {
    if (section.exercises.isEmpty) {
      return _buildNoExercises();
    }

    final exercise = section.exercises[_currentExerciseIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise progress header
          _buildExerciseProgressHeader(section),
          const SizedBox(height: 16),

          // Exercise type badge
          _buildExerciseTypeBadge(exercise),
          const SizedBox(height: 16),

          // Question card with audio button
          _buildQuestionCard(exercise),
          const SizedBox(height: 16),

          // Emoji for vocabulary exercises
          if (exercise.imageEmoji != null && exercise.imageEmoji!.isNotEmpty) ...[
            Center(child: Text(exercise.imageEmoji!, style: const TextStyle(fontSize: 48))),
            const SizedBox(height: 12),
          ],

          // Hint toggle button (before answering)
          if (exercise.hint != null && _selectedAnswer == null)
            _buildHintToggle(exercise.hint!),
          if (exercise.hint != null && _selectedAnswer == null)
            const SizedBox(height: 16),

          // Type-specific exercise UI
          _buildExerciseByType(exercise),

          // Capitalization warning (correct answer but wrong case)
          if (_showCapWarning && _correctCapitalization != null) ...[
            const SizedBox(height: 12),
            _buildCapWarningCard(_correctCapitalization!),
          ],

          // Explanation (after answering)
          if (_showExplanation && exercise.explanation != null) ...[
            const SizedBox(height: 20),
            _buildExplanationCard(exercise.explanation!),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseProgressHeader(LessonSection section) {
    return Row(
      children: [
        // Progress dots
        Expanded(
          child: Row(
            children: List.generate(section.exercises.length, (i) {
              final isDone = i < _currentExerciseIndex;
              final isCurrent = i == _currentExerciseIndex;
              return Container(
                width: isCurrent ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green
                      : isCurrent
                          ? _gold
                          : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              '$_correctAnswers',
              style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseTypeBadge(LessonExercise exercise) {
    final typeConfig = _exerciseTypeConfig(exercise.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: typeConfig.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeConfig.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(typeConfig.icon, color: typeConfig.color, size: 14),
          const SizedBox(width: 6),
          Text(
            exercise.type.displayName,
            style: TextStyle(
              color: typeConfig.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(LessonExercise exercise) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_cardBg, _cardBg2]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _gold.withOpacity(0.2 + 0.1 * _pulseAnimation.value),
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.05 + 0.05 * _pulseAnimation.value),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Audio button for the question
                _buildAudioButton(exercise.question),
              ],
            ),
            if (exercise.questionTranslation != null) ...[
              const SizedBox(height: 8),
              Text(
                exercise.questionTranslation!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHintToggle(String hint) {
    return GestureDetector(
      onTap: () => setState(() => _hintExpanded = !_hintExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(_hintExpanded ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hintExpanded ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _hintExpanded ? 'Hint' : 'Need a hint?',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _hintExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
            if (_hintExpanded) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: TextStyle(
                  color: Colors.blue.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapWarningCard(String correctForm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.amber.shade700, fontSize: 14),
                children: [
                  const TextSpan(text: 'Correct! But pay attention to capitalization. The proper form is: '),
                  TextSpan(
                    text: correctForm,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(String explanation) {
    return AnimatedBuilder(
      animation: _correctAnimation,
      builder: (context, _) => Transform.scale(
        scale: 0.95 + 0.05 * _correctAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Explanation',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                explanation,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISE TYPE DISPATCHER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildExerciseByType(LessonExercise exercise) {
    switch (exercise.type) {
      case ExerciseType.multiple_choice:
        return _buildMultipleChoice(exercise);
      case ExerciseType.fill_in_blank:
        return _buildFillInBlank(exercise);
      case ExerciseType.translation:
        return _buildTranslation(exercise);
      case ExerciseType.listening:
        return _buildListening(exercise);
      case ExerciseType.speaking:
        return _buildSpeaking(exercise);
      case ExerciseType.matching:
        return _buildMatching(exercise);
      case ExerciseType.reorder_words:
        return _buildReorderWords(exercise);
      case ExerciseType.true_false:
        return _buildTrueFalse(exercise);
      case ExerciseType.conversation_choice:
        return _buildConversationChoice(exercise);
      case ExerciseType.free_response:
        return _buildFreeResponse(exercise);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. MULTIPLE CHOICE — Select from option buttons
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMultipleChoice(LessonExercise exercise) {
    return Column(
      children: exercise.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return _buildOptionButton(
          option: option,
          label: String.fromCharCode(65 + index), // A, B, C, D
          correctAnswer: exercise.correctAnswer,
          acceptableAnswers: exercise.acceptableAnswers ?? [],
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton({
    required String option,
    required String label,
    required String correctAnswer,
    required List<String> acceptableAnswers,
  }) {
    final isSelected = _selectedAnswer == option;
    final isCorrect =
        option == correctAnswer || acceptableAnswers.contains(option);
    final showResult = _selectedAnswer != null;

    Color borderColor = Colors.white.withOpacity(0.15);
    Color bgColor = const Color(0xFF1A1A1A);
    Color labelColor = Colors.white.withOpacity(0.5);

    if (showResult) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        labelColor = Colors.green;
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        labelColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = _gold;
      bgColor = _gold.withOpacity(0.1);
      labelColor = _gold;
    }

    return GestureDetector(
      onTap: _selectedAnswer == null ? () => _selectOptionAnswer(option, correctAnswer, acceptableAnswers) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: showResult && isCorrect
                      ? Colors.green
                      : showResult && isSelected && !isCorrect
                          ? Colors.red
                          : Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: Colors.green, size: 22)
            else if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Colors.red, size: 22),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. FILL IN THE BLANK — Sentence with ____ + text input
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFillInBlank(LessonExercise exercise) {
    final answered = _selectedAnswer != null;

    return Column(
      children: [
        // Show sentence with blank highlighted
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
              children: _buildBlankSpans(exercise.question, answered, exercise.correctAnswer),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (!answered) ...[
          // Text field for answer
          TextField(
            controller: _fillBlankController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Type the missing word...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _fillBlankAnswer = v),
            onSubmitted: (_) => _submitTextAnswer(
              _fillBlankController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(
            enabled: _fillBlankAnswer.trim().isNotEmpty,
            onPressed: () => _submitTextAnswer(
              _fillBlankController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
        ] else
          _buildAnswerFeedback(exercise.correctAnswer),
      ],
    );
  }

  List<TextSpan> _buildBlankSpans(String question, bool answered, String correctAnswer) {
    // Look for ____ or ___ pattern in the question
    final blankPattern = RegExp(r'_{2,}');
    final match = blankPattern.firstMatch(question);
    if (match == null) {
      return [TextSpan(text: question)];
    }

    final before = question.substring(0, match.start);
    final after = question.substring(match.end);

    return [
      TextSpan(text: before),
      TextSpan(
        text: answered ? ' $correctAnswer ' : ' _____ ',
        style: TextStyle(
          color: answered ? Colors.green : _gold,
          fontWeight: FontWeight.bold,
          decoration: answered ? null : TextDecoration.underline,
          decorationColor: _gold,
        ),
      ),
      TextSpan(text: after),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. TRANSLATION — Show word/phrase, type translation
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTranslation(LessonExercise exercise) {
    final answered = _selectedAnswer != null;

    return Column(
      children: [
        // Direction indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, color: Colors.purple, size: 16),
              const SizedBox(width: 6),
              Text(
                'Translate this phrase',
                style: TextStyle(
                  color: Colors.purple.shade200,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (!answered) ...[
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Type your translation...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _textInputAnswer = v),
            onSubmitted: (_) => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(
            enabled: _textInputAnswer.trim().isNotEmpty,
            onPressed: () => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
        ] else
          _buildAnswerFeedback(exercise.correctAnswer),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. LISTENING — Play audio, then type what you hear
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildListening(LessonExercise exercise) {
    final answered = _selectedAnswer != null;

    return Column(
      children: [
        // Big listen button
        GestureDetector(
          onTap: () => _speak(exercise.correctAnswer),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSpeaking
                    ? _gold
                    : _gold.withOpacity(0.15 + 0.1 * _pulseAnimation.value),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(
                        _isSpeaking ? 0.4 : 0.1 * _pulseAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                _isSpeaking ? Icons.stop : Icons.headphones,
                color: _isSpeaking ? Colors.black : _gold,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSpeaking ? 'Playing...' : 'Tap to listen',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        if (!answered) ...[
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Type what you heard...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _textInputAnswer = v),
            onSubmitted: (_) => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(
            enabled: _textInputAnswer.trim().isNotEmpty,
            onPressed: () => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
        ] else
          _buildAnswerFeedback(exercise.correctAnswer),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. SPEAKING — Describe what you see / read aloud
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSpeaking(LessonExercise exercise) {
    final answered = _selectedAnswer != null;

    return Column(
      children: [
        // Image display if available
        if (exercise.imageUrl != null) ...[
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, color: Colors.white24, size: 48),
                  SizedBox(height: 8),
                  Text('Describe this image',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Microphone icon (visual — we use text input as fallback)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Text(
                'Type your answer below',
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (!answered) ...[
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Type your description...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _textInputAnswer = v),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(
            enabled: _textInputAnswer.trim().isNotEmpty,
            onPressed: () => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
        ] else
          _buildAnswerFeedback(exercise.correctAnswer),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. MATCHING — Two columns, tap to match pairs
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMatching(LessonExercise exercise) {
    // Options format: "word -> translation" pairs
    final pairs = exercise.options.map((o) {
      final parts = o.split(' -> ');
      return (left: parts[0].trim(), right: parts.length > 1 ? parts[1].trim() : parts[0].trim());
    }).toList();

    final leftItems = pairs.map((p) => p.left).toList();
    final rightItems = pairs.map((p) => p.right).toList()..shuffle();

    final allMatched = _matchedPairs.length == pairs.length;

    if (allMatched && _selectedAnswer == null) {
      // Check if all matches are correct
      bool allCorrect = true;
      for (final pair in pairs) {
        if (_matchedPairs[pair.left] != pair.right) {
          allCorrect = false;
          break;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitMatchingAnswer(allCorrect, exercise);
      });
    }

    return Column(
      children: [
        Text(
          'Tap items to match them',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftItems.map((item) {
                  final isMatched = _matchedPairs.containsKey(item);
                  final isSelected = _selectedMatchLeft == item;

                  return GestureDetector(
                    onTap: (!isMatched && _selectedAnswer == null)
                        ? () => setState(() => _selectedMatchLeft = item)
                        : null,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? Colors.green.withOpacity(0.1)
                            : isSelected
                                ? _gold.withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMatched
                              ? Colors.green.withOpacity(0.5)
                              : isSelected
                                  ? _gold
                                  : Colors.white.withOpacity(0.15),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isMatched
                              ? Colors.green
                              : isSelected
                                  ? _gold
                                  : Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            // Right column
            Expanded(
              child: Column(
                children: rightItems.map((item) {
                  final isMatched = _matchedPairs.containsValue(item);

                  return GestureDetector(
                    onTap: (!isMatched && _selectedMatchLeft != null && _selectedAnswer == null)
                        ? () {
                            setState(() {
                              _matchedPairs[_selectedMatchLeft!] = item;
                              _selectedMatchLeft = null;
                            });
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? Colors.green.withOpacity(0.1)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMatched
                              ? Colors.green.withOpacity(0.5)
                              : Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isMatched ? Colors.green : Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. REORDER WORDS — Drag/tap word chips to form correct sentence
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReorderWords(LessonExercise exercise) {
    // Initialize available words on first build
    if (_availableWords.isEmpty && _reorderedWords.isEmpty && _selectedAnswer == null) {
      final words = exercise.options.isNotEmpty
          ? List<String>.from(exercise.options)
          : exercise.correctAnswer.split(' ');
      words.shuffle();
      _availableWords = words;
    }

    final answered = _selectedAnswer != null;

    return Column(
      children: [
        // Answer area (where words are placed)
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: answered
                ? (_selectedAnswer == exercise.correctAnswer
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1))
                : _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: answered
                  ? (_selectedAnswer == exercise.correctAnswer
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5))
                  : _gold.withOpacity(0.3),
              width: 2,
              // Dashed border effect not available in Flutter, use normal
            ),
          ),
          child: _reorderedWords.isEmpty && !answered
              ? Center(
                  child: Text(
                    'Tap words below to build the sentence',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reorderedWords.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: !answered
                          ? () {
                              setState(() {
                                _availableWords.add(_reorderedWords.removeAt(entry.key));
                              });
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: answered
                              ? (_selectedAnswer == exercise.correctAnswer
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2))
                              : _gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: answered
                                ? (_selectedAnswer == exercise.correctAnswer
                                    ? Colors.green
                                    : Colors.red)
                                : _gold.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: answered
                                ? (_selectedAnswer == exercise.correctAnswer
                                    ? Colors.green
                                    : Colors.red)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Available word chips
        if (!answered)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableWords.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _reorderedWords.add(_availableWords.removeAt(entry.key));
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),

        if (!answered && _reorderedWords.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSubmitButton(
            enabled: _availableWords.isEmpty,
            onPressed: () {
              final userSentence = _reorderedWords.join(' ');
              _submitTextAnswer(
                  userSentence, exercise.correctAnswer, exercise.acceptableAnswers);
            },
            label: 'Check',
          ),
        ],

        if (answered) ...[
          const SizedBox(height: 12),
          if (_selectedAnswer != exercise.correctAnswer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct: ${exercise.correctAnswer}',
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. TRUE/FALSE — Two large buttons
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTrueFalse(LessonExercise exercise) {
    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseButton(
            label: 'True',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            exercise: exercise,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrueFalseButton(
            label: 'False',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            exercise: exercise,
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseButton({
    required String label,
    required IconData icon,
    required Color color,
    required LessonExercise exercise,
  }) {
    final isSelected = _selectedAnswer == label;
    final showResult = _selectedAnswer != null;
    final isCorrect = label == exercise.correctAnswer;

    Color bgColor = const Color(0xFF1A1A1A);
    Color borderColor = Colors.white.withOpacity(0.15);

    if (showResult) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
      } else if (isSelected) {
        bgColor = Colors.red.withOpacity(0.15);
        borderColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: _selectedAnswer == null
          ? () => _selectOptionAnswer(label, exercise.correctAnswer, exercise.acceptableAnswers ?? [])
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: (showResult && isCorrect)
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              showResult && isCorrect
                  ? Icons.check_circle
                  : showResult && isSelected && !isCorrect
                      ? Icons.cancel
                      : icon,
              color: showResult && isCorrect
                  ? Colors.green
                  : showResult && isSelected && !isCorrect
                      ? Colors.red
                      : color.withOpacity(0.7),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: showResult && isCorrect
                    ? Colors.green
                    : showResult && isSelected
                        ? Colors.red
                        : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 9. CONVERSATION CHOICE — Dialogue context + response options
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildConversationChoice(LessonExercise exercise) {
    // Show conversation context, then multiple choice response options
    return Column(
      children: [
        // Chat-style conversation bubble
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.indigo, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Other person',
                      style: TextStyle(
                        color: Colors.indigo.shade200,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAudioButton(exercise.question),
            ],
          ),
        ),

        // "Your reply:" label
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Your reply:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Response option buttons
        ...exercise.options.map((option) => _buildOptionButton(
              option: option,
              label: '',
              correctAnswer: exercise.correctAnswer,
              acceptableAnswers: exercise.acceptableAnswers ?? [],
            )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 10. FREE RESPONSE — Open text input, checked against acceptable answers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFreeResponse(LessonExercise exercise) {
    final answered = _selectedAnswer != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, color: Colors.teal, size: 16),
              const SizedBox(width: 6),
              Text(
                'Write your answer freely',
                style: TextStyle(
                  color: Colors.teal.shade200,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (!answered) ...[
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your answer...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _textInputAnswer = v),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(
            enabled: _textInputAnswer.trim().isNotEmpty,
            onPressed: () => _submitTextAnswer(
              _textController.text,
              exercise.correctAnswer,
              exercise.acceptableAnswers,
            ),
          ),
        ] else
          _buildAnswerFeedback(exercise.correctAnswer),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton({
    required bool enabled,
    required VoidCallback onPressed,
    String label = 'Submit',
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withOpacity(0.1),
          disabledForegroundColor: Colors.white30,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildAnswerFeedback(String correctAnswer) {
    final isCorrect = _isCurrentAnswerCorrect(correctAnswer);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct!' : 'Not quite right',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 34),
                Expanded(
                  child: Text(
                    'Answer: $correctAnswer',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Audio for correct answer
                _buildAudioButton(correctAnswer),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoExercises() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No exercises in this section',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEXT ARROW BAR — Prominent next button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNextArrowBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            if (_canGoBack())
              GestureDetector(
                onTap: _goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white70, size: 22),
                ),
              )
            else
              const SizedBox(width: 44),

            const Spacer(),

            // Main next/continue button — big and prominent
            GestureDetector(
              onTap: _canContinue() ? _goNext : null,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) => Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: _canContinue()
                        ? _gold
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: _canContinue()
                        ? [
                            BoxShadow(
                              color: _gold.withOpacity(
                                  0.3 + 0.15 * _pulseAnimation.value),
                              blurRadius: 12 + 6 * _pulseAnimation.value,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLastStep() ? 'Complete' : 'Next',
                        style: TextStyle(
                          color: _canContinue() ? Colors.black : Colors.white30,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isLastStep()
                            ? Icons.check
                            : Icons.arrow_forward_rounded,
                        color: _canContinue() ? Colors.black : Colors.white30,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  bool _canGoBack() {
    return _currentContentIndex > 0 ||
        _currentSectionIndex > 0 ||
        _showingExercise;
  }

  bool _canContinue() {
    if (_showingExercise) {
      return _selectedAnswer != null;
    }
    return true;
  }

  bool _isLastStep() {
    final isLastSection =
        _currentSectionIndex == widget.lesson.sections.length - 1;
    final section = widget.lesson.sections[_currentSectionIndex];
    final isLastExercise =
        _currentExerciseIndex == section.exercises.length - 1;

    return isLastSection &&
        _showingExercise &&
        (section.exercises.isEmpty || isLastExercise);
  }

  void _goBack() {
    setState(() {
      if (_showingExercise && _currentExerciseIndex > 0) {
        _currentExerciseIndex--;
        _resetAnswerState();
      } else if (_showingExercise) {
        _showingExercise = false;
        _currentExerciseIndex = 0;
        final section = widget.lesson.sections[_currentSectionIndex];
        _currentContentIndex =
            section.contents.isNotEmpty ? section.contents.length - 1 : 0;
      } else if (_currentContentIndex > 0) {
        _currentContentIndex--;
      } else if (_currentSectionIndex > 0) {
        _currentSectionIndex--;
        final prevSection = widget.lesson.sections[_currentSectionIndex];
        _currentContentIndex =
            prevSection.contents.isNotEmpty ? prevSection.contents.length - 1 : 0;
      }
    });
  }

  void _goNext() {
    final section = widget.lesson.sections[_currentSectionIndex];

    setState(() {
      if (_showingExercise) {
        if (_currentExerciseIndex < section.exercises.length - 1) {
          _currentExerciseIndex++;
          _resetAnswerState();
        } else if (_currentSectionIndex < widget.lesson.sections.length - 1) {
          _currentSectionIndex++;
          _currentContentIndex = 0;
          _currentExerciseIndex = 0;
          _showingExercise = false;
          _resetAnswerState();
        } else {
          _completeLesson();
        }
      } else if (_currentContentIndex < section.contents.length - 1) {
        _currentContentIndex++;
      } else {
        _startExercises();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _startExercises() {
    setState(() {
      _showingExercise = true;
      _currentExerciseIndex = 0;
      _resetAnswerState();
    });
  }

  void _resetAnswerState() {
    _selectedAnswer = null;
    _showExplanation = false;
    _textInputAnswer = '';
    _fillBlankAnswer = '';
    _textController.clear();
    _fillBlankController.clear();
    _reorderedWords = [];
    _availableWords = [];
    _matchedPairs = {};
    _selectedMatchLeft = null;
    _hintExpanded = false;
    _showCapWarning = false;
    _correctCapitalization = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANSWER SUBMISSION LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  void _selectOptionAnswer(String answer, String correctAnswer, List<String> acceptableAnswers) {
    final isCorrect =
        answer == correctAnswer || acceptableAnswers.contains(answer);

    setState(() {
      _selectedAnswer = answer;
      _showExplanation = true;
      if (isCorrect) {
        _correctAnswers++;
        _correctController.forward(from: 0);
        HapticFeedback.mediumImpact();
        AppSoundService().play(AppSound.correctAnswer);
      } else {
        HapticFeedback.heavyImpact();
        AppSoundService().play(AppSound.wrongAnswer);
      }
    });
  }

  void _submitTextAnswer(
      String answer, String correctAnswer, List<String>? acceptableAnswers) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;

    final isCorrect = trimmed.toLowerCase() == correctAnswer.toLowerCase() ||
        (acceptableAnswers
                ?.any((a) => a.toLowerCase() == trimmed.toLowerCase()) ??
            false);

    // Check for capitalization mismatch (correct content, wrong case)
    bool capWarning = false;
    String? correctCap;
    if (isCorrect && trimmed != correctAnswer) {
      // Find the exact correct form (could be from acceptableAnswers)
      if (trimmed.toLowerCase() == correctAnswer.toLowerCase()) {
        capWarning = true;
        correctCap = correctAnswer;
      } else if (acceptableAnswers != null) {
        for (final alt in acceptableAnswers) {
          if (trimmed.toLowerCase() == alt.toLowerCase() && trimmed != alt) {
            capWarning = true;
            correctCap = alt;
            break;
          }
        }
      }
    }

    setState(() {
      _selectedAnswer = trimmed;
      _showExplanation = true;
      _showCapWarning = capWarning;
      _correctCapitalization = correctCap;
      if (isCorrect) {
        _correctAnswers++;
        _correctController.forward(from: 0);
        HapticFeedback.mediumImpact();
        AppSoundService().play(AppSound.correctAnswer);
      } else {
        HapticFeedback.heavyImpact();
        AppSoundService().play(AppSound.wrongAnswer);
      }
    });
  }

  void _submitMatchingAnswer(bool allCorrect, LessonExercise exercise) {
    setState(() {
      _selectedAnswer = allCorrect ? exercise.correctAnswer : '__wrong__';
      _showExplanation = true;
      if (allCorrect) {
        _correctAnswers++;
        _correctController.forward(from: 0);
        HapticFeedback.mediumImpact();
        AppSoundService().play(AppSound.correctAnswer);
      } else {
        HapticFeedback.heavyImpact();
        AppSoundService().play(AppSound.wrongAnswer);
      }
    });
  }

  bool _isCurrentAnswerCorrect(String correctAnswer) {
    if (_selectedAnswer == null) return false;
    return _selectedAnswer!.toLowerCase() == correctAnswer.toLowerCase();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LESSON COMPLETION
  // ─────────────────────────────────────────────────────────────────────────

  static const double _passThreshold = 0.6;

  void _completeLesson() {
    final totalExercises = widget.lesson.totalExercises;
    final accuracy =
        totalExercises > 0 ? _correctAnswers / totalExercises : 1.0;
    final passed = accuracy >= _passThreshold;

    if (!passed) {
      AppSoundService().play(AppSound.wrongAnswer);
      _showFailedDialog(accuracy, totalExercises);
      return;
    }

    final earnedXp = (widget.lesson.xpReward * accuracy).round();
    AppSoundService().play(AppSound.lessonComplete);

    final bloc = context.read<LanguageLearningBloc>();
    bloc.add(
          CompleteLessonEvent(
            lessonId: widget.lesson.id,
            languageCode: widget.lesson.languageCode,
            earnedXp: earnedXp,
            accuracy: accuracy,
          ),
        );

    // Also mark the galaxy map node as completed if navigated from galaxy map
    if (widget.galaxyNodeId != null) {
      bloc.add(
            CompleteLessonEvent(
              lessonId: widget.galaxyNodeId!,
              languageCode: widget.lesson.languageCode,
              earnedXp: 0, // XP already awarded above
              accuracy: accuracy,
            ),
          );
    }

    if (accuracy >= 0.8 && widget.lesson.bonusCoins > 0) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<CoinBloc>().add(ClaimCoinReward(
              userId: userId,
              reward: CoinReward(
                rewardId: 'lesson_${widget.lesson.id}',
                name: 'Lesson Bonus',
                description: 'Bonus for completing ${widget.lesson.title}',
                coinAmount: widget.lesson.bonusCoins,
                type: RewardType.achievement,
                isRecurring: false,
                maxClaims: 1,
              ),
            ));
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Lesson Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildResultRow('Correct Answers', '$_correctAnswers/$totalExercises'),
            _buildResultRow('Accuracy', '${(accuracy * 100).round()}%'),
            _buildResultRow('XP Earned', '+$earnedXp XP'),
            if (widget.lesson.bonusCoins > 0 && accuracy >= 0.8)
              _buildResultRow('Bonus Coins', '+${widget.lesson.bonusCoins}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailedDialog(double accuracy, int totalExercises) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Not Quite There...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need at least ${(_passThreshold * 100).round()}% to pass this lesson.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildResultRow('Correct Answers', '$_correctAnswers/$totalExercises'),
            _buildResultRow('Your Score', '${(accuracy * 100).round()}%'),
            _buildResultRow('Required', '${(_passThreshold * 100).round()}%'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _retryLesson();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go Back',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryLesson() {
    setState(() {
      _currentSectionIndex = 0;
      _currentContentIndex = 0;
      _showingExercise = false;
      _currentExerciseIndex = 0;
      _correctAnswers = 0;
      _resetAnswerState();
    });
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXERCISE TYPE CONFIG (icons + colors)
  // ─────────────────────────────────────────────────────────────────────────

  _ExerciseTypeConfig _exerciseTypeConfig(ExerciseType type) {
    switch (type) {
      case ExerciseType.multiple_choice:
        return _ExerciseTypeConfig(Icons.list, Colors.blue);
      case ExerciseType.fill_in_blank:
        return _ExerciseTypeConfig(Icons.text_fields, _gold);
      case ExerciseType.translation:
        return _ExerciseTypeConfig(Icons.translate, Colors.purple);
      case ExerciseType.listening:
        return _ExerciseTypeConfig(Icons.headphones, Colors.cyan);
      case ExerciseType.speaking:
        return _ExerciseTypeConfig(Icons.mic, Colors.orange);
      case ExerciseType.matching:
        return _ExerciseTypeConfig(Icons.compare_arrows, Colors.pink);
      case ExerciseType.reorder_words:
        return _ExerciseTypeConfig(Icons.swap_horiz, Colors.amber);
      case ExerciseType.true_false:
        return _ExerciseTypeConfig(Icons.thumbs_up_down, Colors.teal);
      case ExerciseType.conversation_choice:
        return _ExerciseTypeConfig(Icons.chat_bubble, Colors.indigo);
      case ExerciseType.free_response:
        return _ExerciseTypeConfig(Icons.edit_note, Colors.green);
    }
  }
}

class _ExerciseTypeConfig {
  final IconData icon;
  final Color color;
  _ExerciseTypeConfig(this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE PAINTER — Subtle floating particles for lesson ambiance
// ─────────────────────────────────────────────────────────────────────────────

class _LessonParticlePainter extends CustomPainter {
  final double progress;

  _LessonParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 15;
    const seed = 42;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 53) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 321) % 1000) / 1000.0 * size.height;
      final speed = 0.15 + (hash % 100) / 100.0 * 0.3;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 8;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.7 + phase) * 6;
      final opacity =
          (0.03 + 0.03 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        1.2,
        Paint()..color = const Color(0xFFD4AF37).withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LessonParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
