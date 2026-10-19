import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/info_button.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../screens/follow_list_screen.dart';
import '../screens/followed_stores_screen.dart';

/// PRIVATE follow stats (owner rule 2026-10-17): followers / following /
/// stores are shown ONLY to the account itself. Every widget here renders
/// nothing unless [userId] is the signed-in [currentUserId], and reads only
/// the owner-only counters ([FollowService.counts]: `follow_counts/{uid}`).
bool isOwnFollowView(String userId, String currentUserId) =>
    userId.isNotEmpty && userId == currentUserId;

/// Opens the own Followers (0) / Following (1) list.
void openOwnFollowList(BuildContext context, String uid, int tab) {
  Navigator.of(context).push(
    FollowListScreen.route(userId: uid, currentUserId: uid, initialTab: tab),
  );
}

/// Shared live-counts state for the own-stats widgets.
mixin _OwnCounts<T extends StatefulWidget> on State<T> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts? counts;

  void listenCounts(String uid) {
    _sub?.cancel();
    counts = null;
    if (uid.isEmpty) return;
    _sub = di.sl<FollowService>().counts(uid).listen(
      (c) {
        if (mounted) setState(() => counts = c);
      },
      onError: (_) {/* keep the dashes */},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Own-profile stats bar (owner pick 2026-10-17, "option 2"): one light
/// glass bar, three equal tappable columns with thin dividers.
///
/// ```
///  ╭───────────┬───────────┬───────────╮
///  │    128    │    64     │    12     │
///  │ Followers │ Following │  Stores   │
///  ╰───────────┴───────────┴───────────╯
/// ```
class OwnFollowStatsBar extends StatefulWidget {
  const OwnFollowStatsBar({
    required this.userId,
    required this.currentUserId,
    super.key,
  });

  final String userId;
  final String currentUserId;

  static const double height = 58;

  @override
  State<OwnFollowStatsBar> createState() => _OwnFollowStatsBarState();
}

class _OwnFollowStatsBarState extends State<OwnFollowStatsBar>
    with _OwnCounts<OwnFollowStatsBar> {
  bool get _own => isOwnFollowView(widget.userId, widget.currentUserId);

  @override
  void initState() {
    super.initState();
    if (_own) listenCounts(widget.userId);
  }

  @override
  void didUpdateWidget(covariant OwnFollowStatsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentUserId != widget.currentUserId) {
      if (_own) listenCounts(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_own) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final c = counts;
    String fmt(int v) => c == null ? '–' : formatCompactCount(v, locale: locale);
    final followers = c?.followers ?? 0;
    final following = c?.following ?? 0;
    final stores = c?.stores ?? 0;
    final divider = Container(
      width: 1,
      height: 28,
      color: AppColors.divider.withOpacity(0.5),
    );
    return GlassContainer(
      key: const Key('own_follow_stats_bar'),
      borderRadius: AppGlass.radiusCard,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: OwnFollowStatsBar.height,
        child: Row(
          children: [
            _StatColumn(
              key: const Key('own_stat_followers'),
              number: fmt(followers),
              label: l10n.userFollowCardFollowersLabel(followers),
              semantics: l10n.userFollowFollowersStat(followers, fmt(followers)),
              onTap: () => openOwnFollowList(context, widget.userId, 0),
            ),
            divider,
            _StatColumn(
              key: const Key('own_stat_following'),
              number: fmt(following),
              label: l10n.userFollowTabFollowing,
              semantics: l10n.userFollowFollowingStat(following, fmt(following)),
              onTap: () => openOwnFollowList(context, widget.userId, 1),
            ),
            divider,
            _StatColumn(
              key: const Key('own_stat_stores'),
              number: fmt(stores),
              label: l10n.userFollowStoresLabel,
              semantics: '${fmt(stores)} ${l10n.userFollowStoresLabel}',
              onTap: () => Navigator.of(context).push(
                FollowedStoresScreen.route(userId: widget.userId),
              ),
            ),
            InfoButton(
              key: const Key('own_follow_stats_info'),
              title: l10n.xplInfoFollowTitle,
              message: l10n.xplInfoFollowBody,
              bullets: [l10n.xplInfoFollowPublic, l10n.xplInfoFollowStores],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.number,
    required this.label,
    required this.semantics,
    required this.onTap,
    super.key,
  });

  final String number;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppGlass.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      number,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

/// Small line under the city on "View my profile" (owner, 2026-10-17):
/// `[people] 128 followers · [person] 64 following`, each part tappable.
/// Renders nothing for any other viewer.
class OwnFollowStatsLine extends StatefulWidget {
  const OwnFollowStatsLine({
    required this.userId,
    required this.currentUserId,
    super.key,
  });

  final String userId;
  final String currentUserId;

  @override
  State<OwnFollowStatsLine> createState() => _OwnFollowStatsLineState();
}

class _OwnFollowStatsLineState extends State<OwnFollowStatsLine>
    with _OwnCounts<OwnFollowStatsLine> {
  bool get _own => isOwnFollowView(widget.userId, widget.currentUserId);

  @override
  void initState() {
    super.initState();
    if (_own) listenCounts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_own) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final c = counts;
    String fmt(int v) => c == null ? '–' : formatCompactCount(v, locale: locale);
    final followers = c?.followers ?? 0;
    final following = c?.following ?? 0;
    const style = TextStyle(color: AppColors.textSecondary, fontSize: 13);

    Widget part(Key key, IconData icon, String text, int tab) => InkWell(
          key: key,
          onTap: () => openOwnFollowList(context, widget.userId, tab),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(text,
                      style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );

    return Row(
      key: const Key('own_follow_stats_line'),
      children: [
        Flexible(
          child: part(const Key('own_line_followers'), Icons.people_alt_outlined,
              l10n.userFollowFollowersStat(followers, fmt(followers)), 0),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: style),
        ),
        Flexible(
          child: part(const Key('own_line_following'), Icons.person_outline,
              l10n.userFollowFollowingStat(following, fmt(following)), 1),
        ),
      ],
    );
  }
}

/// The signed-in user's own follower count, live (Explore stats header).
/// Builds [builder] with null while loading.
class OwnFollowersCount extends StatefulWidget {
  const OwnFollowersCount({required this.uid, required this.builder, super.key});

  final String uid;
  final Widget Function(BuildContext context, int? followers) builder;

  @override
  State<OwnFollowersCount> createState() => _OwnFollowersCountState();
}

class _OwnFollowersCountState extends State<OwnFollowersCount>
    with _OwnCounts<OwnFollowersCount> {
  @override
  void initState() {
    super.initState();
    listenCounts(widget.uid);
  }

  @override
  void didUpdateWidget(covariant OwnFollowersCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) listenCounts(widget.uid);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, counts?.followers);
}
