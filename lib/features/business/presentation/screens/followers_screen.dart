import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/follow_service.dart';

/// Business Followers screen.
///
/// Shows the people who follow this business, newest first, read from
/// `business_followers/{businessId}/followers` a page at a time
/// ([FollowService.followersPage], [pageSize] per page, more on scroll). Rows
/// paint as soon as a page of ids arrives; names/avatars fill in from the
/// batched, cached [UserDirectoryService]. Index-light: one ordered
/// subcollection read per page, no composite index, no unbounded fan-out.
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({required this.businessId, super.key});

  final String businessId;

  /// Followers per page.
  static const int pageSize = 20;

  static Route<void> route({required String businessId}) {
    return MaterialPageRoute<void>(
      builder: (_) => FollowersScreen(businessId: businessId),
    );
  }

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FollowService _follows = FollowService();
  final _scroll = ScrollController();
  final List<String> _uids = [];
  final Set<String> _seen = {};
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _done = false;
  bool _firstDone = false;

  /// Server-maintained follower total (null until read).
  int? _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
    _follows.getFollowerCount(widget.businessId).then((n) {
      if (mounted) setState(() => _total = n);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || _done) return;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    var ids = const <String>[];
    try {
      final page = await _follows.followersPage(widget.businessId,
          after: _cursor, limit: FollowersScreen.pageSize);
      ids = page.userIds;
      _cursor = page.cursor;
      _done = !page.hasMore;
    } catch (_) {
      // Some followers may lack a createdAt (legacy) — fall back to an
      // unordered, still-bounded single read so the list is never empty on
      // error.
      if (_uids.isEmpty) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('business_followers')
              .doc(widget.businessId)
              .collection('followers')
              .limit(100)
              .get();
          ids = [for (final d in snap.docs) d.id];
        } catch (_) {/* empty state */}
      }
      _done = true;
    }
    if (!mounted) return;
    setState(() {
      _uids.addAll(ids.where(_seen.add));
      _loading = false;
      _firstDone = true;
    });
    // Names/avatars: batched + cached; the rows repaint as they arrive.
    if (ids.isNotEmpty) UserDirectoryService.instance.resolve(ids);
    // A page that doesn't fill the screen can't be scrolled: fetch the next.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _done || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0) _loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.businessFollowersTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (!_firstDone) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
        ),
      );
    }
    if (_uids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Text(
            l10n.businessNoFollowers,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    final showLoader = !_done;
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _uids.length + 1 + (showLoader ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.businessFollowersCount(
                  (_total ?? 0) > _uids.length ? _total! : _uids.length),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        if (index > _uids.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            ),
          );
        }
        return _followerTile(_uids[index - 1]);
      },
    );
  }

  Widget _followerTile(String uid) {
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(uid);
        final name = (brief?.name.trim().isNotEmpty ?? false)
            ? brief!.name.trim()
            : AppLocalizations.of(context)!.businessFollowerFallbackName;
        final photo = brief?.photoUrl;
        return _tile(name, (photo != null && photo.isNotEmpty) ? photo : null);
      },
    );
  }

  Widget _tile(String name, String? photoUrl) {
    final avatarPx = (48 * MediaQuery.of(context).devicePixelRatio).round();
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.richGold.withOpacity(0.15),
            // Disk-cached, decoded at avatar size.
            backgroundImage: (photoUrl != null)
                ? ResizeImage.resizeIfNeeded(
                    avatarPx, null, CachedNetworkImageProvider(photoUrl))
                : null,
            child: (photoUrl == null)
                ? const Icon(Icons.person, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
