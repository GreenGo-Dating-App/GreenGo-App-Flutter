import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../domain/entities/booking.dart';
import '../booking_l10n.dart';
import '../widgets/booking_widgets.dart';
import '../widgets/payment_link_actions.dart';
import 'booking_detail_screen.dart';

/// After createBooking: "You're booked!" or "Request sent", what happens
/// next, and how to pay (link / cash at the meeting).
class BookingResultScreen extends StatelessWidget {
  const BookingResultScreen({
    super.key,
    required this.booking,
    required this.experience,
    required this.currentUserId,
  });

  final Booking booking;
  final UserExperience experience;
  final String currentUserId;

  static Route<void> route({
    required Booking booking,
    required UserExperience experience,
    required String currentUserId,
  }) =>
      MaterialPageRoute(
        builder: (_) => BookingResultScreen(
          booking: booking,
          experience: experience,
          currentUserId: currentUserId,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = booking;
    final requested = b.status == BookingStatus.requested;
    final link = b.payment.link ?? experience.paymentLink;
    const muted = TextStyle(color: AppColors.textSecondary, height: 1.4);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l.bkDone,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (requested ? AppColors.warningAmber : AppColors.successGreen)
                    .withValues(alpha: 0.15),
                border: Border.all(
                    color: requested
                        ? AppColors.warningAmber
                        : AppColors.successGreen,
                    width: 2),
              ),
              child: Icon(
                requested ? Icons.hourglass_top_rounded : Icons.check_rounded,
                size: 44,
                color:
                    requested ? AppColors.warningAmber : AppColors.successGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            requested ? l.bkResultRequestTitle : l.bkResultConfirmedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            requested ? l.bkResultRequestBody : l.bkResultConfirmedBody,
            textAlign: TextAlign.center,
            style: muted,
          ),
          const SizedBox(height: 20),
          BookingSection(
            title: b.experienceTitle ?? experience.title,
            icon: Icons.local_activity_outlined,
            children: [
              Text(BookingL10n.range(context, b.slotStart, b.slotEnd),
                  style: const TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                  '${l.bkGuestsCount(b.guests)} · ${b.isFree ? l.uexpFree : BookingL10n.total(context, b.price)}',
                  style: muted),
              if (experience.meetingPoint != null) ...[
                const SizedBox(height: 4),
                Text('${l.uexpMeetingPointLabel}: ${experience.meetingPoint}',
                    style: muted),
              ],
            ],
          ),
          if (!b.isFree)
            BookingSection(
              title: l.bkPayment,
              icon: Icons.payments_outlined,
              children: [
                Text(BookingL10n.paymentMode(l, b.payment.mode),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  b.payment.mode == BookingPaymentMode.cash
                      ? l.bkCashAtMeeting
                      : (requested ? l.bkPayAfterAccept : l.bkPayLinkHint),
                  style: muted,
                ),
                if (b.payment.mode == BookingPaymentMode.link &&
                    !requested &&
                    link != null) ...[
                  const SizedBox(height: 10),
                  BookingPrimaryButton(
                    label: link.isOpenable ? l.bkPayNow : l.bkCopyPixKey,
                    icon: link.isOpenable
                        ? Icons.open_in_new
                        : Icons.copy_rounded,
                    onPressed: () => openBookingPaymentLink(context, link),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 8),
          BookingOutlineButton(
            label: l.bkViewBooking,
            icon: Icons.receipt_long_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              BookingDetailScreen.route(
                bookingId: b.id,
                currentUserId: currentUserId,
                initial: b,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.bkDone,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
