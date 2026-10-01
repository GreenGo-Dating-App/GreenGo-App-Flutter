import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/compact_count.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';
import '../screens/follow_list_screen.dart';

/// "N followers · M following" for [userId] — compact, localized and tappable
/// (opens [FollowListScreen] on the matching tab).
///
/// Reads the SERVER-maintained counters with one single-doc listener on the
/// profile. When [controller] is given (the same one driving a
/// `UserFollowButton`), the follower figure follows the optimistic toggle.
class FollowStatsRow extends StatefulWidget {
  const FollowStatsRow({
    required this.userId,
    required this.currentUserId,
    super.key,
    this.controller,
    this.alignment = MainAxisAlignment.start,
  });

  final String userId;
  final String currentUserId;
  final FollowToggleController? controller;
  final MainAxisAlignment alignment;

  @override
  State<FollowStatsRow> createState() => _FollowStatsRowState();
}

class _FollowStatsRowState extends State<FollowStatsRow> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts _counts = FollowCounts.zero;

  @override
  void initState() {
    super.initState();
    _listen();
    widget.controller?.addListener(_onController);
  }

  void _listen() {
    _sub?.cancel();
    if (widget.userId.isEmpty) return;
    _sub = di.sl<FollowService>().counts(widget.userId).listen(
      (c) {
        widget.controller?.syncFromServer(followers: c.followers);
        if (mounted) setState(() => _counts = c);
      },
      onError: (_) {},
    );
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FollowStatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    if (oldWidget.userId != widget.userId) {
      _counts = FollowCounts.zero;
      _listen();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.controller?.removeListener(_onController);
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
    final followers = widget.controller?.followers ?? _counts.followers;
    final following = _counts.following;

    Widget stat(String text, int tab) => InkWell(
          onTap: () => _open(tab),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

    return Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        stat(
          l10n.userFollowFollowersStat(
              followers, formatCompactCount(followers, locale: locale)),
          0,
        ),
        const Text(' · ', style: TextStyle(color: AppColors.textTertiary)),
        stat(
          l10n.userFollowFollowingStat(
              following, formatCompactCount(following, locale: locale)),
          1,
        ),
      ],
    );
  }
}
