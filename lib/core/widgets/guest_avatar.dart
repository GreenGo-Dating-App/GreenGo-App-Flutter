import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

export '../utils/guest_identity.dart' show isGuestUserId, isDeletedUserId;

/// The generic guest avatar: a neutral person outline on a muted disc.
class GuestAvatar extends StatelessWidget {
  const GuestAvatar({super.key, this.radius = 16});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.backgroundInput,
      child: Icon(
        Icons.person_outline,
        size: radius * 1.1,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// Small "Guest" chip shown next to a guest's name.
class GuestLabel extends StatelessWidget {
  const GuestLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.6)),
      ),
      child: Text(
        AppLocalizations.of(context)!.guestLabel,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Neutral avatar + the localized "Deleted user" for someone who deleted
/// their account (no profile, never tappable).
class DeletedUserNameAvatar extends StatelessWidget {
  const DeletedUserNameAvatar({super.key, this.radius = 16, this.textStyle});

  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GuestAvatar(radius: radius),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            l.deletedUserName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle ??
                const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }
}

/// Avatar + "First Last" + the Guest chip. Deliberately NOT tappable: a
/// guest has no profile to open.
class GuestNameAvatar extends StatelessWidget {
  const GuestNameAvatar({
    super.key,
    required this.name,
    this.radius = 16,
    this.textStyle,
  });

  /// "First Last" from the booking / attendee doc (falls back to "Guest").
  final String? name;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final shown =
        (name?.trim().isNotEmpty ?? false) ? name!.trim() : l.guestLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GuestAvatar(radius: radius),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            shown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle ??
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 6),
        const GuestLabel(),
      ],
    );
  }
}
