import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/profile.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step7PersonalityQuizScreen extends StatefulWidget {
  const Step7PersonalityQuizScreen({super.key});

  @override
  State<Step7PersonalityQuizScreen> createState() =>
      _Step7PersonalityQuizScreenState();
}

class _Step7PersonalityQuizScreenState
    extends State<Step7PersonalityQuizScreen> {
  int _currentQuestionIndex = 0;

  final List<QuizQuestion> _questions = [
    QuizQuestion(
      question: 'I enjoy trying new and exciting activities',
      trait: 'openness',
      isPositive: true,
    ),
    QuizQuestion(
      question: 'I prefer to have a structured and organized routine',
      trait: 'conscientiousness',
      isPositive: true,
    ),
    QuizQuestion(
      question: 'I feel energized when socializing with others',
      trait: 'extraversion',
      isPositive: true,
    ),
    QuizQuestion(
      question: 'I try to be cooperative and avoid conflicts',
      trait: 'agreeableness',
      isPositive: true,
    ),
    QuizQuestion(
      question: 'I often feel anxious or worried about things',
      trait: 'neuroticism',
      isPositive: true,
    ),
  ];

  final Map<String, int> _traitScores = {
    'openness': 0,
    'conscientiousness': 0,
    'extraversion': 0,
    'agreeableness': 0,
    'neuroticism': 0,
  };

  void _answerQuestion(int score) {
    final question = _questions[_currentQuestionIndex];
    final trait = question.trait;
    final finalScore = question.isPositive ? score : 5 - score;

    setState(() {
      _traitScores[trait] = finalScore;

      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        // Quiz completed, calculate final scores
        _completeQuiz();
      }
    });
  }

  void _completeQuiz() {
    final traits = PersonalityTraits(
      openness: _traitScores['openness']!,
      conscientiousness: _traitScores['conscientiousness']!,
      extraversion: _traitScores['extraversion']!,
      agreeableness: _traitScores['agreeableness']!,
      neuroticism: _traitScores['neuroticism']!,
    );

    context.read<OnboardingBloc>().add(
          OnboardingPersonalityUpdated(traits: traits),
        );
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    } else {
      context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return LuxuryOnboardingLayout(
          title: 'Personality quiz',
          subtitle: 'Help us understand your personality',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
            children: [
              // Quiz Progress
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Question Card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            question.question,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 40),

                          // Answer Options
                          _buildAnswerButton('Strongly Disagree', 1),
                          const SizedBox(height: 12),
                          _buildAnswerButton('Disagree', 2),
                          const SizedBox(height: 12),
                          _buildAnswerButton('Neutral', 3),
                          const SizedBox(height: 12),
                          _buildAnswerButton('Agree', 4),
                          const SizedBox(height: 12),
                          _buildAnswerButton('Strongly Agree', 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info Box
              LuxuryGlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: AppColors.richGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Based on the Big Five personality traits model',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerButton(String text, int score) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _answerQuestion(score),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final String trait;
  final bool isPositive;

  QuizQuestion({
    required this.question,
    required this.trait,
    required this.isPositive,
  });
}
