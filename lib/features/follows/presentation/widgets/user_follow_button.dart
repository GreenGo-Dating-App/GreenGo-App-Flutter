import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';

/// Follow / Following button for another user's profile (or a list row).
///
/// Optimistic: the label flips instantly and rolls back with a snackbar if the
/// write fails. Live state comes from one single-doc listener (the follow
/// edge). Renders nothing for a self-view or when the two users blocked each
/// other. Pass [controller] to share the optimistic state with a
/// [FollowStatsRow] (so the follower count moves together with the button).
class UserFollowButton extends StatefulWidget {
  const UserFollowButton({
    required this.targetUserId,
    required this.currentUserId,
    super.key,
    this.controller,
    this.compact = false,
    this.followsYou = false,
    this.iconOnly = false,
    this.onDarkOverlay = false,
  });

  final String targetUserId;
  final String currentUserId;
  final FollowToggleController? controller;
  final bool compact;

  /// When true and not yet following, the label reads "Follow back".
  final bool followsYou;

  /// Renders a round icon-only button (label moves to the tooltip/semantics).
  /// Used in tight app bars on small phones.
  final bool iconOnly;

  /// When true the outlined ("Following") state gets a translucent dark fill
  /// so it stays legible over photos (e.g. a transparent app bar).
  final bool onDarkOverlay;

  /// Builds a controller wired to [FollowService] for this pair.
  static FollowToggleController createController({
    required String targetUserId,
    required String currentUserId,
  }) {
    final service = di.sl<FollowService>();
    return FollowToggleController(
      follow: () => service.followUser(
          followeeId: targetUserId, followerId: currentUserId),
      unfollow: () => service.unfollowUser(
          followeeId: targetUserId, followerId: currentUserId),
    );
  }

  @override
  State<UserFollowButton> createState() => _UserFollowButtonState();
}

class _UserFollowButtonState extends State<UserFollowButton> {
  late FollowToggleController _controller;
  bool _ownsController = false;
  StreamSubscription<bool>? _sub;
  bool _blocked = false;

  bool get _isSelf =>
      widget.targetUserId.isEmpty || widget.targetUserId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    final external = widget.controller;
    if (external != null) {
      _controller = external;
      _ownsController = false;
    } else {
      _controller = UserFollowButton.createController(
        targetUserId: widget.targetUserId,
        currentUserId: widget.currentUserId,
      );
      _ownsController = true;
    }
    _controller.addListener(_onChanged);
    if (_isSelf || widget.currentUserId.isEmpty) return;

    final service = di.sl<FollowService>();
    _sub = service
        .isFollowingUser(
            followeeId: widget.targetUserId, followerId: widget.currentUserId)
        .listen(
          (f) => _controller.syncFromServer(following: f),
          onError: (_) {},
        );
    service
        .isBlockedPair(widget.currentUserId, widget.targetUserId)
        .then((b) {
      if (mounted && b != _blocked) setState(() => _blocked = b);
    }).catchError((_) {});
  }

  void _detach() {
    _sub?.cancel();
    _sub = null;
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant UserFollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUserId != widget.targetUserId ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.controller != widget.controller) {
      _detach();
      _blocked = false;
      _attach();
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onTap() async {
    HapticFeedback.lightImpact();
    final ok = await _controller.toggle();
    if (ok || !mounted || _controller.lastError == null) return;
    final l10n = AppLocalizations.of(context)!;
    final blocked = _controller.lastError is FollowBlockedException;
    if (blocked) setState(() => _blocked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(blocked ? l10n.userFollowBlocked : l10n.userFollowError),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelf || widget.currentUserId.isEmpty || _blocked) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final following = _controller.following;
    final label = following
        ? l10n.userFollowFollowing
        : (widget.followsYou ? l10n.userFollowFollowBack : l10n.userFollowFollow);
    final filled = !following;
    final fg = filled ? AppColors.deepBlack : AppColors.richGold;
    final bg = filled
        ? AppColors.richGold
        : (widget.onDarkOverlay
            ? AppColors.backgroundDark.withOpacity(0.7)
            : Colors.transparent);
    // Tooltip names the ACTION the tap performs ("Unfollow" when following).
    final tooltip = following ? l10n.userFollowUnfollowTooltip : label;
    final icon = Icon(
      following ? Icons.check : Icons.person_add_alt_1,
      size: widget.iconOnly ? 20 : (widget.compact ? 15 : 18),
      color: fg,
    );

    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        toggled: following,
        label: label,
        hint: following ? l10n.userFollowUnfollowTooltip : null,
        // The visual children (icon/text) are replaced by this node, so it
        // carries the tap action itself.
        excludeSemantics: true,
        onTap: _controller.busy ? null : _onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _controller.busy ? null : _onTap,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: widget.iconOnly
                  ? const BoxConstraints.tightFor(width: 40, height: 40)
                  : null,
              padding: widget.iconOnly
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(
                      horizontal: widget.compact ? 14 : 20,
                      vertical: widget.compact ? 7 : 11,
                    ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.richGold, width: 1.5),
              ),
              child: widget.iconOnly
                  ? Center(child: icon)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(width: 6),
                        Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: fg,
                            fontSize: widget.compact ? 13 : 15,
                            fontWeight: FontWeight.w600,
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
