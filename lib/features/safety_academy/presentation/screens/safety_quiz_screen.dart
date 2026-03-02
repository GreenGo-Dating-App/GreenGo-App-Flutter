import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/safety_lesson.dart';
import '../../domain/entities/safety_quiz.dart';

/// Quiz screen for safety lessons.
///
/// Presents one question at a time with multiple choice answers,
/// immediate correct/incorrect feedback with explanations,
/// and a summary screen showing pass/fail with retry option.
class SafetyQuizScreen extends StatefulWidget {
  final String userId;
  final SafetyLesson lesson;
  final SafetyQuiz quiz;
  final void Function(int score) onComplete;

  const SafetyQuizScreen({
    super.key,
    required this.userId,
    required this.lesson,
    required this.quiz,
    required this.onComplete,
  });

  @override
  State<SafetyQuizScreen> createState() => _SafetyQuizScreenState();
}

class _SafetyQuizScreenState extends State<SafetyQuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  int _correctAnswers = 0;
  bool _quizFinished = false;

  List<QuizQuestion> get _questions => widget.quiz.questions;

  QuizQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  int get _scorePercentage =>
      _questions.isEmpty ? 0 : (_correctAnswers * 100 ~/ _questions.length);

  bool get _passed => _scorePercentage >= widget.quiz.passingScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          widget.lesson.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => _showExitConfirmation(context),
        ),
      ),
      body: _quizFinished ? _buildResultScreen() : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$_correctAnswers correct',
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundInput,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.richGold,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Question text
          Text(
            _currentQuestion.question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: _currentQuestion.options.length,
              itemBuilder: (context, index) {
                return _buildOptionTile(index);
              },
            ),
          ),

          // Explanation (shown after answering)
          if (_hasAnswered) ...[
            _buildExplanation(),
            const SizedBox(height: 16),
          ],

          // Next / Finish button
          if (_hasAnswered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == _currentQuestion.correctIndex;

    Color borderColor = AppColors.divider;
    Color? backgroundColor;
    Color textColor = AppColors.textPrimary;

    if (_hasAnswered) {
      if (isCorrect) {
        borderColor = AppColors.successGreen;
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        textColor = AppColors.successGreen;
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.errorRed;
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.1);
        textColor = AppColors.errorRed;
      }
    } else if (isSelected) {
      borderColor = AppColors.richGold;
      backgroundColor = AppColors.richGold.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: _hasAnswered ? null : () => _selectOption(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hasAnswered
                      ? (isCorrect
                          ? AppColors.successGreen
                          : isSelected
                              ? AppColors.errorRed
                              : AppColors.divider)
                      : (isSelected ? AppColors.richGold : AppColors.divider),
                  width: 2,
                ),
              ),
              child: _hasAnswered && isCorrect
                  ? const Icon(Icons.check,
                      size: 16, color: AppColors.successGreen)
                  : _hasAnswered && isSelected && !isCorrect
                      ? const Icon(Icons.close,
                          size: 16, color: AppColors.errorRed)
                      : isSelected && !_hasAnswered
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.richGold,
                              ),
                            )
                          : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentQuestion.options[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    final isCorrect =
        _selectedOptionIndex == _currentQuestion.correctIndex;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppColors.successGreen : AppColors.warningAmber)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isCorrect ? AppColors.successGreen : AppColors.warningAmber)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Correct!' : 'Not quite.',
            style: TextStyle(
              color:
                  isCorrect ? AppColors.successGreen : AppColors.warningAmber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentQuestion.explanation,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon
            Icon(
              _passed ? Icons.emoji_events : Icons.refresh,
              color: _passed ? AppColors.richGold : AppColors.warningAmber,
              size: 64,
            ),
            const SizedBox(height: 20),

            // Result title
            Text(
              _passed ? 'Great Job!' : 'Keep Learning!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Score
            Text(
              '$_scorePercentage%',
              style: TextStyle(
                color: _passed ? AppColors.successGreen : AppColors.errorRed,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_correctAnswers out of ${_questions.length} correct',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Passing score: ${widget.quiz.passingScore}%',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (_passed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onComplete(_scorePercentage);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Complete Lesson (+${widget.lesson.xpReward} XP)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retryQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Review Lesson',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
      if (index == _currentQuestion.correctIndex) {
        _correctAnswers++;
      }
    });
  }

  void _goToNext() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  void _retryQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _hasAnswered = false;
      _correctAnswers = 0;
      _quizFinished = false;
    });
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
