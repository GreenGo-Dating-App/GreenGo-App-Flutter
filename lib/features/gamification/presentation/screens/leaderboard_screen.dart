/**
 * Leaderboard Screen
 * Point 191: Display global and regional rankings
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/level_display_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentType = index == 0
                  ? LeaderboardType.global
                  : LeaderboardType.regional;
            });

            context.read<GamificationBloc>().add(LoadLeaderboard(
                  userId: widget.userId,
                  type: _currentType,
                ));
          },
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Regional'),
          ],
        ),
      ),
      body: BlocBuilder<GamificationBloc, GamificationState>(
        builder: (context, state) {
          if (state.leaderboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.leaderboardError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.leaderboardError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GamificationBloc>().add(LoadLeaderboard(
                            userId: widget.userId,
                            type: _currentType,
                          ));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.leaderboardData == null) {
            return const Center(child: Text('No leaderboard data'));
          }

          final data = state.leaderboardData!;

          return Column(
            children: [
              // User's rank card
              if (data.userEntry != null) _buildUserRankCard(data),

              // Top 3 podium
              if (data.topTen.length >= 3) _buildTopThreePodium(data.topTen),

              // Leaderboard list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.entries.length,
                  itemBuilder: (context, index) {
                    final entry = data.entries[index];
                    final isCurrentUser = entry.userId == widget.userId;

                    return _buildLeaderboardEntry(
                      entry,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserRankCard(data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rank',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '#${data.userRank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (data.userEntry!.isVIP) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '👑',
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          LevelBadge(
            level: data.userEntry!.level,
            isVIP: data.userEntry!.isVIP,
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreePodium(List entries) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          _buildPodiumPlace(entries[1], 2, 140, Colors.grey),
          const SizedBox(width: 16),
          // 1st place
          _buildPodiumPlace(entries[0], 1, 180, const Color(0xFFFFD700)),
          const SizedBox(width: 16),
          // 3rd place
          _buildPodiumPlace(entries[2], 3, 120, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(entry, int rank, double height, Color color) {
    final medals = ['', '🥇', '🥈', '🥉'];

    return Column(
      children: [
        LevelBadge(
          level: entry.level,
          isVIP: entry.isVIP,
          size: rank == 1 ? 56 : 48,
        ),
        const SizedBox(height: 8),
        Text(
          entry.displayName ?? 'User ${entry.userId.substring(0, 6)}',
          style: TextStyle(
            fontSize: rank == 1 ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.totalXP} XP',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              medals[rank],
              style: const TextStyle(fontSize: 40),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(entry, {bool isCurrentUser = false}) {
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: Colors.grey,
      3: Colors.brown,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColors[entry.rank]?.withOpacity(0.2) ??
                  Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankColors[entry.rank] ?? Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar/Level badge
          LevelBadge(
            level: entry.level,
            isVIP: entry.isVIP,
            size: 40,
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
                        entry.displayName ??
                            'User ${entry.userId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isVIP) ...[
                      const SizedBox(width: 4),
                      const Text('👑', style: TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Level ${entry.level} • ${entry.totalXP} XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Trophy icon for top 10
          if (entry.rank <= 10)
            Icon(
              Icons.emoji_events,
              color: rankColors[entry.rank] ?? Colors.amber,
              size: 24,
            ),
        ],
      ),
    );
  }
}
