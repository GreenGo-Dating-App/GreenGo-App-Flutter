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
import '../../data/services/followers_audience_service.dart';
import '../widgets/people_search.dart';

/// Business Followers screen.
///
/// Shows the people who follow this business, newest first, read from
/// `business_followers/{businessId}/followers` a page at a time
/// ([FollowService.followersPage], [pageSize] per page, more on scroll). Rows
/// paint as soon as a page of ids arrives; names/avatars fill in from the
/// batched, cached [UserDirectoryService]. Index-light: one ordered
/// subcollection read per page, no composite index, no unbounded fan-out.
///
/// Filter (owner request 2026-10-15): pick one of the business's events or
/// experiences, upcoming or past, to see the people who attended / booked it,
/// by default only those who follow the business ([FollowersAudienceService]).
class FollowersScreen extends StatefulWidget {
  const FollowersScreen({required this.businessId, this.audienceService, this.clock, super.key});

  final String businessId;

  /// Test seams.
  final FollowersAudienceService? audienceService;
  final DateTime Function()? clock;

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

  late final FollowersAudienceService _audSvc = widget.audienceService ?? FirestoreFollowersAudienceService();
  List<AudienceListing>? _listings;
  AudienceListing? _filter;
  ListingAudience? _aud;
  bool _audLoading = false;
  bool _onlyFollowers = true;

  // Advanced search (owner request 2026-10-15).
  PeopleQuery _q = const PeopleQuery();
  Map<String, DateTime?>? _allFollowers;
  final Map<String, PersonFacts> _facts = {};
  bool _searchLoading = false;

  /// Loads what the search looks at for [uids] (profiles: country,
  /// languages), once per person, batched + cached by UserDirectoryService.
  Future<void> _ensureFacts(List<String> uids, Map<String, DateTime?> addedAt) async {
    final missing = uids.where((u) => !_facts.containsKey(u)).toList();
    if (missing.isEmpty) return;
    Map<String, dynamic> profiles = const {};
    try {
      profiles = await UserDirectoryService.instance.resolveProfiles(missing);
    } catch (_) {}
    for (final u in missing) {
      _facts[u] = PersonFacts(
        uid: u,
        name: UserDirectoryService.instance.cached(u)?.name ?? '',
        profile: profiles[u],
        addedAt: addedAt[u],
      );
    }
  }

  Future<void> _onQuery(PeopleQuery q) async {
    setState(() => _q = q);
    if (!q.isActive) return;
    final needAll = _filter == null && _allFollowers == null;
    final needFacts = _filter == null ? _allFollowers?.keys.toList() : _aud?.people;
    if (!needAll && (needFacts == null || needFacts.every(_facts.containsKey))) return;
    setState(() => _searchLoading = true);
    try {
      if (needAll) _allFollowers = await _audSvc.allFollowers(widget.businessId);
      final uids = _filter == null ? _allFollowers!.keys.toList() : (_aud?.people ?? const <String>[]);
      await _ensureFacts(uids, _allFollowers ?? const {});
    } catch (_) {
      _allFollowers ??= {};
    }
    if (mounted) setState(() => _searchLoading = false);
  }

  List<String> _applyQuery(List<String> uids) {
    if (!_q.isActive) return uids;
    final now = (widget.clock ?? DateTime.now)();
    return uids.where((u) {
      final f = _facts[u];
      final name = UserDirectoryService.instance.cached(u)?.name ?? f?.name ?? '';
      return matchesPeopleQuery(
          PersonFacts(uid: u, name: name, profile: f?.profile, addedAt: _allFollowers?[u] ?? f?.addedAt), _q, now);
    }).toList();
  }

  Future<void> _openFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final listings = _listings ??= await _audSvc
        .listings(widget.businessId, (widget.clock ?? DateTime.now)())
        .catchError((Object _) => <AudienceListing>[]);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(listings: listings, selected: _filter, l10n: l10n),
    );
    if (picked == null || !mounted) return;
    if (picked == _FilterSheet.all) {
      setState(() {
        _filter = null;
        _aud = null;
      });
      return;
    }
    final listing = picked as AudienceListing;
    setState(() {
      _filter = listing;
      _aud = null;
      _audLoading = true;
    });
    ListingAudience aud;
    try {
      aud = await _audSvc.audience(widget.businessId, listing);
    } catch (_) {
      aud = const ListingAudience(people: [], followers: {});
    }
    if (!mounted || _filter != listing) return;
    setState(() {
      _aud = aud;
      _audLoading = false;
    });
    if (aud.people.isNotEmpty) UserDirectoryService.instance.resolve(aud.people);
    if (_q.isActive) await _onQuery(_q);
  }

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
        leading: IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
      body: Column(children: [
        _filterBar(l10n),
        PeopleSearchBar(
          query: _q,
          onChanged: _onQuery,
          people: _facts.values.toList(),
          showSince: _filter == null,
        ),
        Expanded(
          child: _searchLoading
              ? const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold)))
              : _filter != null
                  ? _buildFiltered(l10n)
                  : (_q.isActive ? _buildSearchAll(l10n) : _buildBody(l10n)),
        ),
      ]),
    );
  }

  Widget _filterBar(AppLocalizations l10n) {
    final f = _filter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingL, 4, AppDimensions.paddingL, 0),
      child: Row(children: [
        Expanded(
          child: Material(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: InkWell(
              key: const ValueKey('followers-filter'),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              onTap: _openFilter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Icon(f == null ? Icons.filter_list : (f.kind == 'event' ? Icons.event : Icons.explore_outlined),
                      color: AppColors.richGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f == null ? l10n.followersFilterAll : (f.title.isEmpty ? '—' : f.title),
                      key: const ValueKey('followers-filter-label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: AppColors.textTertiary),
                ]),
              ),
            ),
          ),
        ),
        if (f != null)
          IconButton(
            key: const ValueKey('followers-filter-clear'),
            tooltip: l10n.followersFilterAll,
            icon: const Icon(Icons.close, color: AppColors.textTertiary),
            onPressed: () => setState(() {
              _filter = null;
              _aud = null;
            }),
          ),
      ]),
    );
  }

  /// All followers, searched (loaded in full, bounded).
  Widget _buildSearchAll(AppLocalizations l10n) {
    final hits = _applyQuery(_allFollowers?.keys.toList() ?? const <String>[]);
    return ListView(
      key: const ValueKey('followers-search-results'),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        Text(l10n.peopleSearchResults(hits.length),
            key: const ValueKey('people-search-count'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (hits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.followersAudienceEmpty,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        for (final uid in hits) ...[_followerTile(uid), const SizedBox(height: 12)],
      ],
    );
  }

  Widget _buildFiltered(AppLocalizations l10n) {
    final aud = _aud;
    if (_audLoading || aud == null) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold)),
      );
    }
    final shown = _applyQuery(_onlyFollowers ? aud.people.where(aud.followers.contains).toList() : aud.people);
    return ListView(
      key: const ValueKey('followers-filtered'),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        Text(
          l10n.followersAudienceCount(aud.people.length, aud.followers.length),
          key: const ValueKey('followers-audience-count'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SwitchListTile(
          key: const ValueKey('followers-only-switch'),
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.richGold,
          value: _onlyFollowers,
          title: Text(l10n.followersOnlyToggle, style: const TextStyle(color: AppColors.textPrimary)),
          onChanged: (v) => setState(() => _onlyFollowers = v),
        ),
        if (aud.capped)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.followersAudienceCapped(aud.people.length),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.followersAudienceEmpty,
                key: const ValueKey('followers-audience-empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        for (final uid in shown) ...[
          _followerTile(uid, follower: !_onlyFollowers && aud.followers.contains(uid)),
          const SizedBox(height: 12),
        ],
      ],
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

  Widget _followerTile(String uid, {bool follower = false}) {
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(uid);
        final name = (brief?.name.trim().isNotEmpty ?? false)
            ? brief!.name.trim()
            : AppLocalizations.of(context)!.businessFollowerFallbackName;
        final photo = brief?.photoUrl;
        return _tile(name, (photo != null && photo.isNotEmpty) ? photo : null, follower: follower);
      },
    );
  }

  Widget _tile(String name, String? photoUrl, {bool follower = false}) {
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
          if (follower)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(AppLocalizations.of(context)!.followerBadge,
                  style: const TextStyle(color: AppColors.richGold, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet: "All followers", then the business's events and
/// experiences, upcoming / active first, then past.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.listings, required this.selected, required this.l10n});

  static const Object all = Object();

  final List<AudienceListing> listings;
  final AudienceListing? selected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final groups = <(String, List<AudienceListing>)>[
      (l10n.followersFilterUpcomingEvents, listings.where((l) => l.kind == 'event' && !l.past).toList()),
      (l10n.followersFilterActiveExperiences, listings.where((l) => l.kind == 'experience' && !l.past).toList()),
      (l10n.followersFilterPastEvents, listings.where((l) => l.kind == 'event' && l.past).toList()),
      (l10n.followersFilterPastExperiences, listings.where((l) => l.kind == 'experience' && l.past).toList()),
    ];
    String? dateOf(AudienceListing l) {
      final d = l.date;
      return d == null ? null : MaterialLocalizations.of(context).formatMediumDate(d);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: ListView(
          key: const ValueKey('followers-filter-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(l10n.followersFilterTitle,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              key: const ValueKey('followers-filter-all'),
              leading: const Icon(Icons.people_alt_outlined, color: AppColors.richGold),
              title: Text(l10n.followersFilterAll, style: const TextStyle(color: AppColors.textPrimary)),
              trailing: selected == null ? const Icon(Icons.check, color: AppColors.richGold) : null,
              onTap: () => Navigator.of(context).pop(all),
            ),
            if (listings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.followersFilterNone, style: const TextStyle(color: AppColors.textSecondary)),
              ),
            for (final g in groups)
              if (g.$2.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Text(g.$1.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
                ),
                for (final l in g.$2)
                  ListTile(
                    key: ValueKey('followers-filter-${l.kind}-${l.id}'),
                    leading: Icon(l.kind == 'event' ? Icons.event : Icons.explore_outlined,
                        color: l.past ? AppColors.textTertiary : AppColors.richGold),
                    title: Text(l.title.isEmpty ? '—' : l.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: dateOf(l) == null
                        ? null
                        : Text(dateOf(l)!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: selected?.id == l.id && selected?.kind == l.kind
                        ? const Icon(Icons.check, color: AppColors.richGold)
                        : null,
                    onTap: () => Navigator.of(context).pop(l),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}
