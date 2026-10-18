import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../follow_toggle_controller.dart';
import '../screens/follow_list_screen.dart';

/// Profile "Followers | Following" card: two side-by-side tiles, each with a
/// big compact count, up to [maxAvatars] overlapping avatars of the most
/// recent people (newest first) and a "Maria, João and 10 others" line.
/// Tapping a tile opens [FollowListScreen] on that tab.
///
/// Reads, per profile view (bounded, never a scan):
///  * ONE single-doc listener on the profile counters ([FollowService.counts]),
///  * ONE `limit(4)` query per tile (newest first), fetched once and refetched
///    only when that tile's counter changes (at most every [refetchEvery]),
///  * names/photos through [UserDirectoryService] (batched, cache-first),
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
  });

  final String userId;
  final String currentUserId;
  final FollowToggleController? controller;

  /// Defaults to [UserDirectoryService.instance] (injectable for tests).
  final UserDirectoryService? directory;

  static const int maxAvatars = 4;

  /// A popular account's counter can tick every second: the "recent people"
  /// query is refreshed at most this often per tile.
  static const Duration refetchEvery = Duration(seconds: 30);

  @override
  State<FollowCard> createState() => _FollowCardState();
}

class _TileData {
  _TileData();

  /// Recent people (newest first), blocked users already removed.
  List<String> ids = const [];
  bool loaded = false;
  int? fetchedForCount;
  DateTime? fetchedAt;
  bool fetching = false;
}

class _FollowCardState extends State<FollowCard> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts? _counts;
  final _TileData _followers = _TileData();
  final _TileData _following = _TileData();
  Future<Set<String>>? _blocked;
  Timer? _retry;

  FollowService get _service => di.sl<FollowService>();
  UserDirectoryService get _directory =>
      widget.directory ?? UserDirectoryService.instance;

  bool get _isOwn => widget.userId == widget.currentUserId;

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
        _maybeFetch(_followers, c.followers, followersTile: true);
        _maybeFetch(_following, c.following, followersTile: false);
      },
      onError: (_) {
        // Counters unreadable: still show the recent people once.
        _maybeFetch(_followers, 0, followersTile: true);
        _maybeFetch(_following, 0, followersTile: false);
      },
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

  /// Fetch the recent people of one tile when its counter changed since the
  /// last fetch (throttled to [FollowCard.refetchEvery]).
  void _maybeFetch(_TileData t, int count, {required bool followersTile}) {
    if (t.fetching || t.fetchedForCount == count) return;
    final last = t.fetchedAt;
    if (last != null) {
      final wait = FollowCard.refetchEvery - DateTime.now().difference(last);
      if (wait > Duration.zero) {
        _retry ??= Timer(wait, () {
          _retry = null;
          final c = _counts;
          if (!mounted || c == null) return;
          _maybeFetch(_followers, c.followers, followersTile: true);
          _maybeFetch(_following, c.following, followersTile: false);
        });
        return;
      }
    }
    unawaited(_fetch(t, count, followersTile: followersTile));
  }

  Future<void> _fetch(_TileData t, int count,
      {required bool followersTile}) async {
    t.fetching = true;
    try {
      final pageF = followersTile
          ? _service.followersPage(widget.userId, limit: FollowCard.maxAvatars)
          : _service.followingPage(widget.userId, limit: FollowCard.maxAvatars);
      final blocked = await _blockedIds();
      final page = await pageF;
      final ids = page.userIds
          .where((id) => id.isNotEmpty && !blocked.contains(id))
          .toList();
      if (ids.isNotEmpty) await _directory.resolve(ids);
      t
        ..ids = ids
        ..fetchedForCount = count
        ..fetchedAt = DateTime.now();
    } catch (_) {
      t.fetchedAt = DateTime.now(); // retry on the next counter change
    } finally {
      t
        ..fetching = false
        ..loaded = true;
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
      for (final t in [_followers, _following]) {
        t
          ..ids = const []
          ..loaded = false
          ..fetchedForCount = null
          ..fetchedAt = null;
      }
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

  /// Visible recent people: hidden when the account is deleted / inactive.
  List<String> _visible(_TileData t) => t.ids.where((id) {
        final b = _directory.cached(id);
        return b == null || b.isActive;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = _counts;
    final followers = widget.controller?.followers ?? c?.followers ?? 0;
    final following = c?.following ?? 0;

    return Container(
      key: const Key('follow_card'),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withOpacity(0.18)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _FollowTile(
                key: const Key('follow_card_followers'),
                count: followers,
                label: l10n.userFollowCardFollowersLabel(followers),
                ids: _visible(_followers),
                directory: _directory,
                loading: c == null || !_followers.loaded,
                emptyText: l10n.userFollowEmptyFollowers,
                showShare: _isOwn,
                shareUserId: widget.userId,
                onTap: () => _open(0),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 14,
              endIndent: 14,
              color: AppColors.divider,
            ),
            Expanded(
              child: _FollowTile(
                key: const Key('follow_card_following'),
                count: following,
                label: l10n.userFollowTabFollowing,
                ids: _visible(_following),
                directory: _directory,
                loading: c == null || !_following.loaded,
                emptyText: l10n.userFollowEmptyFollowing,
                showShare: false,
                shareUserId: widget.userId,
                onTap: () => _open(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Maria, João and 10 others" line. [names] are the known display names
/// of the recent people, newest first (may be fewer than shown avatars);
/// [total] is the tile's count. Never shows a uid.
String followNamesLine(AppLocalizations l10n, List<String> names, int total,
    {String? locale}) {
  String first(String n) {
    final t = n.trim();
    if (t.startsWith('@')) return t;
    final sp = t.indexOf(' ');
    return sp > 0 ? t.substring(0, sp) : t;
  }

  final known = [
    for (final n in names)
      if (n.trim().isNotEmpty) first(n),
  ].take(2).toList();
  final n = total < known.length ? known.length : total;
  if (n <= 0) return '';
  String fmt(int v) => formatCompactCount(v, locale: locale);
  if (known.isEmpty) return l10n.userFollowNamesPeople(n, fmt(n));
  if (known.length == 1) {
    final others = n - 1;
    return others <= 0
        ? known[0]
        : l10n.userFollowNamesOneMore(others, known[0], fmt(others));
  }
  final others = n - 2;
  return others <= 0
      ? l10n.userFollowNamesTwo(known[0], known[1])
      : l10n.userFollowNamesTwoMore(others, known[0], known[1], fmt(others));
}

class _FollowTile extends StatelessWidget {
  const _FollowTile({
    required this.count,
    required this.label,
    required this.ids,
    required this.directory,
    required this.loading,
    required this.emptyText,
    required this.showShare,
    required this.shareUserId,
    required this.onTap,
    super.key,
  });

  final int count;
  final String label;
  final List<String> ids;
  final UserDirectoryService directory;
  final bool loading;
  final String emptyText;
  final bool showShare;
  final String shareUserId;
  final VoidCallback onTap;

  /// Fixed minimum height of the people area, so loading → loaded → empty
  /// never moves the layout.
  static const double bodyHeight = 72;
  static const double avatar = 28;
  static const double overlap = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final shown = ids.take(FollowCard.maxAvatars).toList();
    final empty = !loading && count <= 0 && shown.isEmpty;

    Widget body;
    if (loading) {
      body = const _TileSkeleton();
    } else if (empty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emptyText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5),
          ),
          if (showShare) ...[
            const SizedBox(height: 6),
            Builder(
              // The BUTTON's context anchors the iPad share popover.
              builder: (buttonContext) => OutlinedButton.icon(
                key: const Key('follow_card_share'),
                onPressed: () => shareProfileLink(buttonContext, shareUserId),
                icon: const Icon(Icons.ios_share, size: 15),
                label: Text(
                  l10n.shareProfileTooltip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: BorderSide(color: AppColors.richGold.withOpacity(0.6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      final names = [for (final id in shown) directory.cached(id)?.name ?? ''];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shown.isNotEmpty)
            SizedBox(
              key: const Key('follow_card_avatars'),
              height: avatar,
              width: avatar + (shown.length - 1) * (avatar - overlap),
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * (avatar - overlap),
                      child: _Avatar(
                        photoUrl: directory.cached(shown[i])?.photoUrl,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            followNamesLine(l10n, names, count, locale: locale),
            key: const Key('follow_card_names'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.3),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      formatCompactCount(count, locale: locale),
                      key: const Key('follow_card_count'),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: bodyHeight),
                child: Align(alignment: Alignment.topLeft, child: body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final has = url != null && url.isNotEmpty;
    return Container(
      width: _FollowTile.avatar,
      height: _FollowTile.avatar,
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard, // ring that separates the overlap
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.richGold.withOpacity(0.15),
        backgroundImage: has ? CachedNetworkImageProvider(url) : null,
        child: has
            ? null
            : const Icon(Icons.person, size: 15, color: AppColors.richGold),
      ),
    );
  }
}

/// Static placeholder (avatars + one line) in the exact footprint of the
/// loaded content.
class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.textTertiary.withOpacity(0.18);
    return Column(
      key: const Key('follow_card_skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _FollowTile.avatar,
          width: _FollowTile.avatar +
              3 * (_FollowTile.avatar - _FollowTile.overlap),
          child: Stack(children: [
            for (var i = 0; i < 4; i++)
              Positioned(
                left: i * (_FollowTile.avatar - _FollowTile.overlap),
                child: Container(
                  width: _FollowTile.avatar,
                  height: _FollowTile.avatar,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.backgroundCard, width: 1.5),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.8,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(5)),
          ),
        ),
      ],
    );
  }
}
