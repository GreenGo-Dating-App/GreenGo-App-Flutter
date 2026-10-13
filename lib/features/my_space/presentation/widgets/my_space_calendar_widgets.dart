import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/gg_calendar.dart';
import '../../../../generated/app_localizations.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../../experience_bookings/presentation/booking_l10n.dart';
import '../../domain/my_space_calendar.dart';
import 'space_widgets.dart';

/// Hosting = gold; going = blue (both calendars).
const Color kMsHostingColor = AppColors.richGold;
const Color kMsGoingColor = AppColors.infoBlue;

/// My Space entries -> [GgCalendarItem]s (the payload is the entry).
class MsCalendarItems {
  const MsCalendarItems._();

  static String tag(AppLocalizations l, MsCalendarRole r) =>
      r == MsCalendarRole.hosting ? l.msCalendarHostingTag : l.msCalendarGoingTag;

  static Color color(MsCalendarRole r) =>
      r == MsCalendarRole.hosting ? kMsHostingColor : kMsGoingColor;

  static GgCalendarItem event(AppLocalizations l, MsEventEntry x) {
    final e = x.event;
    final where = e.locationName.trim();
    return GgCalendarItem(
      id: x.id,
      start: e.startDate.toLocal(),
      end: (e.endDate.isAfter(e.startDate) ? e.endDate : e.startDate)
          .toLocal(),
      title: e.title,
      subtitle: [tag(l, x.role), if (where.isNotEmpty) where].join(' · '),
      imageUrl: x.imageUrl,
      color: color(x.role),
      icon: x.role == MsCalendarRole.hosting
          ? Icons.campaign_outlined
          : Icons.confirmation_number_outlined,
      payload: x,
    );
  }

  static GgCalendarItem experience(
      AppLocalizations l, MsExperienceEntry x, String? photo) {
    return GgCalendarItem(
      id: x.id,
      start: x.start.toLocal(),
      end: (x.end.isAfter(x.start) ? x.end : x.start).toLocal(),
      title: x.title.isEmpty ? l.bkDetailTitle : x.title,
      subtitle: [
        tag(l, x.role),
        l.dcGuestsBooked(x.guests),
        if (x.onlyRequested) BookingL10n.status(l, BookingStatus.requested),
      ].join(' · '),
      imageUrl: photo,
      color: color(x.role),
      icon: Icons.explore_outlined,
      filled: !x.onlyRequested,
      payload: x,
    );
  }
}

/// All / I host / I'm going.
class MsCalendarFilterChips extends StatelessWidget {
  const MsCalendarFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MsCalendarFilter value;
  final ValueChanged<MsCalendarFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget chip(MsCalendarFilter f, String label, Color? dot) {
      final on = f == value;
      return ChoiceChip(
        key: ValueKey('ms-cal-filter-${f.name}'),
        selected: on,
        showCheckmark: false,
        onSelected: (_) => onChanged(f),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: AppColors.backgroundCard,
        selectedColor: AppColors.richGold.withValues(alpha: 0.22),
        side: BorderSide(
            color: on
                ? AppColors.richGold
                : AppColors.richGold.withValues(alpha: 0.2)),
        avatar: dot == null
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: dot, shape: BoxShape.circle)),
        label: Text(label,
            style: TextStyle(
                color: on ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      );
    }

    // One line (scrolls sideways on tiny / large-font screens) so the grid
    // keeps its height.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      child: Row(children: [
        chip(MsCalendarFilter.all, l.msFilterAll, null),
        const SizedBox(width: 6),
        chip(MsCalendarFilter.hosting, l.msFilterHosting, kMsHostingColor),
        const SizedBox(width: 6),
        chip(MsCalendarFilter.going, l.msFilterGoing, kMsGoingColor),
      ]),
    );
  }
}

/// The calendar card of a My Space tab: header (title + full screen), the
/// calendar at a fixed height, and the gesture hint.
class MsCalendarCard extends StatelessWidget {
  const MsCalendarCard({
    super.key,
    required this.calendar,
    required this.onFullScreen,
    this.error,
  });

  final Widget calendar;
  final VoidCallback onFullScreen;

  /// Shown above the calendar (a failed load), if any.
  final Widget? error;

  /// min(560, 75% of the screen).
  static double heightFor(BuildContext context) =>
      math.min(560, MediaQuery.sizeOf(context).height * 0.75);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpaceSectionHeader(
          title: l.msCalendarTitle,
          icon: Icons.calendar_month_outlined,
          trailing: IconButton(
            key: const ValueKey('ms-cal-fullscreen'),
            tooltip: l.calFullScreen,
            icon: const Icon(Icons.open_in_full, color: AppColors.richGold),
            onPressed: onFullScreen,
          ),
        ),
        if (error != null) error!,
        SpaceCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(height: heightFor(context), child: calendar),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Text(l.calGesturesHint,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ),
      ],
    );
  }
}
