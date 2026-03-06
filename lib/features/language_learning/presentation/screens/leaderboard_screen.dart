import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _selectedType = LeaderboardType.totalXp;

  static const _periods = [
    LeaderboardPeriod.weekly,
    LeaderboardPeriod.monthly,
    LeaderboardPeriod.allTime,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadLeaderboard();
    }
  }

  void _loadLeaderboard() {
    context.read<LanguageLearningBloc>().add(
          LoadLeaderboard(
            type: _selectedType,
            period: _periods[_tabController.index],
          ),
        );
  }

  String _periodLabel(AppLocalizations l10n, LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.weekly:
        return l10n.periodWeekly;
      case LeaderboardPeriod.monthly:
        return l10n.periodMonthly;
      case LeaderboardPeriod.allTime:
        return l10n.periodAllTime;
    }
  }

  String _typeLabel(AppLocalizations l10n, LeaderboardType type) {
    switch (type) {
      case LeaderboardType.totalXp:
        return l10n.typeXp;
      case LeaderboardType.streak:
        return l10n.typeStreak;
      case LeaderboardType.wordsLearned:
        return l10n.typeWordsLearned;
      case LeaderboardType.quizzes:
        return l10n.typeQuizzes;
      case LeaderboardType.languagesMastered:
        return l10n.typeWordsLearned; // fallback
    }
  }

  int _getEntryScore(LeaderboardEntry entry) {
    switch (_selectedType) {
      case LeaderboardType.totalXp:
        return entry.totalXp;
      case LeaderboardType.streak:
        return entry.currentStreak;
      case LeaderboardType.wordsLearned:
        return entry.wordsLearned;
      case LeaderboardType.quizzes:
        return entry.quizzesCompleted;
      case LeaderboardType.languagesMastered:
        return entry.languagesCount;
    }
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
          l10n.leaderboardTitle,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.richGold),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: _periods
              .map((p) => Tab(text: _periodLabel(l10n, p)))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Type dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LeaderboardType>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.richGold,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: [
                    LeaderboardType.totalXp,
                    LeaderboardType.streak,
                    LeaderboardType.wordsLearned,
                    LeaderboardType.quizzes,
                  ].map((type) {
                    return DropdownMenuItem<LeaderboardType>(
                      value: type,
                      child: Row(
                        children: [
                          Text(
                            type.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(_typeLabel(l10n, type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (type) {
                    if (type != null) {
                      setState(() => _selectedType = type);
                      _loadLeaderboard();
                    }
                  },
                ),
              ),
            ),
          ),
          // Leaderboard content
          Expanded(
            child: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
              builder: (context, state) {
                if (state.isLeaderboardLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                final leaderboard = state.leaderboard;
                if (leaderboard == null || leaderboard.entries.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                final entries = leaderboard.entries;
                final topThree = entries.where((e) => e.rank <= 3).toList()
                  ..sort((a, b) => a.rank.compareTo(b.rank));
                final rest = entries.where((e) => e.rank > 3).toList();
                final currentUser =
                    entries.where((e) => e.isCurrentUser).firstOrNull;

                return Column(
                  children: [
                    // Podium
                    if (topThree.isNotEmpty)
                      _buildPodium(topThree),
                    const SizedBox(height: 8),
                    // Rank list
                    Expanded(
                      child: rest.isEmpty
                          ? const SizedBox.shrink()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: rest.length,
                              itemBuilder: (context, index) {
                                return _buildRankRow(rest[index]);
                              },
                            ),
                    ),
                    // Your rank bar
                    if (currentUser != null)
                      _buildYourRankBar(l10n, currentUser),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Colors.grey,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noLeaderboardData,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    // Arrange as: 2nd (left), 1st (center, tallest), 3rd (right)
    LeaderboardEntry? first;
    LeaderboardEntry? second;
    LeaderboardEntry? third;

    for (final entry in topThree) {
      if (entry.rank == 1) first = entry;
      if (entry.rank == 2) second = entry;
      if (entry.rank == 3) third = entry;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          if (second != null)
            Expanded(child: _buildPodiumColumn(second, 100, const Color(0xFFC0C0C0)))
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          if (first != null)
            Expanded(child: _buildPodiumColumn(first, 130, const Color(0xFFFFD700)))
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 8),
          // 3rd place (right)
          if (third != null)
            Expanded(child: _buildPodiumColumn(third, 80, const Color(0xFFCD7F32)))
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    LeaderboardEntry entry,
    double podiumHeight,
    Color medalColor,
  ) {
    final medal = entry.rank == 1
        ? '\u{1F947}'
        : entry.rank == 2
            ? '\u{1F948}'
            : '\u{1F949}';
    final score = _getEntryScore(entry);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        // Avatar
        Container(
          width: entry.rank == 1 ? 64 : 52,
          height: entry.rank == 1 ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 3),
            color: const Color(0xFF2A2A2A),
          ),
          child: entry.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    entry.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildInitials(entry.username),
                  ),
                )
              : _buildInitials(entry.username),
        ),
        const SizedBox(height: 6),
        // Username
        Text(
          entry.username,
          style: TextStyle(
            color: entry.isCurrentUser ? AppColors.richGold : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // Score
        Text(
          _formatScore(score),
          style: TextStyle(
            color: medalColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        // Podium block
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor.withValues(alpha: 0.4),
                medalColor.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: medalColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(String username) {
    final initials = username.isNotEmpty
        ? username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry) {
    final score = _getEntryScore(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.richGold.withValues(alpha: 0.15)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.richGold.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                color: entry.isCurrentUser ? AppColors.richGold : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(
                color: entry.isCurrentUser
                    ? AppColors.richGold
                    : Colors.grey[700]!,
                width: 1.5,
              ),
            ),
            child: entry.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildInitials(entry.username),
                    ),
                  )
                : _buildInitials(entry.username),
          ),
          const SizedBox(width: 12),
          // Username & flag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    color: entry.isCurrentUser ? AppColors.richGold : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.countryFlag != null || entry.primaryLanguage != null)
                  Text(
                    [
                      if (entry.countryFlag != null) entry.countryFlag!,
                      if (entry.primaryLanguage != null) entry.primaryLanguage!,
                    ].join(' '),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Score
          Text(
            _formatScore(score),
            style: TextStyle(
              color: entry.isCurrentUser ? AppColors.richGold : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourRankBar(AppLocalizations l10n, LeaderboardEntry currentUser) {
    final score = _getEntryScore(currentUser);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: AppColors.richGold.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.yourRankLabel,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
                border: Border.all(color: AppColors.richGold, width: 2),
              ),
              child: currentUser.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        currentUser.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildInitials(currentUser.username),
                      ),
                    )
                  : _buildInitials(currentUser.username),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentUser.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '#${currentUser.rank}',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatScore(score),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
