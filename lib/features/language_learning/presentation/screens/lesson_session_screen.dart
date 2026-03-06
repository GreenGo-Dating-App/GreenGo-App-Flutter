import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/services/pronunciation_service.dart';
import '../../domain/entities/lesson_question.dart';
import '../bloc/language_learning_bloc.dart';

/// Self-contained lesson session driven by flat Firestore `lessons` collection.
///
/// Takes language pair + unit/lesson identifiers.  Dispatches
/// [LoadLessonQuestions] on init, renders each question with type-specific UI,
/// and dispatches [CompleteLessonEvent] on finish.
class LessonSessionScreen extends StatefulWidget {
  final String languageSource;
  final String languageTarget;
  final int unit;
  final int lesson;
  final String? galaxyNodeId;

  const LessonSessionScreen({
    super.key,
    required this.languageSource,
    required this.languageTarget,
    required this.unit,
    required this.lesson,
    this.galaxyNodeId,
  });

  @override
  State<LessonSessionScreen> createState() => _LessonSessionScreenState();
}

class _LessonSessionScreenState extends State<LessonSessionScreen>
    with TickerProviderStateMixin {
  // ── Constants ──
  static const _gold = Color(0xFFD4AF37);
  static const _bgDark = Color(0xFF0A0A0A);
  static const _cardBg = Color(0xFF1A1A2E);

  // ── State ──
  bool _showIntro = true; // show teacher intro before questions
  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _completed = false;

  // Per-question state (reset on advance)
  String? _selectedAnswer;
  bool _answered = false;
  String _textInput = '';
  final _textController = TextEditingController();
  List<String> _reorderedWords = [];
  List<String> _availableWords = [];
  Map<String, String> _matchedPairs = {};
  String? _selectedMatchLeft;
  bool _hintExpanded = false;
  bool _passageRevealed = false; // for listening comprehension

  // TTS — Google Cloud Neural2 with device TTS fallback
  late FlutterTts _tts;
  bool _isSpeaking = false;
  bool _ttsReady = false;
  final _ttsPlayer = AudioPlayer();

  // Animations
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _completionCtrl;
  late Animation<double> _completionAnim;
  late AnimationController _xpCountCtrl;
  late Animation<double> _xpCountAnim;
  late AnimationController _starCtrl;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Completion animations
    _completionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _completionAnim = CurvedAnimation(
      parent: _completionCtrl,
      curve: Curves.easeOutBack,
    );
    _xpCountCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _xpCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpCountCtrl, curve: Curves.easeOut),
    );
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Load questions
    context.read<LanguageLearningBloc>().add(LoadLessonQuestions(
          langSource: widget.languageSource,
          langTarget: widget.languageTarget,
          unit: widget.unit,
          lesson: widget.lesson,
        ));
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      final ttsLang = _ttsLocale(widget.languageTarget);
      await _tts.setLanguage(ttsLang);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;

          });
        }
      });
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      // Set up neural audio player completion handler
      _ttsPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      _ttsReady = true;
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _completionCtrl.dispose();
    _xpCountCtrl.dispose();
    _starCtrl.dispose();
    _textController.dispose();
    _tts.stop();
    _ttsPlayer.dispose();
    super.dispose();
  }

  /// Build a gold-highlighted tappable word span.
  /// Tap = TTS (target language words only), Long-press = translation tooltip.
  WidgetSpan _buildGoldWord(String word, String hintText) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Builder(builder: (ctx) {
        return GestureDetector(
          onTap: () {
            if (_isTargetLanguage(word)) {
              _speak(word);
            }
          },
          onLongPress: hintText.isNotEmpty
              ? () => _showTranslationTooltip(ctx, word, hintText)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border(
                bottom: BorderSide(color: _gold, width: 2),
              ),
            ),
            child: Text(
              word,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── @/# Parser — builds InlineSpans ──
  List<InlineSpan> _parseQuestion(String text, List<String> quickHints) {
    final spans = <InlineSpan>[];
    int hintIdx = 0;
    // Match @word, # slot, or "quoted text"
    final regex = RegExp(r'@(\w+)|#|"([^"]+)"');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
        ));
      }

      if (match.group(0)!.startsWith('@')) {
        // @word marker
        final word = match.group(1)!;
        final hintText =
            hintIdx < quickHints.length ? quickHints[hintIdx] : word;
        hintIdx++;
        spans.add(_buildGoldWord(word, hintText));
      } else if (match.group(0)!.startsWith('"')) {
        // "quoted text" — highlight as gold tappable word
        final quoted = match.group(2)!;
        final hintText =
            hintIdx < quickHints.length ? quickHints[hintIdx] : '';
        if (hintText.isNotEmpty) hintIdx++;
        spans.add(_buildGoldWord(quoted, hintText));
      } else {
        // # slot
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            width: 80,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _answered
                      ? (_selectedAnswer == _currentQuestion?.rightAnswer
                          ? Colors.green
                          : Colors.red)
                      : _gold,
                  width: 2,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _answered ? (_selectedAnswer ?? '___') : '___',
              style: TextStyle(
                color: _answered
                    ? (_selectedAnswer == _currentQuestion?.rightAnswer
                        ? Colors.green
                        : Colors.red)
                    : _gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
      ));
    }

    return spans;
  }

  LessonQuestion? get _currentQuestion {
    final qs = context.read<LanguageLearningBloc>().state.currentQuestions;
    if (_currentIndex < qs.length) return qs[_currentIndex];
    return null;
  }

  // ── TTS helpers ──
  /// Speak text using Google Translate neural TTS (human-like voice).
  /// Falls back to device TTS if network is unavailable.
  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    if (_isSpeaking) {
      await _ttsPlayer.stop();
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() {
      _isSpeaking = true;
    });
    // Try neural TTS via Google Translate endpoint
    if (await _speakNeural(text)) return;
    // Fallback to device TTS
    await _tts.speak(text);
  }

  /// Use Google Cloud TTS Neural2 voices via PronunciationService.
  /// Returns true if successful. Audio is cached in Firebase Storage.
  Future<bool> _speakNeural(String text) async {
    try {
      final langName = _languageName(widget.languageTarget).toLowerCase();
      final url = await PronunciationService()
          .getPronunciationUrl(text, langName);
      if (url == null) return false;
      await _ttsPlayer.play(UrlSource(url));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Small speaker icon button that plays TTS for the given text.
  Widget _ttsButton(String text, {double size = 20}) {
    return GestureDetector(
      onTap: () => _speak(text),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          _isSpeaking ? Icons.stop_circle : Icons.volume_up,
          color: Colors.cyan.withOpacity(0.8),
          size: size,
        ),
      ),
    );
  }

  // ── Answer handling ──
  void _selectOption(String option, String correct) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    final isCorrect =
        option.toLowerCase().trim() == correct.toLowerCase().trim();
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (isCorrect) _correctAnswers++;
    });
    try {
      AppSoundService().play(
          isCorrect ? AppSound.correctAnswer : AppSound.wrongAnswer);
    } catch (_) {}
  }

  void _submitText(String input, String correct) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    final isCorrect =
        input.trim().toLowerCase() == correct.trim().toLowerCase();
    setState(() {
      _selectedAnswer = input.trim();
      _answered = true;
      if (isCorrect) _correctAnswers++;
    });
    try {
      AppSoundService().play(
          isCorrect ? AppSound.correctAnswer : AppSound.wrongAnswer);
    } catch (_) {}
  }

  void _submitFreeResponse() {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedAnswer = _textController.text.trim();
      _answered = true;
      // Free response always counts as correct (no single right answer)
      _correctAnswers++;
    });
    try {
      AppSoundService().play(AppSound.correctAnswer);
    } catch (_) {}
  }

  void _submitMatching(bool allCorrect) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedAnswer = allCorrect ? 'correct' : 'incorrect';
      _answered = true;
      if (allCorrect) _correctAnswers++;
    });
    try {
      AppSoundService().play(
          allCorrect ? AppSound.correctAnswer : AppSound.wrongAnswer);
    } catch (_) {}
  }

  void _submitReorder(String sentence, String correct) {
    _submitText(sentence, correct);
  }

  void _advance() {
    final qs = context.read<LanguageLearningBloc>().state.currentQuestions;
    if (_currentIndex + 1 >= qs.length) {
      setState(() {
        _completed = true;
      });
      _onComplete();
      // Trigger completion animations
      _completionCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _starCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _xpCountCtrl.forward();
      });
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
      _textInput = '';
      _textController.clear();
      _reorderedWords = [];
      _availableWords = [];
      _matchedPairs = {};
      _selectedMatchLeft = null;
      _hintExpanded = false;
      _passageRevealed = false;
    });
  }

  void _onComplete() {
    final qs = context.read<LanguageLearningBloc>().state.currentQuestions;
    final accuracy = qs.isEmpty ? 0.0 : _correctAnswers / qs.length;
    final stars = accuracy >= 0.9 ? 3 : (accuracy >= 0.7 ? 2 : 1);
    final xp = (_correctAnswers * 10) + (stars * 5);

    // Dispatch completion
    final lessonId =
        '${widget.languageSource}_${widget.languageTarget}_u${widget.unit}_l${widget.lesson}';
    context.read<LanguageLearningBloc>().add(CompleteLessonEvent(
          lessonId: lessonId,
          languageCode: widget.languageTarget,
          earnedXp: xp,
          accuracy: accuracy,
        ));

    if (widget.galaxyNodeId != null) {
      context.read<LanguageLearningBloc>().add(SaveLessonStars(
            lessonId: widget.galaxyNodeId!,
            stars: stars,
            languageCode: widget.languageTarget,
          ));
    }

    try {
      AppSoundService().play(AppSound.lessonComplete);
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
        buildWhen: (p, c) =>
            p.currentQuestions != c.currentQuestions ||
            p.isQuestionsLoading != c.isQuestionsLoading,
        builder: (context, state) {
          if (state.isQuestionsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final questions = state.currentQuestions;
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, color: _gold, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No questions available yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back',
                        style: TextStyle(color: _gold, fontSize: 16)),
                  ),
                ],
              ),
            );
          }

          if (_completed) return _buildCompletion(questions);
          if (_showIntro) return _buildLessonIntro(questions);

          final q = questions[_currentIndex];
          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(questions.length),
                _buildProgressBar(questions.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQuestion(q),
                      ],
                    ),
                  ),
                ),
                if (_answered) _buildNextBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── App bar ──
  Widget _buildAppBar(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Unit ${widget.unit} · Lesson ${widget.lesson}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1}/$total',
              style: const TextStyle(
                  color: _gold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: total > 0 ? (_currentIndex + (_answered ? 1 : 0)) / total : 0,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(_gold),
          minHeight: 6,
        ),
      ),
    );
  }

  // ── Next button bar ──
  Widget _buildNextBar() {
    final isCorrect = _selectedAnswer != null &&
        _currentQuestion != null &&
        (_selectedAnswer!.toLowerCase().trim() ==
                _currentQuestion!.rightAnswer.toLowerCase().trim() ||
            _currentQuestion!.questionType == 'free_response' ||
            _selectedAnswer == 'correct');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08),
        border: Border(
          top: BorderSide(
            color: isCorrect
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Not quite',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // TTS for correct answer
              if (_currentQuestion != null &&
                  _currentQuestion!.rightAnswer.isNotEmpty &&
                  _currentQuestion!.questionType != 'matching')
                _ttsButton(_currentQuestion!.rightAnswer),
            ],
          ),
          if (!isCorrect && _currentQuestion != null) ...[
            const SizedBox(height: 6),
            Text(
              'Answer: ${_currentQuestion!.rightAnswer}',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _advance,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? Colors.green : _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUESTION ROUTER
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildQuestion(LessonQuestion q) {
    final quickHints =
        q.quickHint.isNotEmpty ? q.quickHint.split('|') : <String>[];

    // For reading/listening comprehension, use special layout
    if (q.questionType == 'reading_comprehension') {
      return _buildReadingComprehension(q);
    }
    if (q.questionType == 'listening_comprehension') {
      return _buildListeningComprehension(q);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type badge
        _buildTypeBadge(q.questionType),
        const SizedBox(height: 16),

        // Question text with @/# encoding + TTS button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                      children: _parseQuestion(q.question, quickHints)),
                ),
              ),
              // TTS for question text (English content)
              if (_hasEnglishContent(q.question))
                _ttsButton(_extractEnglishText(q.question)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Hint toggle
        if (q.hint.isNotEmpty) ...[
          _buildHintCard(q.hint),
          const SizedBox(height: 16),
        ],

        // Type-specific UI
        _buildExerciseUI(q),
      ],
    );
  }

  /// Check if text likely contains English content worth speaking.
  bool _hasEnglishContent(String text) {
    // Heuristic: if text contains quoted English or common English words
    return text.contains('"') ||
        text.contains('English') ||
        text.contains('Translate');
  }

  /// Extract English text from a question for TTS.
  String _extractEnglishText(String text) {
    // Try to extract quoted text first
    final quoted = RegExp(r'"([^"]+)"').firstMatch(text);
    if (quoted != null) return quoted.group(1)!;
    // Strip @word markers for TTS
    return text.replaceAll(RegExp(r'@(\w+)'), r'$1');
  }

  Widget _buildTypeBadge(String type) {
    final label = type.replaceAll('_', ' ');
    Color badgeColor;
    IconData icon;
    switch (type) {
      case 'multiple_choice':
        badgeColor = Colors.blue;
        icon = Icons.list;
      case 'fill_in_blank':
        badgeColor = Colors.teal;
        icon = Icons.edit;
      case 'translation':
        badgeColor = Colors.purple;
        icon = Icons.translate;
      case 'listening':
        badgeColor = Colors.cyan;
        icon = Icons.headphones;
      case 'speaking':
        badgeColor = Colors.orange;
        icon = Icons.mic;
      case 'matching':
        badgeColor = Colors.pink;
        icon = Icons.compare_arrows;
      case 'reorder_words':
        badgeColor = Colors.amber;
        icon = Icons.sort;
      case 'true_false':
        badgeColor = Colors.indigo;
        icon = Icons.check_circle_outline;
      case 'conversation_choice':
        badgeColor = Colors.deepPurple;
        icon = Icons.chat_bubble_outline;
      case 'free_response':
        badgeColor = Colors.green;
        icon = Icons.edit_note;
      case 'reading_comprehension':
        badgeColor = Colors.amber;
        icon = Icons.menu_book;
      case 'listening_comprehension':
        badgeColor = Colors.deepOrange;
        icon = Icons.hearing;
      default:
        badgeColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintCard(String hint) {
    return GestureDetector(
      onTap: () => setState(() => _hintExpanded = !_hintExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: _gold.withOpacity(0.7), size: 18),
                const SizedBox(width: 6),
                Text('Hint',
                    style: TextStyle(
                        color: _gold.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(
                  _hintExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _gold.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            if (_hintExpanded) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TYPE DISPATCHERS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildExerciseUI(LessonQuestion q) {
    switch (q.questionType) {
      case 'multiple_choice':
        return _buildMultipleChoice(q);
      case 'fill_in_blank':
        return _buildFillInBlank(q);
      case 'translation':
        return _buildTranslation(q);
      case 'listening':
        return _buildListening(q);
      case 'speaking':
        return _buildSpeaking(q);
      case 'matching':
        return _buildMatching(q);
      case 'reorder_words':
        return _buildReorderWords(q);
      case 'true_false':
        return _buildTrueFalse(q);
      case 'conversation_choice':
        return _buildConversationChoice(q);
      case 'free_response':
        return _buildFreeResponse(q);
      default:
        return Text('Unknown type: ${q.questionType}',
            style: const TextStyle(color: Colors.red));
    }
  }

  // ── 1. MULTIPLE CHOICE ──
  Widget _buildMultipleChoice(LessonQuestion q) {
    final options = q.answers.split('|');
    return Column(
      children: options.asMap().entries.map((e) {
        final label = String.fromCharCode(65 + e.key);
        return _optionButton(e.value, label, q.rightAnswer);
      }).toList(),
    );
  }

  Widget _optionButton(String option, String label, String correct) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option.trim().toLowerCase() == correct.trim().toLowerCase();
    final showResult = _answered;

    Color border = Colors.white.withOpacity(0.15);
    Color bg = const Color(0xFF1A1A1A);
    Color labelC = Colors.white.withOpacity(0.5);

    if (showResult) {
      if (isCorrect) {
        border = Colors.green;
        bg = Colors.green.withOpacity(0.1);
        labelC = Colors.green;
      } else if (isSelected) {
        border = Colors.red;
        bg = Colors.red.withOpacity(0.1);
        labelC = Colors.red;
      }
    } else if (isSelected) {
      border = _gold;
      bg = _gold.withOpacity(0.1);
      labelC = _gold;
    }

    return GestureDetector(
      onTap: _answered ? null : () => _selectOption(option, correct),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: labelC.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: labelC,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option,
                  style: TextStyle(
                    color: showResult && isCorrect
                        ? Colors.green
                        : showResult && isSelected
                            ? Colors.red
                            : Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  )),
            ),
            // Mini TTS for English options
            if (_isTargetLanguage(option))
              GestureDetector(
                onTap: () => _speak(option),
                child: Icon(Icons.volume_up,
                    color: Colors.cyan.withOpacity(0.5), size: 18),
              ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
            if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Colors.red, size: 22),
          ],
        ),
      ),
    );
  }

  /// Common words/patterns per language code — used to detect source language
  /// text so we can avoid playing TTS for words the user already knows.
  static const _sourceLanguagePatterns = <String, List<String>>{
    'IT': [
      'Come ', 'Quale ', 'Sto ', 'Di ', 'E ', 'Non ', 'Mi ', 'Puoi ',
      'Forte ', 'Rispondere', 'Ci ', 'Grazie', 'Prego', 'Scusa', 'Forse',
      'Buon', 'Il ', 'La ', 'Lo ', 'Un ', 'Una ', 'Che ', 'Per ',
    ],
    'ES': [
      'Cómo ', 'Qué ', 'Cuál ', 'De ', 'El ', 'La ', 'Los ', 'Las ',
      'Un ', 'Una ', 'No ', 'Por ', 'Para ', 'Gracias', 'Hola', 'Bueno',
      'Está ', 'Es ', 'Me ', 'Te ', 'Se ',
    ],
    'FR': [
      'Comment ', 'Quel ', 'Le ', 'La ', 'Les ', 'Un ', 'Une ', 'Des ',
      'De ', 'Du ', 'Ne ', 'Pas ', 'Est ', 'Merci', 'Bonjour', 'Oui',
      'Je ', 'Tu ', 'Il ', 'Elle ', 'Nous ', 'Vous ',
    ],
    'DE': [
      'Wie ', 'Was ', 'Der ', 'Die ', 'Das ', 'Ein ', 'Eine ', 'Ist ',
      'Nicht ', 'Danke', 'Bitte', 'Gut ', 'Ja ', 'Nein ',
      'Ich ', 'Du ', 'Er ', 'Sie ', 'Wir ',
    ],
    'PT': [
      'Como ', 'Qual ', 'O ', 'A ', 'Os ', 'As ', 'Um ', 'Uma ',
      'De ', 'Do ', 'Da ', 'Não ', 'Obrigado', 'Olá', 'Bom ',
      'Eu ', 'Você ', 'Ele ', 'Ela ',
    ],
  };

  /// Returns true if [text] is likely in the target language (the one the
  /// user is learning) rather than the source language (the user's native
  /// language). TTS and speaker icons should only appear for target-language
  /// words — we never read source-language words back to a native speaker.
  bool _isTargetLanguage(String text) {
    if (text.isEmpty) return false;
    // Numbers are language-neutral — skip
    if (RegExp(r'^\d+$').hasMatch(text)) return false;
    // Check if text starts with a pattern from the user's source language
    final patterns = _sourceLanguagePatterns[widget.languageSource];
    if (patterns != null) {
      for (final p in patterns) {
        if (text.startsWith(p) ||
            text.toLowerCase().startsWith(p.toLowerCase())) {
          return false;
        }
      }
    }
    return true;
  }

  // ── 2. FILL IN BLANK ──
  Widget _buildFillInBlank(LessonQuestion q) {
    final options = q.answers.split('|').where((s) => s.trim().isNotEmpty).toList();

    // No chip options → fall back to text input
    if (options.isEmpty) {
      return Column(
        children: [
          if (!_answered) ...[
            _buildTextInput('Type your answer...'),
            const SizedBox(height: 12),
            _buildSubmitBtn(
              enabled: _textInput.trim().isNotEmpty,
              onPressed: () => _submitText(_textController.text, q.rightAnswer),
            ),
          ] else
            _buildAnswerFeedback(q),
        ],
      );
    }

    return Column(
      children: [
        // Chip bank
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = _selectedAnswer == opt;
            return GestureDetector(
              onTap: _answered ? null : () => _selectOption(opt, q.rightAnswer),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _gold.withOpacity(0.15)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _answered
                        ? (opt.trim().toLowerCase() ==
                                q.rightAnswer.trim().toLowerCase()
                            ? Colors.green
                            : isSelected
                                ? Colors.red
                                : Colors.white.withOpacity(0.15))
                        : isSelected
                            ? _gold
                            : Colors.white.withOpacity(0.15),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(opt,
                    style: TextStyle(
                      color: _answered
                          ? (opt.trim().toLowerCase() ==
                                  q.rightAnswer.trim().toLowerCase()
                              ? Colors.green
                              : isSelected
                                  ? Colors.red
                                  : Colors.white)
                          : Colors.white,
                      fontSize: 16,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 3. TRANSLATION ──
  Widget _buildTranslation(LessonQuestion q) {
    return Column(
      children: [
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
              Text('Translate this phrase',
                  style: TextStyle(
                      color: Colors.purple.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_answered) ...[
          _buildTextInput('Type your translation...'),
          const SizedBox(height: 12),
          _buildSubmitBtn(
            enabled: _textInput.trim().isNotEmpty,
            onPressed: () => _submitText(_textController.text, q.rightAnswer),
          ),
        ] else
          _buildAnswerFeedback(q),
      ],
    );
  }

  // ── 4. LISTENING ──
  Widget _buildListening(LessonQuestion q) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _speak(q.rightAnswer),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSpeaking
                    ? _gold
                    : _gold.withOpacity(0.15 + 0.1 * _pulseAnim.value),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(
                        _isSpeaking ? 0.4 : 0.1 * _pulseAnim.value),
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
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (!_answered) ...[
          _buildTextInput('Type what you heard...'),
          const SizedBox(height: 12),
          _buildSubmitBtn(
            enabled: _textInput.trim().isNotEmpty,
            onPressed: () => _submitText(_textController.text, q.rightAnswer),
          ),
        ] else
          _buildAnswerFeedback(q),
      ],
    );
  }

  // ── 5. SPEAKING ──
  Widget _buildSpeaking(LessonQuestion q) {
    return Column(
      children: [
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
              Text('Type your answer below',
                  style: TextStyle(
                      color: Colors.orange.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_answered) ...[
          _buildTextInput('Type the sentence...'),
          const SizedBox(height: 12),
          _buildSubmitBtn(
            enabled: _textInput.trim().isNotEmpty,
            onPressed: () => _submitText(_textController.text, q.rightAnswer),
          ),
        ] else
          _buildAnswerFeedback(q),
      ],
    );
  }

  // ── 6. MATCHING ──
  Widget _buildMatching(LessonQuestion q) {
    // answers format: "Left:Right|Left:Right|..."
    final pairs = q.answers.split('|').map((p) {
      final parts = p.split(':');
      return (left: parts[0].trim(), right: parts.length > 1 ? parts[1].trim() : parts[0].trim());
    }).toList();

    final leftItems = pairs.map((p) => p.left).toList();
    // Shuffle right items once per question
    if (_availableWords.isEmpty && !_answered) {
      _availableWords = pairs.map((p) => p.right).toList()..shuffle();
    }
    final rightItems = _answered
        ? pairs.map((p) => p.right).toList()
        : _availableWords;

    final allMatched = _matchedPairs.length == pairs.length;

    if (allMatched && !_answered) {
      bool allCorrect = true;
      for (final pair in pairs) {
        if (_matchedPairs[pair.left] != pair.right) {
          allCorrect = false;
          break;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitMatching(allCorrect);
      });
    }

    return Column(
      children: [
        Text('Tap items to match them',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: leftItems.map((item) {
                  final isMatched = _matchedPairs.containsKey(item);
                  final isSel = _selectedMatchLeft == item;
                  return GestureDetector(
                    onTap: (!isMatched && !_answered)
                        ? () => setState(() => _selectedMatchLeft = item)
                        : null,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? Colors.green.withOpacity(0.1)
                            : isSel
                                ? _gold.withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMatched
                              ? Colors.green.withOpacity(0.5)
                              : isSel
                                  ? _gold
                                  : Colors.white.withOpacity(0.15),
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Text(item,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isMatched
                                ? Colors.green
                                : isSel
                                    ? _gold
                                    : Colors.white,
                            fontSize: 15,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal,
                          )),
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
                    onTap: (!isMatched &&
                            _selectedMatchLeft != null &&
                            !_answered)
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(item,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      isMatched ? Colors.green : Colors.white,
                                  fontSize: 15,
                                )),
                          ),
                          if (_isTargetLanguage(item))
                            GestureDetector(
                              onTap: () => _speak(item),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.volume_up,
                                    color: Colors.cyan.withOpacity(0.4),
                                    size: 16),
                              ),
                            ),
                        ],
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

  // ── 7. REORDER WORDS ──
  Widget _buildReorderWords(LessonQuestion q) {
    if (_availableWords.isEmpty && _reorderedWords.isEmpty && !_answered) {
      final words = q.answers.split('|');
      words.shuffle();
      _availableWords = words;
    }

    return Column(
      children: [
        // Answer area
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _answered
                ? (_selectedAnswer?.toLowerCase().trim() ==
                        q.rightAnswer.toLowerCase().trim()
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1))
                : _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _answered
                  ? (_selectedAnswer?.toLowerCase().trim() ==
                          q.rightAnswer.toLowerCase().trim()
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5))
                  : _gold.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: _reorderedWords.isEmpty && !_answered
              ? Center(
                  child: Text('Tap words below to build the sentence',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 14)))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reorderedWords.asMap().entries.map((e) {
                    return GestureDetector(
                      onTap: !_answered
                          ? () {
                              setState(() {
                                _availableWords
                                    .add(_reorderedWords.removeAt(e.key));
                              });
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _answered
                              ? (_selectedAnswer?.toLowerCase().trim() ==
                                      q.rightAnswer.toLowerCase().trim()
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2))
                              : _gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _answered
                                ? (_selectedAnswer?.toLowerCase().trim() ==
                                        q.rightAnswer.toLowerCase().trim()
                                    ? Colors.green
                                    : Colors.red)
                                : _gold.withOpacity(0.5),
                          ),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                              color: _answered
                                  ? (_selectedAnswer?.toLowerCase().trim() ==
                                          q.rightAnswer.toLowerCase().trim()
                                      ? Colors.green
                                      : Colors.red)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Available chips
        if (!_answered)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableWords.asMap().entries.map((e) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _reorderedWords.add(_availableWords.removeAt(e.key));
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
                  child: Text(e.value,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              );
            }).toList(),
          ),

        if (!_answered && _reorderedWords.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSubmitBtn(
            enabled: _availableWords.isEmpty,
            onPressed: () =>
                _submitReorder(_reorderedWords.join(' '), q.rightAnswer),
            label: 'Check',
          ),
        ],

        if (_answered &&
            _selectedAnswer?.toLowerCase().trim() !=
                q.rightAnswer.toLowerCase().trim()) ...[
          const SizedBox(height: 12),
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
                  child: Text('Correct: ${q.rightAnswer}',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── 8. TRUE / FALSE ──
  Widget _buildTrueFalse(LessonQuestion q) {
    return Row(
      children: [
        Expanded(
          child: _tfButton('True', Icons.check_circle_outline, Colors.green, q),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _tfButton('False', Icons.cancel_outlined, Colors.red, q),
        ),
      ],
    );
  }

  Widget _tfButton(
      String label, IconData icon, Color color, LessonQuestion q) {
    final isSelected = _selectedAnswer == label;
    final isCorrect = label.trim().toLowerCase() == q.rightAnswer.trim().toLowerCase();

    Color bg = const Color(0xFF1A1A1A);
    Color border = Colors.white.withOpacity(0.15);

    if (_answered) {
      if (isCorrect) {
        bg = Colors.green.withOpacity(0.15);
        border = Colors.green;
      } else if (isSelected) {
        bg = Colors.red.withOpacity(0.15);
        border = Colors.red;
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _selectOption(label, q.rightAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              _answered && isCorrect
                  ? Icons.check_circle
                  : _answered && isSelected && !isCorrect
                      ? Icons.cancel
                      : icon,
              color: _answered && isCorrect
                  ? Colors.green
                  : _answered && isSelected && !isCorrect
                      ? Colors.red
                      : color.withOpacity(0.7),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  color: _answered && isCorrect
                      ? Colors.green
                      : _answered && isSelected
                          ? Colors.red
                          : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  // ── 9. CONVERSATION CHOICE ──
  Widget _buildConversationChoice(LessonQuestion q) {
    final options = q.answers.split('|');
    // Extract speaker text from question (everything after the last colon/quote)
    final speakerMatch = RegExp(r'"([^"]+)"').firstMatch(q.question);
    final speakerText = speakerMatch?.group(1) ?? '';

    return Column(
      children: [
        if (speakerText.isNotEmpty)
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(speakerText,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, height: 1.4)),
                ),
                _ttsButton(speakerText),
              ],
            ),
          ),
        ...options.asMap().entries.map((e) {
          return _optionButton(
              e.value, String.fromCharCode(65 + e.key), q.rightAnswer);
        }),
      ],
    );
  }

  // ── 10. FREE RESPONSE ──
  Widget _buildFreeResponse(LessonQuestion q) {
    return Column(
      children: [
        if (!_answered) ...[
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 4,
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
            onChanged: (v) => setState(() => _textInput = v),
          ),
          const SizedBox(height: 12),
          _buildSubmitBtn(
            enabled: _textInput.trim().isNotEmpty,
            onPressed: _submitFreeResponse,
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Response recorded',
                    style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── 11. READING COMPREHENSION ──
  Widget _buildReadingComprehension(LessonQuestion q) {
    // question format: "PASSAGE: ...\n\nQUESTION: ..."
    final parts = q.question.split('\n\nQUESTION: ');
    final passage = parts[0].replaceFirst('PASSAGE: ', '');
    final questionText = parts.length > 1 ? parts[1] : 'Answer the question:';
    final options = q.answers.split('|');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeBadge('reading_comprehension'),
        const SizedBox(height: 16),

        // Passage card with gold border
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.4), width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book,
                        color: _gold.withOpacity(0.7), size: 18),
                    const SizedBox(width: 8),
                    Text('Read the passage',
                        style: TextStyle(
                            color: _gold.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    // TTS for passage
                    _ttsButton(passage, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  passage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Hint
        if (q.hint.isNotEmpty) ...[
          _buildHintCard(q.hint),
          const SizedBox(height: 16),
        ],

        // Multiple choice answers
        ...options.asMap().entries.map((e) {
          final label = String.fromCharCode(65 + e.key);
          return _optionButton(e.value, label, q.rightAnswer);
        }),
      ],
    );
  }

  // ── 12. LISTENING COMPREHENSION ──
  Widget _buildListeningComprehension(LessonQuestion q) {
    // question format: "PASSAGE: ...\n\nQUESTION: ..."
    final parts = q.question.split('\n\nQUESTION: ');
    final passage = parts[0].replaceFirst('PASSAGE: ', '');
    final questionText = parts.length > 1 ? parts[1] : 'Answer the question:';
    final options = q.answers.split('|');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeBadge('listening_comprehension'),
        const SizedBox(height: 16),

        // Large speaker button for passage
        Center(
          child: GestureDetector(
            onTap: () => _speak(passage),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSpeaking
                      ? Colors.deepOrange
                      : Colors.deepOrange
                          .withOpacity(0.15 + 0.1 * _pulseAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(
                          _isSpeaking ? 0.4 : 0.1 * _pulseAnim.value),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSpeaking ? Icons.stop : Icons.hearing,
                      color: _isSpeaking ? Colors.white : Colors.deepOrange,
                      size: 36,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSpeaking ? 'Stop' : 'Listen',
                      style: TextStyle(
                        color: _isSpeaking
                            ? Colors.white
                            : Colors.deepOrange.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _isSpeaking
                ? 'Listening...'
                : 'Tap to hear the passage',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ),

        // Reveal passage button (after answering)
        if (_answered || _passageRevealed) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.deepOrange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility,
                        color: Colors.deepOrange, size: 16),
                    const SizedBox(width: 6),
                    Text('Passage (revealed)',
                        style: TextStyle(
                            color: Colors.deepOrange.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  passage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _passageRevealed = true),
              icon: Icon(Icons.visibility_off,
                  color: Colors.white.withOpacity(0.4), size: 16),
              label: Text('Show passage text',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.deepOrange.withOpacity(0.2)),
          ),
          child: Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Hint
        if (q.hint.isNotEmpty) ...[
          _buildHintCard(q.hint),
          const SizedBox(height: 16),
        ],

        // Multiple choice answers
        ...options.asMap().entries.map((e) {
          final label = String.fromCharCode(65 + e.key);
          return _optionButton(e.value, label, q.rightAnswer);
        }),
      ],
    );
  }

  // ── Shared helpers ──
  Widget _buildTextInput(String hint) {
    return TextField(
      controller: _textController,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
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
      onChanged: (v) => setState(() => _textInput = v),
    );
  }

  Widget _buildSubmitBtn({
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
          disabledBackgroundColor: _gold.withOpacity(0.3),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAnswerFeedback(LessonQuestion q) {
    final correct = q.rightAnswer;
    final isCorrect = _selectedAnswer?.toLowerCase().trim() ==
        correct.toLowerCase().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct!' : 'Your answer: $_selectedAnswer',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // TTS for correct answer
              _ttsButton(correct),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 6),
            Text('Correct answer: $correct',
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Explanation section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generateExplanation(q),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Generate a contextual explanation for why the correct answer is right.
  String _generateExplanation(LessonQuestion q) {
    final correct = q.rightAnswer;
    final src = widget.languageSource;
    final tgt = widget.languageTarget;
    final srcName = _languageName(src);
    final tgtName = _languageName(tgt);

    // Extract the source-language word from the question if available
    final wordMatch = RegExp(r'"([^"]+)"|@(\w+)').firstMatch(q.question);
    final highlightedWord = wordMatch != null
        ? (wordMatch.group(1) ?? wordMatch.group(2) ?? '')
        : '';

    // Use quickHint if available for translation context
    final hint = q.quickHint.isNotEmpty ? q.quickHint.split('|').first : '';

    switch (q.questionType) {
      case 'multiple_choice':
        if (highlightedWord.isNotEmpty && hint.isNotEmpty) {
          return '"$highlightedWord" means "$hint" in $tgtName. '
              'The correct answer is "$correct".';
        }
        return 'The correct answer is "$correct". '
            'Remember this for next time!';

      case 'fill_in_blank':
        return 'The missing word is "$correct". '
            'Try to remember this phrase as a whole.';

      case 'translation':
        if (highlightedWord.isNotEmpty) {
          return '"$highlightedWord" translates to "$correct" in $tgtName.';
        }
        return 'The correct translation is "$correct".';

      case 'listening':
        return 'The spoken text was "$correct". '
            'Tap the speaker icon to hear it again.';

      case 'speaking':
        return 'The correct way to say this in $tgtName is "$correct".';

      case 'matching':
        return 'Each word in $srcName has a specific $tgtName '
            'translation. Review the pairs to memorize them.';

      case 'reorder_words':
        return 'The correct word order is: "$correct". '
            'Word order matters in $tgtName!';

      case 'true_false':
        return 'The statement is $correct. '
            '${hint.isNotEmpty ? 'Remember: "$highlightedWord" = "$hint".' : ''}';

      case 'conversation_choice':
        return '"$correct" is the most natural response in this '
            'conversation context.';

      case 'free_response':
        return 'A correct response would be: "$correct". '
            'There may be other valid answers too.';

      case 'reading_comprehension':
      case 'listening_comprehension':
        return 'Based on the passage, the correct answer is "$correct". '
            'Try re-reading/listening to find the key detail.';

      default:
        return 'The correct answer is "$correct".';
    }
  }

  /// Map language code to readable name.
  String _languageName(String code) {
    const names = {
      'IT': 'Italian',
      'EN': 'English',
      'ES': 'Spanish',
      'FR': 'French',
      'DE': 'German',
      'PT': 'Portuguese',
      'JA': 'Japanese',
      'KO': 'Korean',
      'AR': 'Arabic',
      'RU': 'Russian',
      'NL': 'Dutch',
      'PL': 'Polish',
    };
    return names[code] ?? code;
  }

  /// Map language code to TTS locale string.
  String _ttsLocale(String code) {
    const locales = {
      'IT': 'it-IT',
      'EN': 'en-US',
      'ES': 'es-ES',
      'FR': 'fr-FR',
      'DE': 'de-DE',
      'PT': 'pt-BR',
      'JA': 'ja-JP',
      'KO': 'ko-KR',
      'AR': 'ar-SA',
      'RU': 'ru-RU',
      'NL': 'nl-NL',
      'PL': 'pl-PL',
    };
    return locales[code] ?? 'en-US';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LESSON INTRO — Teacher explains what you'll learn
  // ───────────────────────────────────────────────────────────────────────────

  /// Extract vocabulary pairs from question data for the intro screen.
  /// Returns list of (source, target) tuples.
  List<({String source, String target})> _extractVocabulary(
      List<LessonQuestion> questions) {
    final vocab = <({String source, String target})>[];
    final seen = <String>{};

    for (final q in questions) {
      // From matching questions: "Italian:English|..."
      if (q.questionType == 'matching') {
        for (final pair in q.answers.split('|')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim().toLowerCase();
            if (!seen.contains(key)) {
              seen.add(key);
              vocab.add((source: parts[0].trim(), target: parts[1].trim()));
            }
          }
        }
      }
      // From questions with @word and quickHint
      if (q.quickHint.isNotEmpty && q.question.contains('@')) {
        final words = RegExp(r'@(\w+)').allMatches(q.question);
        final hints = q.quickHint.split('|');
        int i = 0;
        for (final m in words) {
          final word = m.group(1)!;
          final key = word.toLowerCase();
          if (!seen.contains(key) && i < hints.length) {
            seen.add(key);
            vocab.add((source: word, target: hints[i]));
          }
          i++;
        }
      }
      // From translation questions
      if (q.questionType == 'translation' && q.rightAnswer.isNotEmpty) {
        final qText = q.question
            .replaceFirst(RegExp(r'^Traduc[a-z]*:\s*'), '')
            .replaceAll('@', '')
            .replaceAll('"', '')
            .trim();
        if (qText.isNotEmpty && !seen.contains(qText.toLowerCase())) {
          seen.add(qText.toLowerCase());
          vocab.add((source: qText, target: q.rightAnswer));
        }
      }
    }
    return vocab;
  }

  /// Lesson title mapping for intro
  static const _lessonIntros = {
    1: 'Hello & Goodbye',
    2: 'How Are You?',
    3: 'My Name Is...',
    4: 'Numbers 1-10',
    5: 'Please & Thank You',
    6: 'Yes, No, Maybe',
    7: 'Common Questions',
  };

  Widget _buildLessonIntro(List<LessonQuestion> questions) {
    final vocab = _extractVocabulary(questions);
    final lessonTitle =
        _lessonIntros[widget.lesson] ?? 'Lesson ${widget.lesson}';
    final sourceLabel = _languageName(widget.languageSource);
    final targetLabel = _languageName(widget.languageTarget);

    return SafeArea(
      child: Column(
        children: [
          // App bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher greeting
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school,
                            color: _gold, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lesson title
                  Center(
                    child: Text(
                      lessonTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Unit ${widget.unit} · Lesson ${widget.lesson}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Teacher speech
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold.withOpacity(0.2)),
                    ),
                    child: Text(
                      _getIntroSpeech(widget.lesson),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vocabulary section header
                  if (vocab.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.menu_book, color: _gold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.languageSource == 'IT'
                                ? 'Parole e Frasi'
                                : 'Words & Phrases',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.languageSource == 'IT'
                              ? 'Tieni premuto per tradurre'
                              : 'Long-press for translation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sourceLabel,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              targetLabel,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vocabulary rows
                    ...vocab.map((v) => _buildVocabRow(v.source, v.target)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${questions.length} questions in this lesson',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showIntro = false);
                  try {
                    AppSoundService().play(AppSound.quizStart);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                    widget.languageSource == 'IT'
                        ? 'Iniziamo!'
                        : "Let's Start!",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabRow(String source, String target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Source word (Italian)
          Expanded(
            child: Text(
              source,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, color: _gold, size: 16),
          const SizedBox(width: 8),
          // Target word (English) — long-press for reverse translation
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                _showTranslationTooltip(context, target, source);
              },
              onTap: () => _speak(target),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        target,
                        style: TextStyle(
                          color: _gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.volume_up,
                        color: Colors.cyan.withOpacity(0.6), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a floating tooltip with the translation of a word.
  void _showTranslationTooltip(
      BuildContext ctx, String word, String translation) {
    final overlay = Overlay.of(ctx);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: () => entry.remove(),
        behavior: HitTestBehavior.translucent,
        child: Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.2),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.swap_vert,
                      color: Colors.white.withOpacity(0.5), size: 20),
                  const SizedBox(height: 8),
                  Text(
                    translation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  /// Teacher intro speech per lesson, localized to user's language.
  String _getIntroSpeech(int lesson) {
    final isItalian = widget.languageSource == 'IT';
    if (isItalian) return _getIntroSpeechIT(lesson);
    return _getIntroSpeechEN(lesson);
  }

  String _getIntroSpeechEN(int lesson) {
    switch (lesson) {
      case 1:
        return "Today we'll learn how to greet people and say goodbye! "
            "These are the most important words you'll use every day. "
            "Tap any word to hear its pronunciation, or long-press for the translation.";
      case 2:
        return "Let's learn how to ask and answer 'How are you?' "
            "You'll be able to have a basic conversation after this lesson.";
      case 3:
        return "Time to learn how to introduce yourself! "
            "You'll learn to say your name and ask others theirs.";
      case 4:
        return "Numbers are essential! Let's count from 1 to 10. "
            "Pay attention to spelling — some numbers are tricky!";
      case 5:
        return "Being polite opens doors! Let's learn 'please', 'thank you', "
            "and other courtesy phrases.";
      case 6:
        return "Yes, no, maybe — these small words are powerful! "
            "Let's learn how to agree, disagree, and express uncertainty.";
      case 7:
        return "Questions help you navigate the world! "
            "Let's learn the most common questions you'll need.";
      default:
        return "Let's learn some new words and phrases! "
            "Review the vocabulary below, then we'll practice together.";
    }
  }

  String _getIntroSpeechIT(int lesson) {
    switch (lesson) {
      case 1:
        return "Oggi impariamo a salutare e dire addio in inglese! "
            "Queste sono le parole che userai ogni giorno. "
            "Tocca una parola per ascoltare la pronuncia, tieni premuto per la traduzione.";
      case 2:
        return "Impariamo a chiedere e rispondere 'Come stai?' in inglese! "
            "Dopo questa lezione potrai fare una conversazione di base.";
      case 3:
        return "E' il momento di imparare a presentarti! "
            "Imparerai a dire il tuo nome e a chiedere quello degli altri.";
      case 4:
        return "I numeri sono fondamentali! Contiamo da 1 a 10 in inglese. "
            "Fai attenzione all'ortografia — alcuni numeri inglesi sono complicati!";
      case 5:
        return "Essere educati apre le porte! Impariamo 'please', 'thank you' "
            "e altre frasi di cortesia in inglese.";
      case 6:
        return "Si, no, forse — queste piccole parole sono potenti! "
            "Impariamo ad esprimere accordo, disaccordo e incertezza in inglese.";
      case 7:
        return "Le domande ti aiutano a orientarti nel mondo! "
            "Impariamo le domande piu' comuni di cui avrai bisogno in inglese.";
      default:
        return "Impariamo nuove parole e frasi! "
            "Rivedi il vocabolario qui sotto, poi ci esercitiamo insieme.";
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COMPLETION SCREEN — Animated Splash
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCompletion(List<LessonQuestion> questions) {
    final total = questions.length;
    final accuracy = total > 0 ? _correctAnswers / total : 0.0;
    final stars = accuracy >= 0.9 ? 3 : (accuracy >= 0.7 ? 2 : 1);
    final xp = (_correctAnswers * 10) + (stars * 5);

    return SafeArea(
      child: Stack(
        children: [
          // Celebration Lottie background
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/celebration.json',
              fit: BoxFit.cover,
              repeat: false,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: _bgDark.withOpacity(0.85),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Stars
                  AnimatedBuilder(
                    animation: _starCtrl,
                    builder: (_, __) {
                      final progress = _starCtrl.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final starProgress =
                              ((progress - i * 0.25) / 0.5).clamp(0.0, 1.0);
                          final scale = i < stars
                              ? Curves.elasticOut.transform(starProgress)
                              : 0.5;
                          return Transform.scale(
                            scale: scale,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                color: i < stars
                                    ? _gold
                                    : Colors.white.withOpacity(0.3),
                                size: i == 1 ? 56 : 44,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title
                  ScaleTransition(
                    scale: _completionAnim,
                    child: const Text(
                      'Lesson Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats card slides up
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(_completionAnim),
                    child: FadeTransition(
                      opacity: _completionAnim,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _gold.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _statRow(Icons.check_circle, Colors.green,
                                'Correct', '$_correctAnswers / $total'),
                            const SizedBox(height: 12),
                            _statRow(
                                Icons.percent,
                                Colors.blue,
                                'Accuracy',
                                '${(accuracy * 100).toStringAsFixed(0)}%'),
                            const SizedBox(height: 12),
                            // Animated XP counter
                            AnimatedBuilder(
                              animation: _xpCountAnim,
                              builder: (_, __) {
                                final animXp =
                                    (_xpCountAnim.value * xp).round();
                                return _statRow(
                                    Icons.bolt, _gold, 'XP Earned', '+$animXp');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pulsing Continue button
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4 + 4 * _pulseAnim.value,
                          shadowColor: _gold.withOpacity(0.4),
                        ),
                        child: const Text('Continue',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 15)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
