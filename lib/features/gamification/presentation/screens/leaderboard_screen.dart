/**
 * Leaderboard Screen
 * Point 191: Display global and regional rankings with premium UI
 * Supports week/month/year time periods and country display in regional view
 */

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/level_display_widget.dart';

enum TimePeriod { week, month, year }

class LeaderboardScreen extends StatefulWidget {
  final String userId;

  const LeaderboardScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _currentType = LeaderboardType.global;
  TimePeriod _selectedPeriod = TimePeriod.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load global leaderboard
    context.read<GamificationBloc>().add(LoadLeaderboard(
          userId: widget.userId,
          type: LeaderboardType.global,
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadLeaderboard() {
    context.read<GamificationBloc>().add(LoadLeaderboard(
          userId: widget.userId,
          type: _currentType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.gamificationLeaderboard,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Time period selector
          _buildTimePeriodSelector(l10n),

          const SizedBox(height: 8),

          // Global / Regional tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _currentType = index == 0
                      ? LeaderboardType.global
                      : LeaderboardType.regional;
                });
                _loadLeaderboard();
              },
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), AppColors.richGold],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.gamificationGlobal),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.gamificationRegional),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard Content
          Expanded(
            child: BlocBuilder<GamificationBloc, GamificationState>(
              builder: (context, state) {
                if (state.leaderboardLoading) {
                  return _buildLoadingState(l10n);
                }

                if (state.leaderboardError != null) {
                  return _buildErrorState(state, l10n);
                }

                if (state.leaderboardData == null) {
                  return _buildEmptyState(l10n);
                }

                final data = state.leaderboardData!;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // User's rank card
                      if (data.userEntry != null) _buildUserRankCard(data),

                      const SizedBox(height: 24),

                      // Top 3 podium
                      if (data.topTen.length >= 3)
                        _buildTopThreePodium(data.topTen),

                      const SizedBox(height: 24),

                      // Rest of leaderboard
                      _buildLeaderboardList(data),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPeriodChip(TimePeriod.week, l10n.gamificationWeekly),
          const SizedBox(width: 8),
          _buildPeriodChip(TimePeriod.month, l10n.gamificationMonthly),
          const SizedBox(width: 8),
          _buildPeriodChip(TimePeriod.year, l10n.gamificationYearly),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(TimePeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadLeaderboard();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), AppColors.richGold],
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.richGold.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.richGold.withOpacity(0.3),
                  AppColors.richGold.withOpacity(0.1),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: CircularProgressIndicator(
                color: AppColors.richGold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.gamificationLoadingRankings,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GamificationState state, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.leaderboardError!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            l10n.gamificationNoLeaderboard,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(data) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richGold.withOpacity(0.25),
                AppColors.richGold.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD700), AppColors.richGold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${data.userRank}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.gamificationRank,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.gamificationYourPosition,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (data.userEntry!.isVIP) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), AppColors.richGold],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.userEntry!.totalXP} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.gamificationLevel(data.userEntry!.level),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              LevelBadge(
                level: data.userEntry!.level,
                isVIP: data.userEntry!.isVIP,
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopThreePodium(List entries) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2nd place
        Expanded(child: _buildPodiumPlace(entries[1], 2)),
        const SizedBox(width: 8),
        // 1st place
        Expanded(child: _buildPodiumPlace(entries[0], 1)),
        const SizedBox(width: 8),
        // 3rd place
        Expanded(child: _buildPodiumPlace(entries[2], 3)),
      ],
    );
  }

  Widget _buildPodiumPlace(entry, int rank) {
    final colors = {
      1: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      2: [const Color(0xFFC0C0C0), const Color(0xFF808080)],
      3: [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
    };
    final heights = {1: 140.0, 2: 110.0, 3: 90.0};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final showCountry = _currentType == LeaderboardType.regional;

    return Column(
      children: [
        // Avatar with glow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors[rank]![0].withOpacity(0.5),
                blurRadius: rank == 1 ? 20 : 12,
                spreadRadius: rank == 1 ? 2 : 0,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: rank == 1 ? 40 : 32,
            backgroundColor: colors[rank]![0],
            child: CircleAvatar(
              radius: rank == 1 ? 36 : 28,
              backgroundColor: Colors.black,
              backgroundImage:
                  entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(entry.photoUrl!)
                      : null,
              child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                  ? Text(
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colors[rank]![0],
                        fontSize: rank == 1 ? 20 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          entry.username.isNotEmpty
              ? entry.username
              : 'User ${entry.userId.substring(0, 6)}',
          style: TextStyle(
            fontSize: rank == 1 ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Country for regional
        if (showCountry && entry.region != null && entry.region!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _countryCodeToFlag(entry.region!),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _countryCodeToName(entry.region!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        Text(
          '${entry.totalXP} XP',
          style: TextStyle(
            fontSize: 11,
            color: colors[rank]![0],
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            width: double.infinity,
            height: heights[rank],
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[rank]![0].withOpacity(0.8),
                  colors[rank]![1].withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[rank]![0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  medals[rank]!,
                  style: TextStyle(fontSize: rank == 1 ? 40 : 32),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(data) {
    // Skip top 3 as they're shown in podium
    final List<dynamic> entries =
        data.entries.length > 3 ? data.entries.sublist(3) : <dynamic>[];

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: List<Widget>.generate(entries.length, (index) {
              final entry = entries[index];
              final actualRank = index + 4; // Starting from 4th place
              final isCurrentUser = entry.userId == widget.userId;

              return _buildLeaderboardEntry(entry, actualRank, isCurrentUser,
                  isLast: index == entries.length - 1);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntry(entry, int rank, bool isCurrentUser,
      {bool isLast = false}) {
    final showCountry = _currentType == LeaderboardType.regional;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.richGold.withOpacity(0.1)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCurrentUser
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), AppColors.richGold],
                    )
                  : null,
              color: isCurrentUser ? null : Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.black : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User photo
          CircleAvatar(
            radius: 20,
            backgroundColor:
                entry.isVIP ? const Color(0xFFFFD700) : Colors.blue.shade400,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black,
              backgroundImage:
                  entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(entry.photoUrl!)
                      : null,
              child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                  ? Text(
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.username.isNotEmpty
                            ? entry.username
                            : 'User ${entry.userId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isCurrentUser ? AppColors.richGold : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isVIP) ...[
                      const SizedBox(width: 6),
                      const Text('👑', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .gamificationLevel(entry.level),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    if (showCountry &&
                        entry.region != null &&
                        entry.region!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _countryCodeToFlag(entry.region!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _countryCodeToName(entry.region!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.richGold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.totalXP} XP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? AppColors.richGold : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert a 2-letter country code to a flag emoji
  String _countryCodeToFlag(String countryCode) {
    final code = countryCode.toUpperCase().trim();
    if (code.length != 2) return '';
    final first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  /// Convert a 2-letter country code to a display name
  String _countryCodeToName(String countryCode) {
    const countryNames = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'DE': 'Germany',
      'FR': 'France',
      'ES': 'Spain',
      'IT': 'Italy',
      'PT': 'Portugal',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'AR': 'Argentina',
      'CO': 'Colombia',
      'CL': 'Chile',
      'PE': 'Peru',
      'VE': 'Venezuela',
      'EC': 'Ecuador',
      'CA': 'Canada',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'JP': 'Japan',
      'KR': 'South Korea',
      'CN': 'China',
      'IN': 'India',
      'RU': 'Russia',
      'ZA': 'South Africa',
      'NG': 'Nigeria',
      'EG': 'Egypt',
      'KE': 'Kenya',
      'GH': 'Ghana',
      'AT': 'Austria',
      'CH': 'Switzerland',
      'BE': 'Belgium',
      'NL': 'Netherlands',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'PL': 'Poland',
      'CZ': 'Czech Republic',
      'IE': 'Ireland',
      'GR': 'Greece',
      'TR': 'Turkey',
      'IL': 'Israel',
      'AE': 'UAE',
      'SA': 'Saudi Arabia',
      'TH': 'Thailand',
      'PH': 'Philippines',
      'ID': 'Indonesia',
      'MY': 'Malaysia',
      'SG': 'Singapore',
      'VN': 'Vietnam',
      'TW': 'Taiwan',
      'HK': 'Hong Kong',
      'UY': 'Uruguay',
      'PY': 'Paraguay',
      'BO': 'Bolivia',
      'CR': 'Costa Rica',
      'PA': 'Panama',
      'DO': 'Dominican Republic',
      'GT': 'Guatemala',
      'HN': 'Honduras',
      'SV': 'El Salvador',
      'NI': 'Nicaragua',
      'CU': 'Cuba',
      'PR': 'Puerto Rico',
      'RO': 'Romania',
      'HU': 'Hungary',
      'BG': 'Bulgaria',
      'HR': 'Croatia',
      'RS': 'Serbia',
      'SK': 'Slovakia',
      'SI': 'Slovenia',
      'UA': 'Ukraine',
      'LT': 'Lithuania',
      'LV': 'Latvia',
      'EE': 'Estonia',
    };
    final code = countryCode.toUpperCase().trim();
    return countryNames[code] ?? code;
  }
}
