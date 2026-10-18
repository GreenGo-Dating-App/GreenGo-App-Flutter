import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/compact_count.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/follow_name_normalizer.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../widgets/user_follow_button.dart';

/// Followers / Following of [userId] — two tabs (with live counts), endless
/// scroll (30 per page), pull to refresh, and a name search per tab.
///
/// Each page is ONE ordered read of a single subcollection (auto single-field
/// index on `createdAt`). The search is SERVER-side over the WHOLE list: a
/// prefix query on the server-written `followerNameLower` /
/// `followeeNameLower` (20 per page, endless too, debounced). Names, photos
/// and city come from [UserDirectoryService] (cache-first, batched), never
/// from a raw id. Rows of blocked users and of deleted / inactive accounts
/// are hidden.
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    required this.userId,
    required this.currentUserId,
    super.key,
    this.initialTab = 0,
  });

  final String userId;
  final String currentUserId;

  /// 0 = followers, 1 = following.
  final int initialTab;

  static Route<void> route({
    required String userId,
    required String currentUserId,
    int initialTab = 0,
  }) =>
      MaterialPageRoute<void>(
        builder: (_) => FollowListScreen(
          userId: userId,
          currentUserId: currentUserId,
          initialTab: initialTab,
        ),
      );

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  StreamSubscription<FollowCounts>? _sub;
  FollowCounts? _counts;

  @override
  void initState() {
    super.initState();
    // One single-doc listener for the tab counts (server counters + this
    // device's not-yet-counted changes).
    if (widget.userId.isNotEmpty) {
      _sub = di.sl<FollowService>().counts(widget.userId).listen(
        (c) {
          if (mounted) setState(() => _counts = c);
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final c = _counts;
    String fmt(int v) => formatCompactCount(v, locale: locale);
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.divider.withOpacity(0.4),
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                text: c == null
                    ? l10n.userFollowTabFollowers
                    : l10n.userFollowTabFollowersCount(fmt(c.followers)),
              ),
              Tab(
                text: c == null
                    ? l10n.userFollowTabFollowing
                    : l10n.userFollowTabFollowingCount(fmt(c.following)),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FollowListTab(
              key: const PageStorageKey('followers'),
              userId: widget.userId,
              currentUserId: widget.currentUserId,
              followersTab: true,
            ),
            FollowListTab(
              key: const PageStorageKey('following'),
              userId: widget.userId,
              currentUserId: widget.currentUserId,
              followersTab: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// One paged list (+ search) of [FollowListScreen].
@visibleForTesting
class FollowListTab extends StatefulWidget {
  const FollowListTab({
    required this.userId,
    required this.currentUserId,
    required this.followersTab,
    super.key,
  });

  final String userId;
  final String currentUserId;
  final bool followersTab;

  /// Search typing → query delay.
  static const Duration debounce = Duration(milliseconds: 300);

  @override
  State<FollowListTab> createState() => _FollowListTabState();
}

/// One paged id list (the normal newest-first list, or one search).
class _Paged {
  final List<String> ids = [];
  final Set<String> seen = {};
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool hasMore = true;
  bool loading = false;
  bool error = false;

  /// Bumped by [reset]: a late answer for an older request is dropped.
  int gen = 0;

  void reset() {
    gen++;
    ids.clear();
    seen.clear();
    cursor = null;
    hasMore = true;
    loading = false;
    error = false;
  }
}

class _FollowListTabState extends State<FollowListTab>
    with AutomaticKeepAliveClientMixin {
  final FollowService _service = di.sl<FollowService>();
  final UserDirectoryService _directory = UserDirectoryService.instance;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  final _Paged _list = _Paged();
  final _Paged _search = _Paged();
  Set<String> _blocked = const {};
  Future<Set<String>>? _blockedFuture;

  /// The normalized query being shown ('' = normal list).
  String _query = '';
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _directory.addListener(_onDirectory);
    _scroll.addListener(_onScroll);
    _init();
  }

  String get _cacheKey =>
      '${widget.followersTab ? 'followers' : 'following'}_${widget.userId}';

  /// True while the list shows the LAST-RESULT ids (not yet a server page).
  bool _showingCached = false;

  /// A server page has been applied (the cached paint must never follow it).
  bool _serverLoaded = false;

  bool get _searching => _query.isNotEmpty;
  _Paged get _active => _searching ? _search : _list;

  Future<Set<String>> _loadBlocked() => _blockedFuture ??= () async {
        try {
          if (di.sl.isRegistered<BlockedUsersService>()) {
            return await di
                .sl<BlockedUsersService>()
                .getBlockedUserIds(widget.currentUserId);
          }
        } catch (_) {/* no blocks known */}
        return const <String>{};
      }();

  Future<void> _init() async {
    // Blocked ids, the first server page and the last-result ids all load in
    // PARALLEL.
    final blockedFuture = _loadBlocked();
    unawaited(_paintLastResult(blockedFuture));
    await _loadMore();
  }

  /// Paint the ids this tab showed last time (only non-empty, only once the
  /// blocked set is known so a blocked user is never shown, and only if the
  /// server page hasn't arrived yet). The server page then replaces them.
  Future<void> _paintLastResult(Future<Set<String>> blockedFuture) async {
    try {
      final ids = await LastResultCache.loadIds(_cacheKey);
      if (ids.isEmpty) return;
      final blocked = await blockedFuture;
      final shown = ids.where((id) => !blocked.contains(id)).toList();
      if (shown.isEmpty) return;
      await _directory.resolve(shown);
      if (!mounted || _serverLoaded || _list.ids.isNotEmpty) return;
      setState(() {
        _showingCached = true;
        _list.ids.addAll(shown);
      });
    } catch (_) {/* no instant paint */}
  }

  void _onDirectory() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  /// Next page of the ACTIVE list (normal or search).
  Future<void> _loadMore() async {
    final p = _active;
    final query = _query;
    final gen = p.gen;
    if (p.loading || !p.hasMore) return;
    setState(() {
      p.loading = true;
      p.error = false;
    });
    try {
      final firstPage = p.cursor == null;
      final FollowPage page;
      if (query.isNotEmpty) {
        page = widget.followersTab
            ? await _service.searchFollowers(widget.userId, query,
                after: p.cursor)
            : await _service.searchFollowing(widget.userId, query,
                after: p.cursor);
      } else {
        page = widget.followersTab
            ? await _service.followersPage(widget.userId, after: p.cursor)
            : await _service.followingPage(widget.userId, after: p.cursor);
      }
      _blocked = await _loadBlocked();
      if (gen != p.gen) return; // superseded by a new search / refresh
      if (query.isEmpty) {
        _serverLoaded = true;
        if (_showingCached) {
          // The server page replaces the last-result paint.
          _showingCached = false;
          p
            ..ids.clear()
            ..seen.clear();
        }
      }
      final fresh = page.userIds
          .where((id) =>
              id.isNotEmpty && !_blocked.contains(id) && p.seen.add(id))
          .toList();
      // Resolve names/photos BEFORE showing the rows (batched, cache-first).
      if (fresh.isNotEmpty) await _directory.resolve(fresh);
      if (!mounted || gen != p.gen) return;
      setState(() {
        p.ids.addAll(fresh);
        p.cursor = page.cursor;
        p.hasMore = page.hasMore;
        p.loading = false;
      });
      if (firstPage && query.isEmpty) {
        unawaited(LastResultCache.saveIds(_cacheKey, fresh));
      }
      // A page that was entirely filtered out must not stall the scroll.
      if (fresh.isEmpty && p.hasMore) unawaited(_loadMore());
    } catch (_) {
      if (!mounted || gen != p.gen) return;
      setState(() {
        p.loading = false;
        p.error = true;
      });
    }
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(FollowListTab.debounce, () => _applyQuery(raw));
    setState(() {}); // clear-button visibility
  }

  void _applyQuery(String raw) {
    final q = normalizeFollowName(raw);
    if (q == _query) return;
    setState(() {
      _query = q;
      _search.reset();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    // Clearing returns to the normal list, which keeps its loaded pages.
    if (q.isNotEmpty) _loadMore();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    _applyQuery('');
  }

  Future<void> _refresh() async {
    setState(() {
      _active.reset();
      if (!_searching) {
        _showingCached = false;
        _blockedFuture = null; // a block made meanwhile applies now
      }
    });
    await _loadMore();
  }

  Future<void> _openProfile(String uid) async {
    try {
      final profiles = await _directory.resolveProfiles([uid]);
      final profile = profiles[uid];
      if (profile == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileDetailScreen(
            profile: profile,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    } catch (_) {/* stay on the list */}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _directory.removeListener(_onDirectory);
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _searchBox(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          key: const Key('follow_list_search'),
          controller: _searchCtrl,
          onChanged: _onQueryChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            _applyQuery(v);
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.richGold,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.backgroundCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintText: l10n.userFollowSearchHint,
            hintStyle:
                const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.search,
                size: 20, color: AppColors.textTertiary),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.userFollowSearchClear,
                    icon: const Icon(Icons.close,
                        color: AppColors.textTertiary),
                    onPressed: _clearSearch,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: AppColors.richGold.withOpacity(0.35), width: 1),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final p = _active;
    final visible = p.ids.where((id) {
      final b = _directory.cached(id);
      return b == null || b.isActive;
    }).toList();

    Widget? message;
    if (visible.isEmpty && !p.hasMore && !p.loading) {
      message = Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              p.error
                  ? Icons.cloud_off_outlined
                  : _searching
                      ? Icons.search_off
                      : Icons.people_outline,
              size: 32,
              color: AppColors.textTertiary.withOpacity(0.6),
            ),
            const SizedBox(height: 10),
            Text(
              p.error
                  ? l10n.userFollowListError
                  : _searching
                      ? l10n.userFollowSearchNoResults(_searchCtrl.text.trim())
                      : (widget.followersTab
                          ? l10n.userFollowEmptyFollowers
                          : l10n.userFollowEmptyFollowing),
              key: const Key('follow_list_message'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final showFooter = message == null && (p.loading || p.error);
    // My own followers list: everyone here follows me. Elsewhere knowing it
    // would cost one read per row, so "Follows you" is not shown.
    final followsYou =
        widget.followersTab && widget.userId == widget.currentUserId;
    final rows = visible.length;

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _refresh,
      child: ListView.builder(
        key: Key(widget.followersTab ? 'follow_list_followers' : 'follow_list_following'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 1 + (message != null ? 1 : rows) + (showFooter ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) return _searchBox(l10n);
          if (message != null) return message;
          final r = i - 1;
          if (r >= rows) {
            if (p.error) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: Text(
                      '${l10n.userFollowListError} ${l10n.retry}',
                      style: const TextStyle(color: AppColors.richGold),
                    ),
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              ),
            );
          }
          final uid = visible[r];
          return FollowRow(
            key: ValueKey('follow_row_$uid'),
            uid: uid,
            brief: _directory.cached(uid),
            currentUserId: widget.currentUserId,
            followsYou: followsYou,
            onTap: () => _openProfile(uid),
          );
        },
      ),
    );
  }
}

/// One person in a follow list: 44 px photo, name (+ verified), one muted
/// subtitle line ("Follows you · 🇵🇹 Lisbon, Portugal") and a compact
/// Follow back / Following pill.
@visibleForTesting
class FollowRow extends StatelessWidget {
  const FollowRow({
    required this.uid,
    required this.brief,
    required this.currentUserId,
    required this.followsYou,
    required this.onTap,
    super.key,
  });

  final String uid;
  final UserBrief? brief;
  final String currentUserId;
  final bool followsYou;
  final VoidCallback onTap;

  static const double avatar = 44;

  static String placeLine(UserBrief? b) {
    if (b == null) return '';
    final city = b.city?.trim() ?? '';
    final country = b.country?.trim() ?? '';
    final code = country.isEmpty
        ? null
        : (country.length == 2
            ? country
            : CountryFlagHelper.getCodeFromName(country));
    final flag = code == null ? '' : CountryFlagHelper.getFlag(code);
    final place = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty && country.length != 2) country,
    ].join(', ');
    return [if (flag.isNotEmpty) flag, if (place.isNotEmpty) place].join(' ');
  }

  /// "Follows you · City" / "Follows you" / "City" / ''.
  static String subtitleLine(String followsYouLabel, String place,
          {required bool followsYou}) =>
      [if (followsYou) followsYouLabel, if (place.isNotEmpty) place]
          .join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = brief?.name ?? '';
    final photo = brief?.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final isSelf = uid == currentUserId;
    final subtitle = subtitleLine(l10n.userFollowFollowsYou, placeLine(brief),
        followsYou: followsYou && !isSelf);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatar / 2,
              backgroundColor: AppColors.richGold.withOpacity(0.15),
              backgroundImage:
                  hasPhoto ? CachedNetworkImageProvider(photo) : null,
              child: hasPhoto
                  ? null
                  : const Icon(Icons.person,
                      size: 22, color: AppColors.richGold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unknown name -> a neutral placeholder bar, never the uid.
                  if (name.isNotEmpty)
                    Row(children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (UserVerifiedBadge.isVisible(brief))
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: VerifiedBadge(size: 14),
                        ),
                    ])
                  else
                    Container(
                      width: 110,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        key: const Key('follow_row_subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            ),
            if (!isSelf) ...[
              const SizedBox(width: 10),
              UserFollowButton(
                targetUserId: uid,
                currentUserId: currentUserId,
                compact: true,
                followsYou: followsYou,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
