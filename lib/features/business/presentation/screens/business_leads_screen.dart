import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

/// Business Leads / enquiries list.
///
/// Shows the people who have interacted with the business (opened a chat →
/// "contact", or saved/RSVP'd one of the business's events → "saved_event").
///
/// Reads are deliberately cheap and index-free so this scales to millions:
///   * `business_leads/{businessId}/leads` ordered by `updatedAt` newest-first
///     (single-field index), [_BusinessLeadsScreenState._pageSize] per page
///     with a cursor; the original unordered `.limit(100)` read is the
///     fallback if that query fails.
///   * Names + avatars come from the batched, cached [UserDirectoryService]
///     after the rows paint; a failed/missing profile falls back to a neutral
///     placeholder so one bad doc never breaks the list.
class BusinessLeadsScreen extends StatefulWidget {
  const BusinessLeadsScreen({required this.businessId, super.key});

  /// The business's own uid — the `business_leads/{businessId}` document owner.
  final String businessId;

  @override
  State<BusinessLeadsScreen> createState() => _BusinessLeadsScreenState();
}

class _BusinessLeadsScreenState extends State<BusinessLeadsScreen> {
  static const int _pageSize = 30;

  final _scroll = ScrollController();
  final List<_Lead> _leads = [];
  final Set<String> _seen = {};
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _done = false;
  bool _firstDone = false;
  bool _failed = false;

  /// Bumped by refresh so a stale page never lands in the new list.
  int _gen = 0;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('business_leads')
      .doc(widget.businessId)
      .collection('leads');

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
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

  /// Newest interaction first, a page at a time (single-field `updatedAt`
  /// index — every lead write sets it). The list paints as soon as a page
  /// arrives; names/avatars fill in from the batched, cached
  /// [UserDirectoryService] instead of one full profile read per row.
  Future<void> _loadMore() async {
    if (_loading || _done) return;
    final gen = _gen;
    setState(() => _loading = true);
    List<_Lead> page;
    try {
      Query<Map<String, dynamic>> q =
          _col.orderBy('updatedAt', descending: true).limit(_pageSize);
      if (_cursor != null) q = q.startAfterDocument(_cursor!);
      final snap = await q.get();
      if (snap.docs.isNotEmpty) _cursor = snap.docs.last;
      _done = snap.docs.length < _pageSize;
      page = snap.docs.map((d) => _Lead.fromDoc(d.id, d.data())).toList();
    } catch (e) {
      if (gen != _gen) return;
      if (_leads.isNotEmpty) {
        // Keep what is shown; a later scroll retries.
        if (mounted) setState(() => _loading = false);
        return;
      }
      // First page failed: the original bounded, unordered read, sorted here.
      try {
        final snap = await _col.limit(100).get();
        page = snap.docs.map((d) => _Lead.fromDoc(d.id, d.data())).toList()
          ..sort((a, b) {
            final at = a.updatedAt;
            final bt = b.updatedAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });
        _done = true;
      } catch (e) {
        debugPrint('[Leads] load failed: $e');
        if (!mounted || gen != _gen) return;
        setState(() {
          _loading = false;
          _firstDone = true;
          _failed = true;
          _done = true;
        });
        return;
      }
    }
    if (!mounted || gen != _gen) return;
    setState(() {
      _leads.addAll(page.where((l) => _seen.add(l.uid)));
      _loading = false;
      _firstDone = true;
      _failed = false;
    });
    final ids = page.map((l) => l.uid).toList();
    if (ids.isNotEmpty) UserDirectoryService.instance.resolve(ids);
    // A page that doesn't fill the screen can't be scrolled: fetch the next.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _done || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0) _loadMore();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _gen++;
      _leads.clear();
      _seen.clear();
      _cursor = null;
      _done = false;
      _loading = false;
      _failed = false;
    });
    await _loadMore();
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
          l10n.businessLeadsTitle,
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
    if (!_firstDone) return _loadingIndicator();
    if (_failed && _leads.isEmpty) return _errorState();
    if (_leads.isEmpty) return _emptyState(l10n.businessLeadsEmpty);
    final showLoader = !_done;
    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: _leads.length + (showLoader ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => i >= _leads.length
            ? _loadingIndicator()
            : ListenableBuilder(
                listenable: UserDirectoryService.instance,
                builder: (_, __) => _leadTile(_leads[i]),
              ),
      ),
    );
  }

  Widget _leadTile(_Lead lead) {
    final l10n = AppLocalizations.of(context)!;
    final isContact = lead.type != 'saved_event';
    final typeLabel =
        isContact ? l10n.businessLeadContact : l10n.businessLeadSavedEvent;
    // Never show the raw uid — fall back to a neutral label if the name is
    // unavailable (e.g. a deleted profile or a transient load failure).
    final brief = UserDirectoryService.instance.cached(lead.uid);
    final resolvedName = brief?.name.trim() ?? '';
    final name = resolvedName.isNotEmpty ? resolvedName : l10n.chatUnknown;
    final avatarUrl =
        (brief?.photoUrl?.isNotEmpty ?? false) ? brief!.photoUrl : null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      onTap: () => _openLeadProfile(lead.uid),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withOpacity(0.12),
              image: avatarUrl != null
                  ? DecorationImage(
                      // Disk-cached, decoded at avatar size (48dp).
                      image: ResizeImage.resizeIfNeeded(
                          (48 * MediaQuery.of(context).devicePixelRatio)
                              .round(),
                          null,
                          CachedNetworkImageProvider(avatarUrl)),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isContact ? Icons.chat_bubble_outline : Icons.event,
                      size: 13,
                      color: AppColors.richGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (!isContact && (lead.eventId?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(
                    lead.eventId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (lead.updatedAt != null) ...[
            const SizedBox(width: 10),
            Text(
              _fmtDate(lead.updatedAt!),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// Open the lead user's profile (loads it by uid, then ProfileDetailScreen).
  Future<void> _openLeadProfile(String uid) async {
    final navigator = Navigator.of(context);
    final result = await di.sl<ProfileRepository>().getProfile(uid);
    final profile = result.fold((_) => null, (p) => p);
    if (profile == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: widget.businessId,
        ),
      ),
    );
  }

  Widget _loadingIndicator() => const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.richGold,
          ),
        ),
      );

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _refresh,
                child: Text(
                  AppLocalizations.of(context)!.retry,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

/// View model for a lead row (name/avatar come from [UserDirectoryService]).
class _Lead {
  _Lead({
    required this.uid,
    required this.type,
    this.eventId,
    this.updatedAt,
  });

  final String uid;
  final String type;
  final String? eventId;
  final DateTime? updatedAt;

  factory _Lead.fromDoc(String id, Map<String, dynamic> d) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return _Lead(
      uid: (d['uid'] as String?) ?? id,
      type: (d['lastType'] as String?) ?? (d['type'] as String?) ?? 'contact',
      eventId: d['eventId'] as String?,
      updatedAt: ts(d['updatedAt']) ?? ts(d['createdAt']),
    );
  }
}
