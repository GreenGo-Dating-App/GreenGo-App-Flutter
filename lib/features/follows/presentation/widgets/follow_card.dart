import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';
import '../screens/follow_list_screen.dart';

/// Profile "Followers | Following" summary — numbers + tiny photos:
///
/// ```
///   (o)(o)(o)  128   |   64
///          Followers | Following
/// ```
///
/// No card background. Each block is a big compact number with a small label
/// under it; the Followers block also shows up to [maxAvatars] tiny
/// overlapping photos of the newest followers. Tapping a block opens
/// [FollowListScreen] on that tab.
///
/// Reads, per profile view (bounded, never a scan):
///  * ONE single-doc listener on the profile counters ([FollowService.counts]),
///  * ONE `limit(3)` followers query (newest first), fetched once and
///    refetched only when the follower counter changes (at most every
///    [refetchEvery]),
///  * photos through [UserDirectoryService] (batched, cache-first),
///  * the viewer's blocked ids once (same as the list screen).
///
/// When [controller] is given (the one driving the profile's
/// `UserFollowButton`), the follower figure follows the optimistic toggle.
class FollowCard extends StatefulWidget {
  const FollowCard({
    required this.userId,
    required this.currentUserId,
    super.key,
    this.controller,
    this.directory,
    this.ringColor = AppColors.backgroundDark,
  });

  final String userId;
  final String currentUserId;
  final FollowToggleController? controller;

  /// Defaults to [UserDirectoryService.instance] (injectable for tests).
  final UserDirectoryService? directory;

  /// The surface behind the card: the ring that separates the overlapping
  /// photos is painted in it.
  final Color ringColor;

  static const int maxAvatars = 3;

  /// A popular account's counter can tick every second: the "recent people"
  /// query is refreshed at most this often.
  static const Duration refetchEvery = Duration(seconds: 30);

  /// Fixed height: loading → loaded never moves the layout.
  static const double height = 56;

  @override
  State<FollowCard> createState() => _FollowCardState();
}

class _FollowCardState extends State<FollowCard> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts? _counts;

  /// Newest followers (blocked users already removed).
  List<String> _ids = const [];
  int? _fetchedForCount;
  DateTime? _fetchedAt;
  bool _fetching = false;
  Future<Set<String>>? _blocked;
  Timer? _retry;

  FollowService get _service => di.sl<FollowService>();
  UserDirectoryService get _directory =>
      widget.directory ?? UserDirectoryService.instance;

  @override
  void initState() {
    super.initState();
    _directory.addListener(_onChanged);
    widget.controller?.addListener(_onChanged);
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (widget.userId.isEmpty) return;
    _sub = _service.counts(widget.userId).listen(
      (c) {
        widget.controller?.syncFromServer(followers: c.followers);
        if (!mounted) return;
        setState(() => _counts = c);
        _maybeFetch(c.followers);
      },
      // Counters unreadable: still show the newest followers once.
      onError: (_) => _maybeFetch(0),
    );
  }

  Future<Set<String>> _blockedIds() => _blocked ??= () async {
        try {
          if (di.sl.isRegistered<BlockedUsersService>() &&
              widget.currentUserId.isNotEmpty) {
            return await di
                .sl<BlockedUsersService>()
                .getBlockedUserIds(widget.currentUserId);
          }
        } catch (_) {/* no blocks known */}
        return const <String>{};
      }();

  /// Fetch the newest followers when the counter changed since the last
  /// fetch (throttled to [FollowCard.refetchEvery]). No query at all for 0.
  void _maybeFetch(int count) {
    if (_fetching || _fetchedForCount == count) return;
    if (count <= 0 && _counts != null) {
      _ids = const [];
      _fetchedForCount = count;
      return;
    }
    final last = _fetchedAt;
    if (last != null) {
      final wait = FollowCard.refetchEvery - DateTime.now().difference(last);
      if (wait > Duration.zero) {
        _retry ??= Timer(wait, () {
          _retry = null;
          final c = _counts;
          if (!mounted || c == null) return;
          _maybeFetch(c.followers);
        });
        return;
      }
    }
    unawaited(_fetch(count));
  }

  Future<void> _fetch(int count) async {
    _fetching = true;
    try {
      final pageF =
          _service.followersPage(widget.userId, limit: FollowCard.maxAvatars);
      final blocked = await _blockedIds();
      final page = await pageF;
      final ids = page.userIds
          .where((id) => id.isNotEmpty && !blocked.contains(id))
          .toList();
      if (ids.isNotEmpty) await _directory.resolve(ids);
      _ids = ids;
      _fetchedForCount = count;
      _fetchedAt = DateTime.now();
    } catch (_) {
      _fetchedAt = DateTime.now(); // retry on the next counter change
    } finally {
      _fetching = false;
      if (mounted) setState(() {});
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant FollowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onChanged);
      widget.controller?.addListener(_onChanged);
    }
    if (oldWidget.directory != widget.directory) {
      (oldWidget.directory ?? UserDirectoryService.instance)
          .removeListener(_onChanged);
      _directory.addListener(_onChanged);
    }
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentUserId != widget.currentUserId) {
      _counts = null;
      _blocked = null;
      _ids = const [];
      _fetchedForCount = null;
      _fetchedAt = null;
      _listen();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _retry?.cancel();
    _directory.removeListener(_onChanged);
    widget.controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _open(int tab) {
    Navigator.of(context).push(
      FollowListScreen.route(
        userId: widget.userId,
        currentUserId: widget.currentUserId,
        initialTab: tab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final c = _counts;
    final loading = c == null;
    final followers = widget.controller?.followers ?? c?.followers ?? 0;
    final following = c?.following ?? 0;
    String fmt(int v) => formatCompactCount(v, locale: locale);

    // Hidden when the account is deleted / inactive; none when 0.
    final photos = followers <= 0
        ? const <String>[]
        : _ids
            .where((id) {
              final b = _directory.cached(id);
              return b == null || b.isActive;
            })
            .take(FollowCard.maxAvatars)
            .toList();

    return SizedBox(
      key: const Key('follow_card'),
      height: FollowCard.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _FollowBlock(
              key: const Key('follow_card_followers'),
              number: loading ? '–' : fmt(followers),
              label: l10n.userFollowCardFollowersLabel(followers),
              semanticsLabel: loading
                  ? l10n.userFollowTabFollowers
                  : l10n.userFollowFollowersStat(followers, fmt(followers)),
              leading: photos.isEmpty
                  ? null
                  : _AvatarStack(
                      photoUrls: [
                        for (final id in photos)
                          _directory.cached(id)?.photoUrl
                      ],
                      ringColor: widget.ringColor,
                    ),
              onTap: () => _open(0),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.textTertiary.withOpacity(0.25),
          ),
          Flexible(
            child: _FollowBlock(
              key: const Key('follow_card_following'),
              number: loading ? '–' : fmt(following),
              label: l10n.userFollowTabFollowing,
              semanticsLabel: loading
                  ? l10n.userFollowTabFollowing
                  : l10n.userFollowFollowingStat(following, fmt(following)),
              onTap: () => _open(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable "number over label" block (optional tiny photos on the left).
class _FollowBlock extends StatelessWidget {
  const _FollowBlock({
    required this.number,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
    this.leading,
  });

  final String number;
  final String label;
  final String semanticsLabel;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        number,
                        key: const Key('follow_card_count'),
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to 3 tiny overlapping round photos, newest first (leftmost on top).
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.photoUrls, required this.ringColor});

  final List<String?> photoUrls;
  final Color ringColor;

  static const double size = 20;
  static const double overlap = 7;

  @override
  Widget build(BuildContext context) {
    final n = photoUrls.length;
    return SizedBox(
      key: const Key('follow_card_avatars'),
      height: size,
      width: size + (n - 1) * (size - overlap),
      child: Stack(
        children: [
          // Painted last-to-first so the newest sits on top.
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              left: i * (size - overlap),
              child: _Avatar(photoUrl: photoUrls[i], ringColor: ringColor),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.ringColor});

  final String? photoUrl;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final has = url != null && url.isNotEmpty;
    return Container(
      width: _AvatarStack.size,
      height: _AvatarStack.size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
      child: CircleAvatar(
        backgroundColor: AppColors.richGold.withOpacity(0.15),
        backgroundImage: has ? CachedNetworkImageProvider(url) : null,
        child: has
            ? null
            : const Icon(Icons.person, size: 11, color: AppColors.richGold),
      ),
    );
  }
}
