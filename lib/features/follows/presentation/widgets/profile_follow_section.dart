import 'package:flutter/material.dart';

import '../follow_toggle_controller.dart';
import 'follow_stats_row.dart';
import 'user_follow_button.dart';

/// Profile header block: "N followers · M following" plus (for someone else's
/// profile, when [showButton]) the Follow button, sharing ONE optimistic
/// controller so the follower count moves with the tap.
class ProfileFollowSection extends StatefulWidget {
  const ProfileFollowSection({
    required this.profileUserId,
    required this.currentUserId,
    super.key,
    this.showButton = true,
  });

  final String profileUserId;
  final String currentUserId;

  /// False for business profiles (they keep their own follow pill) and for
  /// the viewer's own profile.
  final bool showButton;

  @override
  State<ProfileFollowSection> createState() => _ProfileFollowSectionState();
}

class _ProfileFollowSectionState extends State<ProfileFollowSection> {
  FollowToggleController? _controller;

  bool get _isSelf => widget.profileUserId == widget.currentUserId;
  bool get _wantsButton =>
      widget.showButton && !_isSelf && widget.currentUserId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _controller?.dispose();
    _controller = _wantsButton
        ? UserFollowButton.createController(
            targetUserId: widget.profileUserId,
            currentUserId: widget.currentUserId,
          )
        : null;
  }

  @override
  void didUpdateWidget(covariant ProfileFollowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileUserId != widget.profileUserId ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.showButton != widget.showButton) {
      _build();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FollowStatsRow(
          userId: widget.profileUserId,
          currentUserId: widget.currentUserId,
          controller: controller,
        ),
        if (controller != null)
          UserFollowButton(
            targetUserId: widget.profileUserId,
            currentUserId: widget.currentUserId,
            controller: controller,
            compact: true,
          ),
      ],
    );
  }
}
