import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lesson.dart';
import '../bloc/language_learning_bloc.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int _currentSectionIndex = 0;
  int _currentContentIndex = 0;
  bool _showingExercise = false;
  int _currentExerciseIndex = 0;
  int _correctAnswers = 0;
  String? _selectedAnswer;
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final currentSection = lesson.sections.isNotEmpty
        ? lesson.sections[_currentSectionIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
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
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${lesson.xpReward} XP',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
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

          // Navigation
          _buildNavigationBar(),
        ],
      ),
    );
  }

  double _calculateProgress() {
    final totalSections = widget.lesson.sections.length;
    if (totalSections == 0) return 0;
    return (_currentSectionIndex + 1) / totalSections;
  }

  Widget _buildEmptySection() {
    return const Center(
      child: Text(
        'No content available',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

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
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  section.type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
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

          // Content based on type
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
            Text(
              section.type.icon,
              style: const TextStyle(fontSize: 64),
            ),
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
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Practice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
        // Main text
        if (content.text != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.text!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (content.pronunciation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: Colors.white.withOpacity(0.5),
                        size: 16,
                      ),
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
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.translate,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
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

        // Audio button
        if (content.audioUrl != null) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _playAudio(content.audioUrl!),
              icon: const Icon(Icons.volume_up),
              label: const Text('Listen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

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
          // Exercise progress
          Row(
            children: [
              Text(
                'Question ${_currentExerciseIndex + 1} of ${section.exercises.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctAnswers correct',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.type.displayName,
                  style: TextStyle(
                    color: const Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
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
          const SizedBox(height: 20),

          // Hint
          if (exercise.hint != null && _selectedAnswer == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.hint!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Options
          ...exercise.options.map((option) => _buildOptionButton(
                option,
                exercise.correctAnswer,
                exercise.acceptableAnswers ?? [],
              )),

          // Explanation
          if (_showExplanation && exercise.explanation != null) ...[
            const SizedBox(height: 20),
            Container(
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
                    exercise.explanation!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
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

  Widget _buildOptionButton(
    String option,
    String correctAnswer,
    List<String> acceptableAnswers,
  ) {
    final isSelected = _selectedAnswer == option;
    final isCorrect =
        option == correctAnswer || acceptableAnswers.contains(option);
    final showResult = _selectedAnswer != null;

    Color borderColor = Colors.white.withOpacity(0.2);
    Color bgColor = const Color(0xFF1A1A1A);

    if (showResult) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
      }
    } else if (isSelected) {
      borderColor = const Color(0xFFD4AF37);
      bgColor = const Color(0xFFD4AF37).withOpacity(0.1);
    }

    return GestureDetector(
      onTap: _selectedAnswer == null ? () => _selectAnswer(option) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExercises() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No exercises in this section',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final section = widget.lesson.sections.isNotEmpty
        ? widget.lesson.sections[_currentSectionIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
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
            if (_canGoBack())
              TextButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                label: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              const SizedBox(width: 80),
            const Spacer(),
            ElevatedButton(
              onPressed: _canContinue() ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLastStep() ? 'Complete' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isLastStep() ? Icons.check : Icons.arrow_forward,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final isLastContent = _currentContentIndex == section.contents.length - 1;
    final isLastExercise = _currentExerciseIndex == section.exercises.length - 1;

    return isLastSection &&
        _showingExercise &&
        (section.exercises.isEmpty || isLastExercise);
  }

  void _goBack() {
    setState(() {
      if (_showingExercise && _currentExerciseIndex > 0) {
        _currentExerciseIndex--;
        _selectedAnswer = null;
        _showExplanation = false;
      } else if (_showingExercise) {
        _showingExercise = false;
        _currentExerciseIndex = 0;
        final section = widget.lesson.sections[_currentSectionIndex];
        _currentContentIndex = section.contents.isNotEmpty
            ? section.contents.length - 1
            : 0;
      } else if (_currentContentIndex > 0) {
        _currentContentIndex--;
      } else if (_currentSectionIndex > 0) {
        _currentSectionIndex--;
        final prevSection = widget.lesson.sections[_currentSectionIndex];
        _currentContentIndex = prevSection.contents.isNotEmpty
            ? prevSection.contents.length - 1
            : 0;
      }
    });
  }

  void _goNext() {
    final section = widget.lesson.sections[_currentSectionIndex];

    setState(() {
      if (_showingExercise) {
        if (_currentExerciseIndex < section.exercises.length - 1) {
          _currentExerciseIndex++;
          _selectedAnswer = null;
          _showExplanation = false;
        } else if (_currentSectionIndex < widget.lesson.sections.length - 1) {
          _currentSectionIndex++;
          _currentContentIndex = 0;
          _currentExerciseIndex = 0;
          _showingExercise = false;
          _selectedAnswer = null;
          _showExplanation = false;
        } else {
          _completeLesson();
        }
      } else if (_currentContentIndex < section.contents.length - 1) {
        _currentContentIndex++;
      } else {
        _startExercises();
      }
    });
  }

  void _startExercises() {
    setState(() {
      _showingExercise = true;
      _currentExerciseIndex = 0;
      _selectedAnswer = null;
      _showExplanation = false;
    });
  }

  void _selectAnswer(String answer) {
    final section = widget.lesson.sections[_currentSectionIndex];
    final exercise = section.exercises[_currentExerciseIndex];
    final isCorrect = answer == exercise.correctAnswer ||
        (exercise.acceptableAnswers?.contains(answer) ?? false);

    setState(() {
      _selectedAnswer = answer;
      _showExplanation = true;
      if (isCorrect) {
        _correctAnswers++;
      }
    });
  }

  void _playAudio(String url) {
    // TODO: Implement audio playback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio playback coming soon!'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  void _completeLesson() {
    // Calculate results
    final totalExercises = widget.lesson.totalExercises;
    final accuracy =
        totalExercises > 0 ? _correctAnswers / totalExercises : 1.0;
    final earnedXp = (widget.lesson.xpReward * accuracy).round();

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 64),
            ),
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
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
