import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// Shown at ticket checkout / experience booking: the buyer's name and email
/// go to the organizer in the participants list (privacy disclosure).
class OrganizerShareNotice extends StatelessWidget {
  const OrganizerShareNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      key: const ValueKey('organizer-share-notice'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l.checkoutOrganizerShareNotice,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
