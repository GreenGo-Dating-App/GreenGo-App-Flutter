import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../data/services/leads_service.dart';

/// "Contact this business" button.
///
/// Opens an instant one-to-one chat with the business (reusing the existing
/// [openConnectChat] helper — same immediate, no-approval search conversation
/// used everywhere else in the Apple-safe build) AND logs a `contact` lead via
/// [LeadsService] so the business can see who reached out. The lead write is
/// fire-and-forget; a failure never blocks opening the chat.
class BusinessContactButton extends StatelessWidget {
  const BusinessContactButton({
    required this.businessProfile,
    required this.currentUserId,
    super.key,
    this.compact = false,
  });

  final Profile businessProfile;
  final String currentUserId;
  final bool compact;

  bool get _isSelf => businessProfile.userId == currentUserId;

  void _onTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Log the lead (best-effort, non-blocking).
    unawaited(
      di.sl<LeadsService>().logContactLead(
            businessId: businessProfile.userId,
            uid: currentUserId,
          ),
    );
    openConnectChat(
      context,
      currentUserId: currentUserId,
      otherUserId: businessProfile.userId,
      otherUserProfile: businessProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelf) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: compact ? 16 : 18,
                color: AppColors.richGold,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.businessContact,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
