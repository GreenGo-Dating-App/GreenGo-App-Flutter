import 'package:flutter/material.dart';

import '../../../safety/presentation/widgets/report_block_sheet.dart';

/// Report a community member or a community post's author.
///
/// Thin wrapper over the app-wide [showReportBlockSheet] so community reports
/// carry the community (and optional post) they came from. Blocking is not
/// offered here: leaving a community is the proportionate action, and a
/// community-wide block is the moderators' job, not a reader's.
Future<void> showCommunityReportSheet(
  BuildContext context, {
  required String reporterId,
  required String reportedUserId,
  required String reportedUserName,
  required String communityId,
  String? contentId,
}) {
  return showReportBlockSheet(
    context,
    reporterId: reporterId,
    reportedUserId: reportedUserId,
    reportedUserName: reportedUserName,
    surface: 'community:$communityId',
    contentId: contentId,
    allowBlock: false,
  );
}
