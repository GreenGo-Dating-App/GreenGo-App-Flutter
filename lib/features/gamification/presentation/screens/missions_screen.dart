import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/missions_service.dart';
import '../../data/services/streak_service.dart';

/// Streaks & Missions hub (glass).
///
/// Shows the user's daily engagement streak (with flame) as a header and the
/// mission catalog below with progress bars, coin rewards and a Claim action
/// once a mission is complete. Data is loaded once on open; the streak is also
/// [StreakService.touch]ed on open as a safety net for app-start touch.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({required this.userId, super.key});

  final String userId;

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final StreakService _streakService = di.sl<StreakService>();
  final MissionsService _missionsService = di.sl<MissionsService>();

  StreakInfo _streak = const StreakInfo.empty();
  List<MissionState> _missions = const <MissionState>[];
  bool _loading = true;
  final Set<String> _claiming = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Touch the streak on open (safety net for app-start touch), then load.
    final streak = await _streakService.touch(widget.userId);
    final missions = await _missionsService.load(widget.userId);
    if (!mounted) return;
    setState(() {
      _streak = streak.lastActiveDay.isEmpty
          ? _streak
          : streak;
      _missions = missions;
      _loading = false;
    });
  }

  Future<void> _claim(MissionState mission) async {
    if (_claiming.contains(mission.def.id)) return;
    setState(() => _claiming.add(mission.def.id));
    try {
      await _missionsService.claim(widget.userId, mission.def.id);
      final missions = await _missionsService.load(widget.userId);
      if (!mounted) return;
      setState(() => _missions = missions);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${mission.def.coinReward} 🪙'),
          backgroundColor: AppColors.richGold.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not claim reward'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _claiming.remove(mission.def.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          l10n.missionsTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : RefreshIndicator(
              color: AppColors.richGold,
              backgroundColor: Colors.black,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _buildStreakHeader(l10n),
                  const SizedBox(height: 24),
                  Text(
                    l10n.missionsSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._missions.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMissionCard(l10n, m),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakHeader(AppLocalizations l10n) {
    return GlassContainer(
      active: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6D00).withOpacity(0.5),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.streakTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_streak.current}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.streakDaysLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.streakKeepGoing,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(AppLocalizations l10n, MissionState mission) {
    final def = mission.def;
    final complete = mission.isComplete;
    final claimed = mission.claimed;
    final isClaiming = _claiming.contains(def.id);
    final accent = claimed
        ? Colors.green
        : (complete ? AppColors.richGold : Colors.white);

    return GlassContainer(
      active: complete && !claimed,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                ),
                child: Icon(def.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: AppColors.richGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.missionRewardLabel} ${def.coinReward}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildTrailing(l10n, mission, isClaiming),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppGlass.radiusPill),
                  child: LinearProgressIndicator(
                    value: mission.fraction,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      claimed ? Colors.green : AppColors.richGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${l10n.missionProgressLabel} ${mission.progress}/${def.target}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(
    AppLocalizations l10n,
    MissionState mission,
    bool isClaiming,
  ) {
    if (mission.claimed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 4),
          Text(
            l10n.missionCompleteLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    if (!mission.isComplete) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: isClaiming ? null : () => _claim(mission),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.richGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppGlass.radiusPill),
        ),
      ),
      child: isClaiming
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Text(
              l10n.claimReward,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
    );
  }
}
