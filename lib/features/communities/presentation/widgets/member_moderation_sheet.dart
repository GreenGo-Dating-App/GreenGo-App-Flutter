import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community_member.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';

/// Owner/admin moderation actions for a single member. Dispatches
/// [ModerateMember] on [bloc] and closes.
Future<void> showMemberModerationSheet(
  BuildContext context, {
  required CommunitiesBloc bloc,
  required String communityId,
  required CommunityMember member,
  bool canReport = false,
  VoidCallback? onReport,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;

      void act(MemberModerationAction action) {
        bloc.add(ModerateMember(
          communityId: communityId,
          userId: member.userId,
          action: action,
        ));
        Navigator.of(sheetContext).pop();
      }

      Widget tile(IconData icon, String label, VoidCallback onTap,
          {Color color = AppColors.textPrimary}) {
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          onTap: onTap,
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM, vertical: 8),
              child: Text(
                member.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            if (member.role == CommunityRole.admin)
              tile(Icons.arrow_downward, l10n.communitiesDemoteMember,
                  () => act(MemberModerationAction.demoteToMember))
            else
              tile(Icons.arrow_upward, l10n.communitiesPromoteMember,
                  () => act(MemberModerationAction.promoteToAdmin)),
            if (member.isMuted)
              tile(Icons.volume_up, l10n.communitiesUnmuteMember,
                  () => act(MemberModerationAction.unmute))
            else
              tile(Icons.volume_off, l10n.communitiesMuteMember,
                  () => act(MemberModerationAction.mute)),
            tile(Icons.person_remove_outlined, l10n.communitiesRemoveMember,
                () => act(MemberModerationAction.remove),
                color: AppColors.warningAmber),
            tile(Icons.block, l10n.communitiesBanMember,
                () => act(MemberModerationAction.ban),
                color: AppColors.errorRed),
            if (canReport && onReport != null)
              tile(Icons.flag_outlined, l10n.communitiesReportMember, () {
                Navigator.of(sheetContext).pop();
                onReport();
              }, color: AppColors.textSecondary),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
