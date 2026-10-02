import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../../domain/booking_failure.dart';
import '../../domain/entities/booking.dart';
import '../booking_l10n.dart';

/// Coloured status label.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = BookingL10n.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(BookingL10n.status(l, status),
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

/// A guest's rating from hosts (profiles.guestRating*, server-owned), shown
/// to hosts on booking requests. "New guest" until the first visible review.
class GuestRatingBadge extends StatelessWidget {
  const GuestRatingBadge({super.key, required this.guestId});
  final String guestId;

  /// Pure formatter (unit-tested).
  static String label(AppLocalizations l, String locale,
      {required int count, required double avg}) {
    if (count <= 0) return l.bkNewGuest;
    String avgText;
    String countText;
    try {
      avgText = NumberFormat('0.0', locale).format(avg);
      countText = NumberFormat.compact(locale: locale).format(count);
    } catch (_) {
      avgText = avg.toStringAsFixed(1);
      countText = '$count';
    }
    return '$avgText · ${l.uexpHostRatings(count, countText)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(guestId);
        if (brief == null) {
          UserDirectoryService.instance.resolve([guestId]);
          return const SizedBox.shrink();
        }
        final count = brief.guestRatingCount;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(count > 0 ? Icons.star_rounded : Icons.fiber_new_rounded,
              size: 14, color: AppColors.richGold),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label(l, locale, count: count, avg: brief.guestRatingAvg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                      count > 0 ? AppColors.textSecondary : AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ]);
      },
    );
  }
}

/// The other party of a booking: name + avatar (never the uid), the
/// Verified badge, and — for hosts looking at a guest — the guest rating.
class BookingPartyRow extends StatelessWidget {
  const BookingPartyRow({
    super.key,
    required this.uid,
    this.showGuestRating = false,
    this.onTap,
    this.radius = 16,
  });

  final String uid;
  final bool showGuestRating;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        UserNameAvatar(
          uid: uid,
          radius: radius,
          onTap: onTap,
          trailing: UserVerifiedBadge(uid: uid, size: 14),
        ),
        if (showGuestRating)
          Padding(
            padding: EdgeInsets.only(left: radius * 2 + 8, top: 2),
            child: GuestRatingBadge(guestId: uid),
          ),
      ],
    );
  }
}

/// One row of a bookings list.
class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.currentUserId,
    required this.onTap,
  });

  final Booking booking;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = booking;
    final asHost = b.isHost(currentUserId);
    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: b.status == BookingStatus.requested && asHost
                ? AppColors.warningAmber.withValues(alpha: 0.6)
                : AppColors.richGold.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(
                    b.experienceTitle ?? l.bkDetailTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                BookingStatusChip(status: b.status),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.event, size: 15, color: AppColors.richGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    BookingL10n.range(context, b.slotStart, b.slotEnd),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.groups_outlined,
                    size: 15, color: AppColors.richGold),
                const SizedBox(width: 6),
                Text(l.bkGuestsCount(b.guests),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text(
                  b.isFree ? l.uexpFree : BookingL10n.total(context, b.price),
                  style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 8),
              BookingPartyRow(
                uid: b.counterpartOf(currentUserId),
                showGuestRating: asHost,
                radius: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error snackbar for a booking refusal.
void showBookingFailure(BuildContext context, BookingFailure f) {
  final l = AppLocalizations.of(context)!;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(BookingL10n.error(l, f)),
    backgroundColor: AppColors.errorRed,
  ));
}

void showBookingSnack(BuildContext context, String msg) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: AppColors.successGreen,
  ));
}

/// A titled card section of the booking pages.
class BookingSection extends StatelessWidget {
  const BookingSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });
  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.richGold),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Gold primary button with a FINITE minimum size (the app theme's
/// ElevatedButton minimumSize is infinitely wide, which breaks Rows).
class BookingPrimaryButton extends StatelessWidget {
  const BookingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.color = AppColors.richGold,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.deepBlack))
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppColors.deepBlack,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    return icon == null || busy
        ? ElevatedButton(
            style: style, onPressed: busy ? null : onPressed, child: child)
        : ElevatedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: child);
  }
}

class BookingOutlineButton extends StatelessWidget {
  const BookingOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.richGold,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.8)),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
    final text = busy
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color))
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return icon == null || busy
        ? OutlinedButton(
            style: style, onPressed: busy ? null : onPressed, child: text)
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: text);
  }
}
