import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';

/// Owner/admin sheet listing pending join requests for a private community,
/// with Approve / Reject actions. Reads the live [CommunityDetailLoaded] state.
class JoinRequestsSheet extends StatelessWidget {
  const JoinRequestsSheet({required this.communityId, super.key});

  final String communityId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.communitiesJoinRequestsTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: BlocBuilder<CommunitiesBloc, CommunitiesState>(
                builder: (context, state) {
                  final requests = state is CommunityDetailLoaded
                      ? state.pendingRequests
                      : const [];
                  if (requests.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.communitiesNoJoinRequests,
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final hasPhoto =
                          r.photoUrl != null && r.photoUrl!.isNotEmpty;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          backgroundImage: hasPhoto
                              ? CachedNetworkImageProvider(r.photoUrl!)
                              : null,
                          child: hasPhoto
                              ? null
                              : Text(r.displayName.isNotEmpty
                                  ? r.displayName[0].toUpperCase()
                                  : '?'),
                        ),
                        title: Text(
                          r.displayName,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: AppColors.successGreen),
                              tooltip: l10n.communitiesApprove,
                              onPressed: () =>
                                  context.read<CommunitiesBloc>().add(
                                        ApproveJoinRequest(
                                          communityId: communityId,
                                          userId: r.userId,
                                        ),
                                      ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: AppColors.errorRed),
                              tooltip: l10n.communitiesReject,
                              onPressed: () =>
                                  context.read<CommunitiesBloc>().add(
                                        RejectJoinRequest(
                                          communityId: communityId,
                                          userId: r.userId,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
