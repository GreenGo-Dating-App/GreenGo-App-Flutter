import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../data/services/rating_service.dart';

/// Interactive 1–5 star rating control for a public business storefront.
///
/// Streams the viewer's own current rating from [RatingService] (so the stars
/// reflect what they previously gave, live across devices) and writes a new
/// rating on tap. Hidden entirely when the viewer IS the business
/// (`raterId == businessId`) — an owner cannot rate their own business.
///
/// Glassy gold row with light haptics per selection.
class BusinessRatingBar extends StatefulWidget {
  const BusinessRatingBar({
    required this.businessId,
    required this.raterId,
    super.key,
    this.onRated,
  });

  final String businessId;
  final String raterId;

  /// Called with the star value after a successful write (e.g. to show a toast).
  final ValueChanged<int>? onRated;

  @override
  State<BusinessRatingBar> createState() => _BusinessRatingBarState();
}

class _BusinessRatingBarState extends State<BusinessRatingBar> {
  final RatingService _service = di.sl<RatingService>();
  bool _busy = false;

  bool get _isSelf => widget.businessId == widget.raterId;

  /// Created on first use and kept (not per build). Never created for a
  /// self-view, which renders nothing.
  late Stream<int?> _mine = _watchMine();

  Stream<int?> _watchMine() => _service.myRating(
        businessId: widget.businessId,
        raterId: widget.raterId,
      );

  @override
  void didUpdateWidget(BusinessRatingBar old) {
    super.didUpdateWidget(old);
    if (old.businessId != widget.businessId || old.raterId != widget.raterId) {
      _mine = _watchMine();
    }
  }

  Future<void> _rate(int stars) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    try {
      await _service.rateBusiness(
        businessId: widget.businessId,
        raterId: widget.raterId,
        stars: stars,
      );
      widget.onRated?.call(stars);
    } catch (_) {
      if (mounted) {
        showUserErrorMessage(
            context, AppLocalizations.of(context)!.businessRatingError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Owner viewing their own storefront: no self-rating control.
    if (_isSelf) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<int?>(
      stream: _mine,
      builder: (context, snap) {
        final mine = snap.data ?? 0;

        // Once the viewer has rated, the "Rate this business" control
        // disappears (the average is still shown by BusinessRatingSummary).
        if (mine > 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.richGold.withOpacity(0.30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.rateThisBusiness,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  final selected = value <= mine;
                  return _StarButton(
                    filled: selected,
                    enabled: !_busy,
                    onTap: () => _rate(value),
                    semanticLabel: l10n.rateStarsSemantic(value),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.filled,
    required this.enabled,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool filled;
  final bool enabled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 30,
            color: filled
                ? AppColors.richGold
                : AppColors.richGold.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}

/// Compact, read-only average-rating display for the storefront header.
///
/// Renders the denormalized average from [RatingService.aggregate] as
/// filled / half / empty gold stars followed by the rater count `(N)`.
/// Shows nothing (empty stars + `(0)`) gracefully when a business has no
/// ratings yet.
class BusinessRatingSummary extends StatefulWidget {
  const BusinessRatingSummary({
    required this.businessId,
    super.key,
    this.starSize = 16,
  });

  final String businessId;
  final double starSize;

  @override
  State<BusinessRatingSummary> createState() => _BusinessRatingSummaryState();
}

class _BusinessRatingSummaryState extends State<BusinessRatingSummary> {
  /// Created once per business (not on every parent rebuild).
  late Stream<({double avg, int count})> _aggregate =
      di.sl<RatingService>().aggregate(widget.businessId);
  ({double avg, int count})? _last;

  String get businessId => widget.businessId;
  double get starSize => widget.starSize;

  @override
  void didUpdateWidget(BusinessRatingSummary old) {
    super.didUpdateWidget(old);
    if (old.businessId != widget.businessId) {
      _aggregate = di.sl<RatingService>().aggregate(widget.businessId);
      _last = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<({double avg, int count})>(
      stream: _aggregate,
      initialData: _last,
      builder: (context, snap) {
        _last = snap.data ?? _last;
        final avg = snap.data?.avg ?? 0;
        final count = snap.data?.count ?? 0;

        return Semantics(
          label: l10n.businessRatingSemantic(
            avg.toStringAsFixed(1),
            count,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(5, (i) => _summaryStar(avg, i)),
              const SizedBox(width: 6),
              Text(
                l10n.businessRatingCount(count),
                style: TextStyle(
                  color: AppColors.richGold.withOpacity(0.85),
                  fontSize: starSize * 0.85,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryStar(double avg, int index) {
    final position = index + 1;
    final IconData icon;
    if (avg >= position) {
      icon = Icons.star_rounded; // fully filled
    } else if (avg >= position - 0.5) {
      icon = Icons.star_half_rounded; // half
    } else {
      icon = Icons.star_outline_rounded; // empty
    }
    return Icon(
      icon,
      size: starSize,
      color: icon == Icons.star_outline_rounded
          ? AppColors.richGold.withOpacity(0.40)
          : AppColors.richGold,
    );
  }
}
