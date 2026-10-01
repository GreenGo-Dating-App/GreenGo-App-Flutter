import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/blocked_users_service.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/data/services/follow_service.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../widgets/user_follow_button.dart';

/// Followers / Following of [userId] — two tabs, 30 per page, infinite scroll.
///
/// Each page is ONE ordered read of a single subcollection (auto single-field
/// index on `createdAt`); names and photos come from [UserDirectoryService]
/// (cache-first, batched), never from a raw id. Rows of blocked users and of
/// deleted / inactive accounts are hidden.
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            tabs: [
              Tab(text: l10n.userFollowTabFollowers),
              Tab(text: l10n.userFollowTabFollowing),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowListTab(
              key: const PageStorageKey('followers'),
              userId: widget.userId,
              currentUserId: widget.currentUserId,
              followersTab: true,
            ),
            _FollowListTab(
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

class _FollowListTab extends StatefulWidget {
  const _FollowListTab({
    required this.userId,
    required this.currentUserId,
    required this.followersTab,
    super.key,
  });

  final String userId;
  final String currentUserId;
  final bool followersTab;

  @override
  State<_FollowListTab> createState() => _FollowListTabState();
}

class _FollowListTabState extends State<_FollowListTab>
    with AutomaticKeepAliveClientMixin {
  final FollowService _service = di.sl<FollowService>();
  final UserDirectoryService _directory = UserDirectoryService.instance;
  final ScrollController _scroll = ScrollController();

  final List<String> _ids = [];
  final Set<String> _seen = {};
  Set<String> _blocked = const {};
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _error = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _directory.addListener(_onDirectory);
    _scroll.addListener(_onScroll);
    _init();
  }

  Future<void> _init() async {
    try {
      if (di.sl.isRegistered<BlockedUsersService>()) {
        _blocked = await di
            .sl<BlockedUsersService>()
            .getBlockedUserIds(widget.currentUserId);
      }
    } catch (_) {/* no blocks known */}
    await _loadMore();
  }

  void _onDirectory() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = widget.followersTab
          ? await _service.followersPage(widget.userId, after: _cursor)
          : await _service.followingPage(widget.userId, after: _cursor);
      final fresh = page.userIds
          .where((id) => id.isNotEmpty && !_blocked.contains(id) && _seen.add(id))
          .toList();
      // Resolve names/photos BEFORE showing the rows (batched, cache-first).
      if (fresh.isNotEmpty) await _directory.resolve(fresh);
      if (!mounted) return;
      setState(() {
        _ids.addAll(fresh);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
      // A page that was entirely filtered out must not stall the scroll.
      if (fresh.isEmpty && _hasMore) _loadMore();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
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
    _directory.removeListener(_onDirectory);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final visible = _ids.where((id) {
      final b = _directory.cached(id);
      return b == null || b.isActive;
    }).toList();

    if (visible.isEmpty && !_hasMore && !_loading) {
      return Center(
        child: Text(
          _error
              ? l10n.userFollowListError
              : (widget.followersTab
                  ? l10n.userFollowEmptyFollowers
                  : l10n.userFollowEmptyFollowing),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }

    final showFooter = _loading || _error;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visible.length + (showFooter ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= visible.length) {
          if (_error) {
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
        final uid = visible[i];
        return _FollowRow(
          uid: uid,
          brief: _directory.cached(uid),
          currentUserId: widget.currentUserId,
          // My own followers list: everyone here follows me.
          followsYou: widget.followersTab && widget.userId == widget.currentUserId,
          onTap: () => _openProfile(uid),
        );
      },
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.uid,
    required this.brief,
    required this.currentUserId,
    required this.followsYou,
    required this.onTap,
  });

  final String uid;
  final UserBrief? brief;
  final String currentUserId;
  final bool followsYou;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = brief?.name ?? '';
    final photo = brief?.photoUrl;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.richGold.withOpacity(0.15),
        backgroundImage: (photo != null && photo.isNotEmpty)
            ? CachedNetworkImageProvider(photo)
            : null,
        child: (photo == null || photo.isEmpty)
            ? const Icon(Icons.person, color: AppColors.richGold)
            : null,
      ),
      // Unknown name → a neutral placeholder bar, never the uid.
      title: name.isNotEmpty
          ? Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 110,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
      trailing: uid == currentUserId
          ? null
          : UserFollowButton(
              targetUserId: uid,
              currentUserId: currentUserId,
              compact: true,
              followsYou: followsYou,
            ),
    );
  }
}
