import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../data/services/follow_service.dart';

/// Follow / Unfollow button for a public business account.
///
/// Streams the live follow state (the follower doc) and the denormalized
/// follower count from [FollowService], so the button is always correct across
/// devices without polling. A self-view (business owner looking at their own
/// storefront) renders a passive follower-count chip instead of a follow
/// action.
class BusinessFollowButton extends StatefulWidget {
  const BusinessFollowButton({
    required this.businessId,
    required this.currentUserId,
    super.key,
    this.compact = false,
  });

  final String businessId;
  final String currentUserId;

  /// Renders a smaller pill (for headers) when true.
  final bool compact;

  @override
  State<BusinessFollowButton> createState() => _BusinessFollowButtonState();
}

class _BusinessFollowButtonState extends State<BusinessFollowButton> {
  final FollowService _service = di.sl<FollowService>();
  bool _busy = false;

  bool get _isSelf => widget.businessId == widget.currentUserId;

  Future<void> _toggle(bool currentlyFollowing) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    try {
      await _service.toggle(
        businessId: widget.businessId,
        uid: widget.currentUserId,
        currentlyFollowing: currentlyFollowing,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.businessFollowError),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<int>(
      stream: _service.followerCount(widget.businessId),
      builder: (context, countSnap) {
        final count = countSnap.data ?? 0;

        // Self-view: show a passive follower-count chip, no action.
        if (_isSelf) {
          return _CountChip(
            label: l10n.businessFollowersCount(count),
            compact: widget.compact,
          );
        }

        return StreamBuilder<bool>(
          stream: _service.isFollowing(
            businessId: widget.businessId,
            uid: widget.currentUserId,
          ),
          builder: (context, followSnap) {
            final following = followSnap.data ?? false;
            final label = following
                ? l10n.businessFollowing
                : l10n.businessFollow;

            return _ActionPill(
              icon: following ? Icons.check : Icons.add,
              label: count > 0 ? '$label · ${_fmtCount(count)}' : label,
              filled: !following,
              busy: _busy,
              compact: widget.compact,
              onTap: () => _toggle(following),
            );
          },
        );
      },
    );
  }

  String _fmtCount(int c) =>
      c > 999 ? '${(c / 1000).toStringAsFixed(1)}k' : '$c';
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.filled,
    required this.busy,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final bool busy;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.deepBlack : AppColors.richGold;
    final vPad = compact ? 8.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20, vertical: vPad),
          decoration: BoxDecoration(
            color: filled ? AppColors.richGold : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.richGold, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(icon, size: compact ? 16 : 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.richGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group, size: 16, color: AppColors.richGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
