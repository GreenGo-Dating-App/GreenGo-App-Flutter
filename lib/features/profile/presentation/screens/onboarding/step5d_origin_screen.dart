import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/country_flag_helper.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step5dOriginScreen extends StatefulWidget {
  const Step5dOriginScreen({super.key});

  @override
  State<Step5dOriginScreen> createState() => _Step5dOriginScreenState();
}

class _Step5dOriginScreenState extends State<Step5dOriginScreen> {
  String? _primary;
  String? _secondary;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _primary = state.primaryOrigin;
      _secondary = state.secondaryOrigin;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> get _filteredCountries {
    if (_searchQuery.isEmpty) return CountryFlagHelper.allCountries;
    final q = _searchQuery.toLowerCase();
    return CountryFlagHelper.allCountries
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  void _selectCountry(String isoCode) {
    setState(() {
      if (_primary == isoCode) {
        _primary = null;
      } else if (_secondary == isoCode) {
        _secondary = null;
      } else if (_primary == null) {
        _primary = isoCode;
      } else {
        _secondary = isoCode;
      }
    });
    context.read<OnboardingBloc>().add(
          OnboardingOriginUpdated(
            primaryOrigin: _primary,
            secondaryOrigin: _secondary,
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
          title: 'Where are you from?',
          subtitle:
              'Select your origin. You can add a second country if you have mixed roots.',
          onBack: () {
            context
                .read<OnboardingBloc>()
                .add(const OnboardingPreviousStep());
          },
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Selected origins display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _OriginChip(
                        label: 'Primary Origin',
                        isoCode: _primary,
                        onClear: () {
                          setState(() => _primary = null);
                          context.read<OnboardingBloc>().add(
                                OnboardingOriginUpdated(
                                  primaryOrigin: null,
                                  secondaryOrigin: _secondary,
                                ),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OriginChip(
                        label: 'Secondary (optional)',
                        isoCode: _secondary,
                        onClear: () {
                          setState(() => _secondary = null);
                          context.read<OnboardingBloc>().add(
                                OnboardingOriginUpdated(
                                  primaryOrigin: _primary,
                                  secondaryOrigin: null,
                                ),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  hintStyle:
                      const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              // Country list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final flag =
                        CountryFlagHelper.getFlag(country.isoCode);
                    final isPrimary = _primary == country.isoCode;
                    final isSecondary = _secondary == country.isoCode;

                    return ListTile(
                      leading:
                          Text(flag, style: const TextStyle(fontSize: 28)),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: isPrimary || isSecondary
                              ? AppColors.richGold
                              : AppColors.textPrimary,
                          fontWeight: isPrimary || isSecondary
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isPrimary
                          ? const Icon(Icons.check_circle,
                              color: AppColors.richGold)
                          : isSecondary
                              ? const Icon(Icons.check_circle_outline,
                                  color: AppColors.richGold)
                              : null,
                      onTap: () => _selectCountry(country.isoCode),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Next button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _primary != null
                      ? () {
                          context
                              .read<OnboardingBloc>()
                              .add(const OnboardingNextStep());
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.richGold.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
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

class _OriginChip extends StatelessWidget {
  final String label;
  final String? isoCode;
  final VoidCallback onClear;

  const _OriginChip({
    required this.label,
    this.isoCode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (isoCode == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: AppColors.textTertiary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    final flag = CountryFlagHelper.getFlag(isoCode!);
    final name = CountryFlagHelper.allCountries
            .where((c) => c.isoCode == isoCode)
            .map((c) => c.name)
            .firstOrNull ??
        isoCode!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.richGold.withValues(alpha: 0.15),
        border:
            Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
