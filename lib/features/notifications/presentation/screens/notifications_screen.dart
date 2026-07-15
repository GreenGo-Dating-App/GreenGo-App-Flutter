import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../chat/presentation/screens/group_chat_screen.dart';
import '../../../chat/presentation/screens/support_chat_screen.dart';
import '../../../communities/domain/repositories/communities_repository.dart';
import '../../../communities/presentation/bloc/communities_bloc.dart';
import '../../../communities/presentation/screens/community_detail_screen.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

/// Notifications Screen — the app's notifications hub.
///
/// Streams the user's 100 most-recent notifications (newest first), highlights
/// unread rows with a subtle gold tint + dot, marks a row read on tap, then
/// routes to the relevant destination (chat / event / community / profile).
/// Glass, Apple-safe design.
class NotificationsScreen extends StatefulWidget {

  const NotificationsScreen({
    required this.userId, super.key,
  });
  final String userId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Alias so the existing helper methods keep reading `userId` directly.
  String get userId => widget.userId;

  /// Guards the one-time notifications mini-tour within a session.
  bool _tourChecked = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => di.sl<NotificationsBloc>()
        ..add(NotificationsLoadRequested(userId: userId, limit: 100)),
      child: ShowCaseWidget(
        builder: (showcaseContext) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          title: TourShowcase(
            showcaseKey: TourKeys.notifHub,
            title: l10n.tourNotifHubTitle,
            description: l10n.tourNotifHubDesc,
            child: Text(
              l10n.notificationsTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is NotificationsLoaded && state.unreadCount > 0) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TourShowcase(
                        showcaseKey: TourKeys.notifMarkAll,
                        title: l10n.tourNotifMarkAllTitle,
                        description: l10n.tourNotifMarkAllDesc,
                        gesture: TourGesture.tap,
                        child: TextButton(
                          onPressed: () {
                            context.read<NotificationsBloc>().add(
                                  NotificationsMarkedAllAsRead(userId),
                                );
                          },
                          child: Text(
                            l10n.notificationMarkAllRead,
                            style: const TextStyle(color: AppColors.richGold),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.notificationsDeleteUnread,
                        icon: const Icon(Icons.delete_sweep_outlined,
                            color: AppColors.textSecondary),
                        onPressed: () => _confirmDeleteUnread(context, l10n),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }

            if (state is NotificationsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NotificationsBloc>().add(
                              NotificationsLoadRequested(
                                userId: userId,
                                limit: 100,
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                      ),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.notificationsEmpty,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoaded) {
              // One-time notifications mini-tour, started once the list has
              // actually rendered so the first row (and mark-all) are anchored.
              if (!_tourChecked && state.notifications.isNotEmpty) {
                _tourChecked = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  TourController.instance.maybeStartMiniTour(
                    context,
                    tourId: TourController.notificationsTourId,
                    userId: userId,
                    keys: [
                      TourKeys.notifHub,
                      TourKeys.notifFirstItem,
                      TourKeys.notifMarkAll,
                    ],
                  );
                });
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationsBloc>().add(
                        NotificationsLoadRequested(
                          userId: userId,
                          limit: 100,
                        ),
                      );
                },
                color: AppColors.richGold,
                backgroundColor: AppColors.backgroundCard,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider.withOpacity(0.3),
                  ),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    final tile = _NotificationTile(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          context.read<NotificationsBloc>().add(
                                NotificationMarkedAsRead(
                                  notification.notificationId,
                                ),
                              );
                        }
                        _handleNotificationTap(context, notification);
                      },
                      onDismiss: () {
                        context.read<NotificationsBloc>().add(
                              NotificationDeleted(notification.notificationId),
                            );
                      },
                      onOpenActor: (notification.actorId != null &&
                              notification.actorId!.isNotEmpty)
                          ? () => _openProfile(context, notification.actorId!)
                          : null,
                    );
                    if (index == 0) {
                      return TourShowcase(
                        showcaseKey: TourKeys.notifFirstItem,
                        title: l10n.tourNotifOpenTitle,
                        description: l10n.tourNotifOpenDesc,
                        gesture: TourGesture.swipeLeft,
                        child: tile,
                      );
                    }
                    return tile;
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      ),
    );
  }

  /// Routes a tapped notification to its destination based on `data['action']`
  /// and the notification [NotificationType]. Unknown targets are a no-op.
  void _handleNotificationTap(
      BuildContext context, NotificationEntity notification) {
    final data = notification.data ?? const <String, dynamic>{};
    final action = (data['action'] as String?)?.toLowerCase();
    final type = notification.type;

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    }

    // Support chat — existing behavior, preserved.
    if (action == 'support_message') {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupportChatScreen(
              conversationId: conversationId,
              currentUserId: userId,
            ),
          ),
        );
      }
      return;
    }

    // Profile — profile view, like, super-like and match all open the actor's
    // profile. (Likes store the actor under `likerId`, matches under
    // `matchedUserId`; both were previously unrouted → dead taps.)
    if (action == 'profile' ||
        action == 'profile_view' ||
        action == 'open_profile' ||
        type == NotificationType.profileView ||
        type == NotificationType.newLike ||
        type == NotificationType.superLike ||
        type == NotificationType.newMatch ||
        type == NotificationType.businessFollow ||
        type == NotificationType.businessRating ||
        type == NotificationType.qrScanned) {
      final actor = notification.actorId;
      final profileId = (actor != null && actor.isNotEmpty)
          ? actor
          : pick([
              'profileId',
              'targetUserId',
              'likerId',
              'matchedUserId',
              'fromUserId',
              'senderId',
              'userId',
            ]);
      if (profileId != null && profileId != userId) {
        _openProfile(context, profileId);
      }
      return;
    }

    // Event detail.
    final eventId = pick(['eventId']);
    if (action == 'event' || eventId != null) {
      if (eventId != null) {
        Navigator.of(context).push(
          EventDetailLoaderScreen.route(
            eventId: eventId,
            currentUserId: userId,
          ),
        );
      }
      return;
    }

    // COMMUNITY — must be checked BEFORE group. A community notification carries
    // `communityId` (+ action open_community/community/community_join/…). It was
    // previously lumped into the group branch (communityId used as a groupId),
    // which opened a bogus "unknown group" instead of the community.
    final communityId = pick(['communityId']);
    if (action == 'community' ||
        action == 'open_community' ||
        communityId != null) {
      if (communityId != null) {
        _openCommunity(context, communityId);
      }
      return;
    }

    // GROUP chat — only a genuine group (groupId / group action).
    final groupId = pick(['groupId']);
    if (action == 'group' || action == 'open_group' || groupId != null) {
      if (groupId != null) {
        Navigator.of(context).push(
          GroupChatScreen.route(
            groupId: groupId,
            groupName: (data['groupName'] as String?) ?? '',
            currentUserId: userId,
            groupPhotoUrl: data['groupPhotoUrl'] as String?,
          ),
        );
      }
      return;
    }

    // Chat / exchange (one-to-one). Apple-safe: opens instantly, no approval.
    final otherUserId = pick(['otherUserId', 'fromUserId', 'senderId']);
    if (otherUserId != null && otherUserId != userId) {
      openConnectChat(
        context,
        currentUserId: userId,
        otherUserId: otherUserId,
      );
      return;
    }

    // Actor-attributed fallback: any remaining notification that carries an
    // actor (or a profileId) but no specific target → open that person's profile.
    // Catches actor-based types whose action/keys weren't matched above.
    final actorFallback =
        notification.actorId ?? pick(['profileId', 'actorId']);
    if (actorFallback != null && actorFallback != userId) {
      _openProfile(context, actorFallback);
      return;
    }

    // Unknown target — no-op.
  }

  /// Confirm, then permanently delete all UNREAD notifications.
  Future<void> _confirmDeleteUnread(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final bloc = context.read<NotificationsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.notificationsDeleteUnread,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.notificationsDeleteUnreadConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(
                  color: AppColors.errorRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(NotificationsUnreadCleared(userId));
    }
  }

  /// Loads a community by id then opens [CommunityDetailScreen] (wrapped with its
  /// blocs). Silent on failure.
  Future<void> _openCommunity(
      BuildContext context, String communityId) async {
    final navigator = Navigator.of(context);
    final result =
        await di.sl<CommunitiesRepository>().getCommunityById(communityId);
    final community = result.fold((_) => null, (c) => c);
    if (community == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>(
              create: (_) => di.sl<CommunitiesBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()
                ..add(ProfileLoadRequested(userId: userId)),
            ),
          ],
          child: CommunityDetailScreen(community: community),
        ),
      ),
    );
  }

  /// Loads a profile then opens [ProfileDetailScreen]. Silent on failure.
  Future<void> _openProfile(BuildContext context, String profileId) async {
    final navigator = Navigator.of(context);
    final result = await di.sl<ProfileRepository>().getProfile(profileId);
    final profile = result.fold((_) => null, (p) => p);
    if (profile == null) return;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: userId,
        ),
      ),
    );
  }
}

/// A single notification row: leading image (with icon fallback), title, body,
/// relative time, unread gold tint + dot. Swipe-to-dismiss deletes the row.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.onOpenActor,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  /// Opens the actor's profile (name-tap / avatar-tap). Null when there's no
  /// actor to open (system / no-actor notifications).
  final VoidCallback? onOpenActor;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: unread
              ? AppColors.richGold.withOpacity(0.06)
              : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar → actor profile when there's an actor.
              GestureDetector(onTap: onOpenActor, child: _buildLeading()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(context, unread),
                    const SizedBox(height: 4),
                    Text(
                      _resolveL10n(context, notification.message),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeSinceText,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.richGold,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Title with the actor's nickname rendered BOLD + tappable (opens their
  /// profile). Falls back to a plain title when there's no actor (legacy docs
  /// or system notifications with the name baked into the title).
  Widget _buildTitle(BuildContext context, bool unread) {
    final title = _resolveL10n(context, notification.title);
    final actor = notification.actorName?.trim();
    final baseStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: unread ? FontWeight.bold : FontWeight.w500,
    );
    if (actor == null || actor.isEmpty || onOpenActor == null) {
      return Text(title, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: onOpenActor,
              child: Text(
                actor,
                style: baseStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.richGold,
                ),
              ),
            ),
          ),
          if (title.isNotEmpty) TextSpan(text: ' $title'),
        ],
      ),
    );
  }

  Widget _buildLeading() {
    final imageUrl = notification.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => _iconAvatar(),
          errorWidget: (_, __, ___) => _iconAvatar(),
        ),
      );
    }
    return _iconAvatar();
  }

  Widget _iconAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.richGold.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_iconForType(notification.type),
          color: AppColors.richGold, size: 24),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMatch:
        return Icons.favorite;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.newLike:
        return Icons.thumb_up;
      case NotificationType.profileView:
        return Icons.visibility;
      case NotificationType.superLike:
        return Icons.star;
      case NotificationType.matchExpiring:
        return Icons.schedule;
      case NotificationType.promotional:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.newChat:
        return Icons.forum;
      case NotificationType.coinsPurchased:
        return Icons.monetization_on;
      case NotificationType.progressAchieved:
        return Icons.emoji_events;
      case NotificationType.gameInvite:
        return Icons.sports_esports;
      case NotificationType.newEvent:
      case NotificationType.communityEvent:
      case NotificationType.communityEventChanged:
      case NotificationType.eventJoin:
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.groupMessage:
      case NotificationType.groupAdd:
      case NotificationType.groupJoin:
        return Icons.groups;
      case NotificationType.communityJoin:
      case NotificationType.communityAnnouncement:
      case NotificationType.eventAnnouncement:
        return Icons.campaign;
      case NotificationType.eventLike:
        return Icons.thumb_up;
      case NotificationType.qrScanned:
        return Icons.qr_code;
      case NotificationType.businessFollow:
        return Icons.person_add;
      case NotificationType.businessRating:
        return Icons.star;
      case NotificationType.boostStarted:
      case NotificationType.boostEnded:
        return Icons.rocket_launch;
    }
  }

  /// Resolve `l10n:key` prefixed strings to localized text.
  String _resolveL10n(BuildContext context, String text) {
    if (!text.startsWith('l10n:')) return text;
    final key = text.substring(5);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return text;
    switch (key) {
      case 'priorityConnectNotificationTitle':
        return l10n.priorityConnectNotificationTitle;
      case 'priorityConnectNotificationMessage':
        return l10n.priorityConnectNotificationMessage;
      default:
        return text;
    }
  }
}
