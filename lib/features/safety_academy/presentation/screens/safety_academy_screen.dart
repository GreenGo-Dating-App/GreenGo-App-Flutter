import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/safety_academy_remote_datasource.dart';
import '../../data/repositories/safety_academy_repository_impl.dart';
import '../../domain/entities/safety_module.dart';
import '../../domain/entities/safety_progress.dart';
import '../bloc/safety_academy_bloc.dart';
import '../bloc/safety_academy_event.dart';
import '../bloc/safety_academy_state.dart';
import '../widgets/safety_module_card.dart';
import 'safety_lesson_screen.dart';

/// Main hub screen for the Safety Academy feature.
///
/// Displays all 5 safety modules as cards, total XP earned,
/// and completion progress for each module.
class SafetyAcademyScreen extends StatelessWidget {
  final String userId;

  const SafetyAcademyScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final datasource = SafetyAcademyRemoteDatasource();
        final repository =
            SafetyAcademyRepositoryImpl(remoteDatasource: datasource);
        return SafetyAcademyBloc(repository: repository)
          ..add(const LoadModules())
          ..add(LoadProgress(userId));
      },
      child: _SafetyAcademyScreenContent(userId: userId),
    );
  }
}

class _SafetyAcademyScreenContent extends StatelessWidget {
  final String userId;

  const _SafetyAcademyScreenContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Safety Academy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<SafetyAcademyBloc, SafetyAcademyState>(
        builder: (context, state) {
          if (state.isLoadingModules) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (state.errorMessage != null && state.modules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SafetyAcademyBloc>()
                        ..add(const LoadModules())
                        ..add(LoadProgress(userId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP header
                _buildXpHeader(state.progress),
                const SizedBox(height: 24),

                // Section title
                const Text(
                  'Learning Modules',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Module cards
                ...state.modules.map((module) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SafetyModuleCard(
                        module: module,
                        progress: state.progress,
                        onTap: () => _navigateToModule(context, module),
                      ),
                    )),

                // Safety champion badge
                if (state.progress?.badges.contains('safety_champion') ??
                    false)
                  _buildSafetyChampionBanner(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildXpHeader(SafetyProgress? progress) {
    final totalXp = progress?.totalXpEarned ?? 0;
    final completedModules = progress?.completedModules.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shield,
            color: AppColors.deepBlack,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            '$totalXp XP',
            style: const TextStyle(
              color: AppColors.deepBlack,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$completedModules / 5 modules completed',
            style: TextStyle(
              color: AppColors.deepBlack.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyChampionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: AppColors.richGold,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Champion',
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You completed all safety modules!',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToModule(BuildContext context, SafetyModule module) {
    final bloc = context.read<SafetyAcademyBloc>();
    bloc.add(LoadLessons(module.id));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: SafetyLessonScreen(
            userId: userId,
            module: module,
          ),
        ),
      ),
    );
  }
}
