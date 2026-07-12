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
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';

/// Universal Search — look up other PEOPLE (→ open a chat instantly) and
/// community EVENTS (→ open that event's page), from the Explore header.
///
/// Apple-safe / glass. Deliberately index-light: every query is a single-field
/// equality or prefix range (no composite indexes), capped at 20, sorted
/// client-side. People are searched by exact `nickname` (the same lookup the
/// Network search uses) plus a `displayName` prefix; events by `title` prefix
/// (published + public only, filtered client-side).
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
  List<Event>? _events;
  bool _loading = false;

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
        _events = null;
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
      _searchPeople(q),
      _searchEvents(q),
    ]);

    if (!mounted || generation != _generation) return;
    setState(() {
      _people = results[0] as List<Profile>;
      _events = results[1] as List<Event>;
      _loading = false;
    });
  }

  /// People: exact `nickname` equality (lowercased) merged with a `displayName`
  /// prefix range. Excludes self, ghost-mode and the hidden GreenGo
  /// admin/support account, and non-active profiles.
  Future<List<Profile>> _searchPeople(String q) async {
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

    final list = byId.values.toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list.take(20).toList();
  }

  /// Events: `title` prefix range (single-field, index-free), filtered to
  /// published + public client-side.
  Future<List<Event>> _searchEvents(String q) async {
    try {
      final snap = await _firestore
          .collection('events')
          .orderBy('title')
          .startAt([q])
          .endAt(['$q'])
          .limit(20)
          .get();
      final events = snap.docs
          .map(EventModel.fromFirestore)
          .where((e) => e.status == EventStatus.published && e.isPublic)
          .toList();
      return events;
    } catch (_) {
      return const <Event>[];
    }
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
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: Text(l10n.universalSearchTitle),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: l10n.universalSearchTabPeople),
              Tab(text: l10n.universalSearchTabEvents),
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
