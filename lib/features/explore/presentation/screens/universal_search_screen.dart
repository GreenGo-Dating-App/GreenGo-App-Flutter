import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/interaction_log_service.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../communities/domain/entities/community.dart';
import '../../../communities/domain/repositories/communities_repository.dart';
import '../../../communities/presentation/bloc/communities_bloc.dart';
import '../../../communities/presentation/screens/community_detail_screen.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Universal Search — look up other PEOPLE (→ open a chat instantly) and
/// community EVENTS (→ open that event's page), from the Explore header.
///
/// Apple-safe / glass. Deliberately index-light: every query is a single-field
/// equality, prefix range or `arrayContains` (no composite indexes), capped at
/// 20, sorted client-side. People are searched by exact `nickname` (the same
/// lookup the Network search uses) plus a `displayName` prefix; events by the
/// single-field, case-insensitive `searchKeywords` array (community + public,
/// live-gated) unioned with the events the current user is GOING to.
class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key, required this.currentUserId});

  final String currentUserId;

  static Route<void> route({required String currentUserId}) {
    return MaterialPageRoute<void>(
      builder: (_) => UniversalSearchScreen(currentUserId: currentUserId),
    );
  }

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final InteractionLogService _log = di.sl<InteractionLogService>();

  Timer? _debounce;

  /// Monotonic guard so a stale (older keystroke) response never overwrites a
  /// newer one after an await.
  int _generation = 0;

  String _query = '';

  // null == not searched yet / cleared; empty == searched, nothing found.
  List<Profile>? _people;
  List<Profile>? _business;
  List<Event>? _events;
  List<Community>? _communities;
  bool _loading = false;

  /// The current user's own events (organized + going), fetched at most once per
  /// screen and reused across keystrokes so search stays cheap. Bounded to this
  /// single user's memberships.
  Future<List<Event>>? _userEventsFuture;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() {
        _people = null;
        _business = null;
        _events = null;
        _communities = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final generation = ++_generation;
    if (!mounted) return;
    setState(() => _loading = true);

    final results = await Future.wait<Object>([
      _searchProfiles(q),
      _searchEvents(q),
      _searchCommunities(q),
    ]);

    if (!mounted || generation != _generation) return;
    final profiles = results[0] as List<Profile>;
    setState(() {
      // Split matched profiles into People (personal) and Business accounts.
      _people = profiles.where((p) => !p.isBusiness).toList();
      _business = profiles.where((p) => p.isBusiness).toList();
      _events = results[1] as List<Event>;
      _communities = results[2] as List<Community>;
      _loading = false;
    });
  }

  /// Communities matching the query (name / description / tags — the datasource's
  /// client-side substring search over public communities).
  Future<List<Community>> _searchCommunities(String q) async {
    final result =
        await di.sl<CommunitiesRepository>().getCommunities(searchQuery: q);
    return result.fold((_) => <Community>[], (list) => list.take(20).toList());
  }

  /// People: exact `nickname` equality (lowercased) merged with a `displayName`
  /// prefix range. Excludes self, ghost-mode and the hidden GreenGo
  /// admin/support account, and non-active profiles.
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Tab label with a result count "(n)" once a search has produced results.
  String _tabLabel(String label, List<Object?>? results) =>
      (results != null && results.isNotEmpty) ? '$label (${results.length})' : label;

  Future<List<Profile>> _searchProfiles(String q) async {
    final byId = <String, Profile>{};

    void absorb(QuerySnapshot<Map<String, dynamic>> snap) {
      for (final doc in snap.docs) {
        if (byId.containsKey(doc.id)) continue;
        Profile p;
        try {
          p = ProfileModel.fromFirestore(doc);
        } catch (_) {
          continue;
        }
        if (p.userId == widget.currentUserId) continue;
        if (p.isGhostMode || p.isAdmin || p.isSupport) continue;
        if (p.accountStatus != 'active') continue;
        if (p.displayName.trim().isEmpty) continue;
        byId[doc.id] = p;
      }
    }

    // 1) Exact nickname (usernames are stored lowercase).
    try {
      absorb(await _firestore
          .collection('profiles')
          .where('nickname', isEqualTo: q.toLowerCase())
          .limit(20)
          .get());
    } catch (_) {/* keep whatever we have */}

    // 2) displayName prefix range (single-field, index-free).
    try {
      absorb(await _firestore
          .collection('profiles')
          .orderBy('displayName')
          .startAt([q])
          .endAt(['$q'])
          .limit(20)
          .get());
    } catch (_) {/* keep whatever we have */}

    // 3) businessName prefix — find business accounts by their storefront name.
    for (final term in {q, _capitalize(q)}) {
      try {
        absorb(await _firestore
            .collection('profiles')
            .orderBy('businessName')
            .startAt([term])
            .endAt(['$term'])
            .limit(20)
            .get());
      } catch (_) {/* keep whatever we have */}
    }

    final list = byId.values.toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list.take(20).toList();
  }

  /// Events: case-insensitive keyword match over the single-field
  /// `searchKeywords` array (index-free `arrayContains`, the SAME field the
  /// community-events feed matches on), gated to live + public so community
  /// events surface. This replaces the old case-sensitive `title` prefix range,
  /// which missed community events (mixed-case / title-less docs) entirely.
  ///
  /// The result is then unioned with the events the current user is GOING to
  /// that match the query — of ANY visibility — so a joined event always shows
  /// up. De-duped by id and capped at 20.
  Future<List<Event>> _searchEvents(String q) async {
    final lower = q.toLowerCase();
    // First alphanumeric token >= 2 chars — mirrors the datasource tokenizer so
    // the query lines up with how `searchKeywords` is built.
    final token = lower
        .split(RegExp(r'[^a-z0-9]+'))
        .firstWhere((t) => t.length >= 2, orElse: () => '');

    final byId = <String, Event>{};

    // 1) Public keyword search (community + all public events, live only).
    if (token.isNotEmpty) {
      try {
        final snap = await _firestore
            .collection('events')
            .where('searchKeywords', arrayContains: token)
            .limit(30)
            .get();
        for (final doc in snap.docs) {
          final e = EventModel.fromFirestore(doc);
          if (e.isLive && e.isPublic) byId[e.id] = e;
        }
      } catch (_) {/* keep whatever we have */}
    }

    // 2) Events the user is GOING to that match — any visibility, live only.
    // Client-side `contains` covers blank/title-less or non-tokenizable queries
    // over this user's bounded event set.
    try {
      final mine = await _userEvents();
      for (final e in mine) {
        if (byId.containsKey(e.id)) continue;
        if (!e.isLive) continue;
        if (_eventMatches(e, lower)) byId[e.id] = e;
      }
    } catch (_) {/* keep whatever we have */}

    final list = byId.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list.take(20).toList();
  }

  /// The current user's organized + going events, fetched at most once and
  /// cached for the life of the screen (bounded to this one user).
  Future<List<Event>> _userEvents() {
    return _userEventsFuture ??=
        di.sl<EventsRemoteDataSource>().getUserEvents(widget.currentUserId);
  }

  /// Case-insensitive substring match over an event's searchable text fields.
  bool _eventMatches(Event e, String lowerQuery) {
    if (lowerQuery.isEmpty) return false;
    bool has(String? s) => s != null && s.toLowerCase().contains(lowerQuery);
    return has(e.title) ||
        has(e.city) ||
        has(e.country) ||
        has(e.locationName) ||
        e.category.name.toLowerCase().contains(lowerQuery) ||
        e.tags.any((t) => t.toLowerCase().contains(lowerQuery));
  }

  void _openPerson(Profile profile) {
    _log
      ..logSearch(widget.currentUserId, _query)
      ..logProfileView(widget.currentUserId, profile.userId);
    openConnectChat(
      context,
      currentUserId: widget.currentUserId,
      otherUserId: profile.userId,
      otherUserProfile: profile,
    );
  }

  void _openEvent(Event event) {
    _log
      ..logSearch(widget.currentUserId, _query)
      ..logEventView(widget.currentUserId, event.id, category: event.category.name);
    Navigator.of(context).push(
      EventDetailLoaderScreen.route(
        eventId: event.id,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: Text(l10n.universalSearchTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: _tabLabel(l10n.universalSearchTabPeople, _people)),
              Tab(text: _tabLabel(l10n.universalSearchTabEvents, _events)),
              Tab(text: _tabLabel(l10n.universalSearchTabBusiness, _business)),
              Tab(text:
                  _tabLabel(l10n.universalSearchTabCommunity, _communities)),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _searchField(l10n),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _peopleTab(l10n),
                    _eventsTab(l10n),
                    _businessTab(l10n),
                    _communitiesTab(l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        border: Border.all(color: AppGlass.border),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
        onSubmitted: (v) {
          final q = v.trim();
          if (q.isNotEmpty) _log.logSearch(widget.currentUserId, q);
        },
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        cursorColor: AppColors.richGold,
        decoration: InputDecoration(
          hintText: l10n.universalSearchHint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _peopleTab(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return _hint(Icons.person_search_outlined, l10n.universalSearchEmptyPrompt);
    }
    final people = _people;
    if (people == null || _loading) return _spinner();
    if (people.isEmpty) {
      return _hint(Icons.search_off, l10n.universalSearchNoPeople);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _personRow(people[index]),
    );
  }

  Widget _eventsTab(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return _hint(Icons.event_outlined, l10n.universalSearchEmptyPrompt);
    }
    final events = _events;
    if (events == null || _loading) return _spinner();
    if (events.isEmpty) {
      return _hint(Icons.search_off, l10n.universalSearchNoEvents);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _eventRow(events[index]),
    );
  }

  Widget _businessTab(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return _hint(Icons.storefront_outlined, l10n.universalSearchEmptyPrompt);
    }
    final business = _business;
    if (business == null || _loading) return _spinner();
    if (business.isEmpty) {
      return _hint(Icons.search_off, l10n.universalSearchNoBusiness);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: business.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _personRow(business[index]),
    );
  }

  Widget _communitiesTab(AppLocalizations l10n) {
    if (_query.isEmpty) {
      return _hint(Icons.groups_outlined, l10n.universalSearchEmptyPrompt);
    }
    final communities = _communities;
    if (communities == null || _loading) return _spinner();
    if (communities.isEmpty) {
      return _hint(Icons.search_off, l10n.universalSearchNoCommunities);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: communities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _communityRow(communities[index]),
    );
  }

  Widget _communityRow(Community community) {
    final photo = community.imageUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return InkWell(
      onTap: () => _openCommunity(community),
      borderRadius: BorderRadius.circular(AppGlass.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          border: Border.all(color: AppGlass.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
              child: hasPhoto ? null : const Icon(Icons.groups),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    community.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _openCommunity(Community community) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>(
              create: (_) => di.sl<CommunitiesBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()
                ..add(ProfileLoadRequested(userId: widget.currentUserId)),
            ),
          ],
          child: CommunityDetailScreen(community: community),
        ),
      ),
    );
  }

  Widget _personRow(Profile profile) {
    final photo = profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
    final city = profile.location.city.trim();
    final subtitle = <String>[
      if (profile.nickname != null && profile.nickname!.isNotEmpty)
        '@${profile.nickname}',
      if (city.isNotEmpty) city,
    ].join(' · ');
    return _glassRow(
      onTap: () => _openPerson(profile),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.charcoal,
        backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
        child: photo == null
            ? const Icon(Icons.person, color: AppColors.textSecondary)
            : null,
      ),
      title: profile.displayName,
      subtitle: subtitle,
      trailing: const Icon(Icons.chat_bubble_outline,
          color: AppColors.richGold, size: 20),
    );
  }

  Widget _eventRow(Event event) {
    final photo = event.imageUrl;
    final date = DateFormat('EEE, MMM d • h:mm a').format(event.startDate);
    final where = (event.city ?? event.locationName).trim();
    final subtitle = where.isEmpty ? date : '$date · $where';
    return _glassRow(
      onTap: () => _openEvent(event),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: photo != null && photo.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.charcoal,
                    child: Icon(Icons.event, color: AppColors.textSecondary),
                  ),
                )
              : const ColoredBox(
                  color: AppColors.charcoal,
                  child: Icon(Icons.event, color: AppColors.textSecondary),
                ),
        ),
      ),
      title: event.title,
      subtitle: subtitle,
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.richGold, size: 22),
    );
  }

  Widget _glassRow({
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(AppGlass.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppGlass.radiusCard),
            border: Border.all(color: AppGlass.border),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _spinner() => const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );

  Widget _hint(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 44),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
