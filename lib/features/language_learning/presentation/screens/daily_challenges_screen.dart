import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/content/daily_challenges_data.dart';
import '../../domain/entities/language_challenge.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/language_challenge_card.dart';

/// Full-page daily challenges screen showing today's 3 challenges
/// plus weekly challenges and challenge history.
class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key});

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  late List<LanguageChallenge> _todayChallenges;
  late List<LanguageChallenge> _weeklyChallenges;

  @override
  void initState() {
    super.initState();
    _todayChallenges = DailyChallengesData.getChallengesForToday();
    _weeklyChallenges = LanguageChallenge.weeklyChallenges;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          l10n.dailyChallengesTitle,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.richGold),
      ),
      body: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
        builder: (context, state) {
          // Merge BLoC state challenges with static data if available
          final blocChallenges = state.dailyChallenges;
          final dailyList = blocChallenges.isNotEmpty
              ? blocChallenges
              : _todayChallenges;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's challenges header
                _buildSectionHeader(
                  l10n.dailyChallengesTitle,
                  Icons.today,
                  _timeUntilMidnight(),
                ),
                const SizedBox(height: 12),

                // Today's challenge cards
                ...dailyList.map(
                  (challenge) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LanguageChallengeCard(
                      challenge: challenge,
                      onClaim: () {
                        context.read<LanguageLearningBloc>().add(
                              ClaimChallengeReward(challenge.id),
                            );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Weekly challenges header
                _buildSectionHeader(
                  l10n.weeklyChallengesTitle,
                  Icons.date_range,
                  _timeUntilSunday(),
                ),
                const SizedBox(height: 12),

                // Weekly challenge cards
                ..._weeklyChallenges.map(
                  (challenge) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LanguageChallengeCard(
                      challenge: challenge,
                      onClaim: () {
                        context.read<LanguageLearningBloc>().add(
                              ClaimChallengeReward(challenge.id),
                            );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // XP info banner
                _buildXpInfoBanner(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String timeLeft) {
    return Row(
      children: [
        Icon(icon, color: AppColors.richGold, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.richGold, size: 14),
              const SizedBox(width: 4),
              Text(
                timeLeft,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXpInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.15),
            AppColors.richGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.richGold, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete all daily challenges for bonus XP and coins. '
              'Challenges reset every day at midnight.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  String _timeUntilSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = DateTime(now.year, now.month, now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday));
    final diff = nextSunday.difference(now);
    return '${diff.inDays}d ${diff.inHours % 24}h';
  }
}
