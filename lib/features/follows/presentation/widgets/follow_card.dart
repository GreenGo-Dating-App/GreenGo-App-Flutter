import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';
import '../screens/follow_list_screen.dart';

/// Profile follow stats as two glass pills:
///
/// ```
///   ╭───────────────╮  ╭──────────────╮
///   │ 128 Followers │  │ 64 Following │
///   ╰───────────────╯  ╰──────────────╯
/// ```
///
/// The number is gold and bold, the label white. Tapping a pill opens
/// [FollowListScreen] on that tab.
///
/// Reads, per profile view: ONE single-doc listener on the profile counters
/// ([FollowService.counts]) — nothing else.
///
/// When [controller] is given (the one driving the profile's
/// `UserFollowButton`), the follower figure follows the optimistic toggle.
class FollowCard extends StatefulWidget {
  const FollowCard({
    required this.userId,
    required this.currentUserId,
    super.key,
    this.controller,
  });

  final String userId;
  final String currentUserId;
  final FollowToggleController? controller;

  /// Fixed height: loading → loaded never moves the layout.
  static const double height = 36;

  /// Space between the two pills.
  static const double gap = 10;

  @override
  State<FollowCard> createState() => _FollowCardState();
}

class _FollowCardState extends State<FollowCard> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts? _counts;

  FollowService get _service => di.sl<FollowService>();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onChanged);
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (widget.userId.isEmpty) return;
    _sub = _service.counts(widget.userId).listen(
      (c) {
        widget.controller?.syncFromServer(followers: c.followers);
        if (!mounted) return;
        setState(() => _counts = c);
      },
      onError: (_) {/* keep the dashes */},
    );
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FollowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onChanged);
      widget.controller?.addListener(_onChanged);
    }
    if (oldWidget.userId != widget.userId) {
      _counts = null;
      _listen();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _open(int tab) {
    Navigator.of(context).push(
      FollowListScreen.route(
        userId: widget.userId,
        currentUserId: widget.currentUserId,
        initialTab: tab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final c = _counts;
    final loading = c == null;
    final followers = widget.controller?.followers ?? c?.followers ?? 0;
    final following = c?.following ?? 0;
    String fmt(int v) => formatCompactCount(v, locale: locale);

    return SizedBox(
      key: const Key('follow_card'),
      height: FollowCard.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _FollowPill(
              key: const Key('follow_card_followers'),
              number: loading ? '–' : fmt(followers),
              label: l10n.userFollowCardFollowersLabel(followers),
              semanticsLabel: loading
                  ? l10n.userFollowTabFollowers
                  : l10n.userFollowFollowersStat(followers, fmt(followers)),
              onTap: () => _open(0),
            ),
          ),
          const SizedBox(width: FollowCard.gap),
          Flexible(
            child: _FollowPill(
              key: const Key('follow_card_following'),
              number: loading ? '–' : fmt(following),
              label: l10n.userFollowTabFollowing,
              semanticsLabel: loading
                  ? l10n.userFollowTabFollowing
                  : l10n.userFollowFollowingStat(following, fmt(following)),
              onTap: () => _open(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable glass pill: gold bold number, a space, white label.
class _FollowPill extends StatelessWidget {
  const _FollowPill({
    required this.number,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final String number;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppGlass.radiusPill,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onTap,
        child: SizedBox(
          height: FollowCard.height - 2, // inside the 1 px hairline border
          child: Center(
            widthFactor: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: number,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: label),
                  ],
                ),
                key: const Key('follow_card_pill_text'),
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
