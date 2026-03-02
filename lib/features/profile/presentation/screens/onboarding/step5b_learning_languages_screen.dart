import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step5bLearningLanguagesScreen extends StatefulWidget {
  const Step5bLearningLanguagesScreen({super.key});

  @override
  State<Step5bLearningLanguagesScreen> createState() =>
      _Step5bLearningLanguagesScreenState();
}

class _Step5bLearningLanguagesScreenState
    extends State<Step5bLearningLanguagesScreen> {
  static const List<String> _supportedLanguages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
    'Russian', 'Japanese', 'Korean', 'Chinese', 'Arabic', 'Hindi',
    'Turkish', 'Dutch', 'Swedish', 'Norwegian', 'Danish', 'Finnish',
    'Polish', 'Czech', 'Romanian', 'Hungarian', 'Greek', 'Thai',
    'Vietnamese', 'Indonesian', 'Malay', 'Filipino', 'Swahili',
    'Hebrew', 'Persian', 'Ukrainian', 'Serbian', 'Croatian',
    'Bulgarian', 'Slovak', 'Slovenian', 'Lithuanian', 'Latvian',
    'Estonian', 'Georgian',
  ];

  List<String> _selectedLanguages = [];
  String? _nativeLanguage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _selectedLanguages = List.from(state.preferredLanguages);
      _nativeLanguage = state.nativeLanguage;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _supportedLanguages;
    return _supportedLanguages
        .where((l) => l.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        if (_selectedLanguages.length < 5) {
          _selectedLanguages.add(language);
        }
      }
    });
    _updateBloc();
  }

  void _setNativeLanguage(String? language) {
    setState(() {
      _nativeLanguage = language;
    });
    _updateBloc();
  }

  void _updateBloc() {
    context.read<OnboardingBloc>().add(
          OnboardingLearningLanguagesUpdated(
            preferredLanguages: _selectedLanguages,
            nativeLanguage: _nativeLanguage,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) return const SizedBox();

        return LuxuryOnboardingLayout(
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          title: 'What languages do you want to learn?',
          subtitle:
              'Select up to 5 languages. This helps us connect you with native speakers and learning partners.',
          onBack: () {
            context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Native language selector
              const Text(
                'Your native language',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _nativeLanguage,
                    hint: const Text(
                      'Select your native language',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                    dropdownColor: AppColors.backgroundCard,
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: _supportedLanguages
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: _setNativeLanguage,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Languages to learn
              Text(
                'Languages to learn (${_selectedLanguages.length}/5)',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Selected languages chips
              if (_selectedLanguages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedLanguages
                      .map((lang) => Chip(
                            label: Text(lang,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                            deleteIconColor: AppColors.richGold,
                            side: const BorderSide(color: AppColors.richGold),
                            onDeleted: () => _toggleLanguage(lang),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Language grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredLanguages.length,
                  itemBuilder: (context, index) {
                    final language = _filteredLanguages[index];
                    final isSelected = _selectedLanguages.contains(language);
                    final isNative = _nativeLanguage == language;

                    return GestureDetector(
                      onTap: isNative ? null : () => _toggleLanguage(language),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.richGold.withValues(alpha: 0.2)
                              : isNative
                                  ? AppColors.backgroundCard.withValues(alpha: 0.5)
                                  : AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.richGold
                                : AppColors.divider,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.check,
                                    color: AppColors.richGold, size: 18),
                              ),
                            Text(
                              language,
                              style: TextStyle(
                                color: isNative
                                    ? AppColors.textTertiary
                                    : isSelected
                                        ? AppColors.richGold
                                        : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            if (isNative)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  '(native)',
                                  style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Next / Skip button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Save language selections
                    context.read<OnboardingBloc>().add(
                      OnboardingLearningLanguagesUpdated(
                        preferredLanguages: _selectedLanguages,
                        nativeLanguage: _nativeLanguage,
                      ),
                    );
                    context.read<OnboardingBloc>().add(const OnboardingNextStep());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedLanguages.isEmpty ? 'Skip' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
