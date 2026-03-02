import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/widgets/learning_effects.dart';

/// A gamified quiz widget with animations, sound effects, and visual feedback.
///
/// Used at the end of every learning chapter/module. Supports:
/// - Multiple choice questions
/// - True/False questions
/// - Image-based questions
/// - Timed questions (optional)
/// - Immediate feedback with explanation
/// - Score tracking with XP rewards
/// - Confetti on completion
class GamifiedQuizWidget extends StatefulWidget {
  final String title;
  final List<QuizItem> questions;
  final int xpReward;
  final int passingScore; // Percentage (0-100)
  final VoidCallback? onComplete;
  final Function(int score, int total, bool passed)? onResult;
  final bool showTimer;
  final int timerSeconds; // Per question

  const GamifiedQuizWidget({
    super.key,
    required this.title,
    required this.questions,
    this.xpReward = 25,
    this.passingScore = 70,
    this.onComplete,
    this.onResult,
    this.showTimer = false,
    this.timerSeconds = 30,
  });

  @override
  State<GamifiedQuizWidget> createState() => _GamifiedQuizWidgetState();
}

class _GamifiedQuizWidgetState extends State<GamifiedQuizWidget>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _quizComplete = false;
  bool _showConfetti = false;
  bool _shakeWrong = false;
  final List<bool> _results = [];

  // Timer
  late AnimationController _timerController;
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timerSeconds),
    );

    if (widget.showTimer) {
      _startTimer();
    }

    AppSoundService().play(AppSound.quizStart);
  }

  void _startTimer() {
    _timerController.forward(from: 0).then((_) {
      if (mounted && !_answered) {
        setState(() {
          _timerExpired = true;
          _answered = true;
          _results.add(false);
        });
        AppSoundService().play(AppSound.wrongAnswer);
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    final question = widget.questions[_currentIndex];
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _timerController.stop();
      _results.add(isCorrect);

      if (isCorrect) {
        _correctCount++;
      } else {
        _shakeWrong = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _shakeWrong = false);
        });
      }
    });

    if (isCorrect) {
      AppSoundService().play(AppSound.correctAnswer);
      HapticFeedback.lightImpact();
    } else {
      AppSoundService().play(AppSound.wrongAnswer);
      HapticFeedback.heavyImpact();
    }
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= widget.questions.length) {
      // Quiz complete
      final score =
          (_correctCount / widget.questions.length * 100).round();
      final passed = score >= widget.passingScore;

      setState(() {
        _quizComplete = true;
        if (passed) {
          _showConfetti = true;
        }
      });

      if (passed) {
        AppSoundService().play(AppSound.quizComplete);
      } else {
        AppSoundService().play(AppSound.error);
      }

      widget.onResult?.call(_correctCount, widget.questions.length, passed);
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _timerExpired = false;
      });

      if (widget.showTimer) {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizComplete) {
      return _buildResultScreen();
    }

    final question = widget.questions[_currentIndex];

    return ConfettiOverlay(
      trigger: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: 8),

              // Timer (if enabled)
              if (widget.showTimer) _buildTimer(),

              // Question
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number
                      Text(
                        'Question ${_currentIndex + 1} of ${widget.questions.length}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Question text
                      Text(
                        question.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Question hint
                      if (question.hint != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: AppColors.richGold, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.hint!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Question image
                      if (question.imageUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            question.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Answer options
                      ShakeWidget(
                        trigger: _shakeWrong,
                        child: Column(
                          children: List.generate(
                            question.options.length,
                            (index) => _buildOptionCard(index, question),
                          ),
                        ),
                      ),

                      // Explanation (after answer)
                      if (_answered && question.explanation != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (_selectedAnswer == question.correctIndex)
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  (_selectedAnswer == question.correctIndex)
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    (_selectedAnswer ==
                                            question.correctIndex)
                                        ? Icons.check_circle
                                        : Icons.info_outline,
                                    color: (_selectedAnswer ==
                                            question.correctIndex)
                                        ? Colors.green
                                        : Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (_selectedAnswer ==
                                            question.correctIndex)
                                        ? 'Correct!'
                                        : 'Explanation',
                                    style: TextStyle(
                                      color: (_selectedAnswer ==
                                              question.correctIndex)
                                          ? Colors.green
                                          : Colors.amber,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Next button
              if (_answered)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex + 1 >= widget.questions.length
                            ? 'See Results'
                            : 'Next Question',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          widget.questions.length,
          (index) {
            Color color;
            if (index < _results.length) {
              color = _results[index] ? Colors.green : Colors.red;
            } else if (index == _currentIndex) {
              color = AppColors.richGold;
            } else {
              color = AppColors.divider;
            }
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AnimatedBuilder(
        animation: _timerController,
        builder: (context, _) {
          final remaining =
              (widget.timerSeconds * (1 - _timerController.value)).round();
          final isLow = remaining <= 5;

          return Row(
            children: [
              Icon(
                Icons.timer,
                color: isLow ? Colors.red : AppColors.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${remaining}s',
                style: TextStyle(
                  color: isLow ? Colors.red : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: 1 - _timerController.value,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(
                    isLow ? Colors.red : AppColors.richGold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(int index, QuizItem question) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == question.correctIndex;
    final showResult = _answered;

    Color borderColor = AppColors.divider;
    Color bgColor = AppColors.backgroundCard;
    IconData? trailingIcon;
    Color? iconColor;

    if (showResult) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        trailingIcon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        trailingIcon = Icons.cancel;
        iconColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = AppColors.richGold;
      bgColor = AppColors.richGold.withValues(alpha: 0.1);
    }

    final optionLetter = String.fromCharCode(65 + index); // A, B, C, D

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Option letter circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected && !showResult
                      ? AppColors.richGold
                      : showResult && isCorrect
                          ? Colors.green
                          : showResult && isSelected
                              ? Colors.red
                              : AppColors.backgroundDark,
                ),
                child: Center(
                  child: Text(
                    optionLetter,
                    style: TextStyle(
                      color: (isSelected || (showResult && isCorrect))
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Option text
              Expanded(
                child: Text(
                  question.options[index],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),

              // Result icon
              if (trailingIcon != null)
                Icon(trailingIcon, color: iconColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final score =
        (_correctCount / widget.questions.length * 100).round();
    final passed = score >= widget.passingScore;

    return ConfettiOverlay(
      trigger: _showConfetti,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Result icon
                  Icon(
                    passed ? Icons.emoji_events : Icons.refresh,
                    size: 80,
                    color: passed ? AppColors.richGold : Colors.amber,
                  ),
                  const SizedBox(height: 24),

                  // Result text
                  Text(
                    passed ? 'Quiz Passed!' : 'Keep Practicing!',
                    style: TextStyle(
                      color: passed ? AppColors.richGold : Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Score
                  Text(
                    '$_correctCount / ${widget.questions.length} correct ($score%)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Passing threshold
                  Text(
                    'Passing score: ${widget.passingScore}%',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),

                  // XP earned
                  if (passed) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.richGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.richGold, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.xpReward} XP earned!',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Question results summary
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      _results.length,
                      (index) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _results[index]
                              ? Colors.green
                              : Colors.red,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Action buttons
                  if (!passed)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 0;
                            _correctCount = 0;
                            _selectedAnswer = null;
                            _answered = false;
                            _quizComplete = false;
                            _showConfetti = false;
                            _results.clear();
                          });
                          AppSoundService().play(AppSound.quizStart);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.richGold,
                          side: const BorderSide(color: AppColors.richGold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onComplete?.call();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            passed ? AppColors.richGold : AppColors.backgroundCard,
                        foregroundColor: passed ? Colors.black : AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        passed ? 'Continue' : 'Skip for Now',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single quiz question item
class QuizItem {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? hint;
  final String? imageUrl;

  const QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.hint,
    this.imageUrl,
  });
}
