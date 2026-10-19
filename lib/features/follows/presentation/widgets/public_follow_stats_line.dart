import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/compact_count.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';
import '../screens/follow_list_screen.dart';

/// PUBLIC follow stats (owner decisions 2026-10-19): the followers AND the
/// following of every user and business are public - both counts and both
/// lists. Only the stores count stays private (own profile stats bar).
///
/// Small line under the city / category of SOMEONE ELSE's profile or
/// storefront:
///
/// ```
///   [people] 128 followers · [person] 64 following
/// ```
///
/// 13 sp, compact counts ("1.2k"), localized plurals. Each part is tappable
/// and opens [FollowListScreen] for that account on the Followers (0) /
/// Following (1) tab - also at 0 (the list shows its empty state). One
/// cached `get` of `follower_counts_public/{uid}`
/// ([FollowService.publicFollowCounts]).
///
/// - Hidden while loading and when unreadable (offline / signed out).
/// - With the page's [controller] (the app-bar Follow button's optimistic
///   state), the viewer's own follow / unfollow moves the followers number
///   at once.
class PublicFollowStatsLine extends StatefulWidget {
  const PublicFollowStatsLine({
    required this.userId,
    required this.currentUserId,
    this.controller,
    this.padding = const EdgeInsets.only(top: 6),
    this.followService,
    super.key,
  });

  /// The account whose stats are shown (never the viewer: own pages use
  /// `OwnFollowStatsLine` / `OwnFollowStatsBar`).
  final String userId;

  /// The signed-in viewer (rows' follow buttons, "Follows you" logic).
  final String currentUserId;
  final FollowToggleController? controller;

  /// Space above the line, only taken when the line is shown.
  final EdgeInsetsGeometry padding;

  /// Injectable for tests; defaults to the registered [FollowService].
  final FollowService? followService;

  @override
  State<PublicFollowStatsLine> createState() => _PublicFollowStatsLineState();
}

class _PublicFollowStatsLineState extends State<PublicFollowStatsLine> {
  PublicFollowCounts? _fetched;

  /// [FollowToggleController.followers] when [_fetched] arrived: only the
  /// viewer's own toggles after that are added on top.
  int _baseline = 0;

  FollowService get _service => widget.followService ?? di.sl<FollowService>();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
    _load();
  }

  @override
  void didUpdateWidget(covariant PublicFollowStatsLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
      // Re-base on the new controller, keeping the number shown.
      final fetched = _fetched;
      if (fetched != null) {
        final shown =
            fetched.followers + (oldWidget.controller?.followers ?? 0) - _baseline;
        _fetched = PublicFollowCounts(
            followers: shown < 0 ? 0 : shown, following: fetched.following);
        widget.controller?.syncFromServer(followers: _fetched!.followers);
        _baseline = widget.controller?.followers ?? 0;
      }
    }
    if (oldWidget.userId != widget.userId) {
      _fetched = null;
      _load();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted && _fetched != null) setState(() {});
  }

  Future<void> _load() async {
    final uid = widget.userId;
    PublicFollowCounts? counts;
    try {
      counts = await _service.publicFollowCounts(uid);
    } catch (_) {
      counts = null;
    }
    if (!mounted || uid != widget.userId || counts == null) return;
    // Seed the controller with the server value so an UNFOLLOW of an
    // already-counted follow can go down (its count is clamped at 0).
    // Ignored while a toggle is in flight; the baseline absorbs that.
    widget.controller?.syncFromServer(followers: counts.followers);
    setState(() {
      _fetched = counts;
      _baseline = widget.controller?.followers ?? 0;
    });
  }

  void _open(int tab) {
    Navigator.of(context).push(FollowListScreen.route(
      userId: widget.userId,
      currentUserId: widget.currentUserId,
      initialTab: tab,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fetched = _fetched;
    if (fetched == null) return const SizedBox.shrink();
    final delta = (widget.controller?.followers ?? 0) - _baseline;
    final followers =
        fetched.followers + delta < 0 ? 0 : fetched.followers + delta;
    final following = fetched.following;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String fmt(int v) => formatCompactCount(v, locale: locale);
    const style = TextStyle(color: AppColors.textSecondary, fontSize: 13);

    Widget part(Key key, IconData icon, String text, int tab) => Semantics(
          button: true,
          label: text,
          excludeSemantics: true,
          child: InkWell(
            key: key,
            onTap: () => _open(tab),
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
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: widget.padding,
      child: Row(
        key: const Key('public_follow_stats_line'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: part(
                const Key('public_line_followers'),
                Icons.people_alt_outlined,
                l10n.userFollowFollowersStat(followers, fmt(followers)),
                0),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('·', style: style),
          ),
          Flexible(
            child: part(
                const Key('public_line_following'),
                Icons.person_outline,
                l10n.userFollowFollowingStat(following, fmt(following)),
                1),
          ),
        ],
      ),
    );
  }
}
