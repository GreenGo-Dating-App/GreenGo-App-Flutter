import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/profile.dart';
import '../widgets/business_contact_button.dart';
import '../widgets/business_follow_button.dart';

/// Public Business Storefront.
///
/// A public-facing page for a business account: cover + avatar + name + gold
/// verified badge, bio / links, a photo gallery strip, the business's upcoming
/// events and the communities they own, plus Follow + Contact actions.
///
/// Reads are deliberately cheap and index-free so this scales to millions:
///   * Events: a single equality query `events.where(organizerId == businessId)`
///     limited to 20, then filtered to published + upcoming and sorted CLIENT
///     side (no composite index required).
///   * Communities: `communities.where(createdByUserId == businessId)` limited
///     to 20, filtered to public client side.
class BusinessStorefrontScreen extends StatefulWidget {
  const BusinessStorefrontScreen({
    required this.business,
    required this.currentUserId,
    super.key,
  });

  final Profile business;
  final String currentUserId;

  @override
  State<BusinessStorefrontScreen> createState() =>
      _BusinessStorefrontScreenState();
}

class _BusinessStorefrontScreenState extends State<BusinessStorefrontScreen> {
  late Future<List<_EventCard>> _eventsFuture;
  late Future<List<_CommunityCard>> _communitiesFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
    _communitiesFuture = _loadCommunities();
  }

  String get _title =>
      (widget.business.businessName?.trim().isNotEmpty ?? false)
          ? widget.business.businessName!.trim()
          : widget.business.displayName;

  Future<List<_EventCard>> _loadEvents() async {
    try {
      // Single-field equality filter → no composite index. Sort/filter client side.
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: widget.business.userId)
          .limit(20)
          .get();
      final now = DateTime.now();
      final cards = snap.docs
          .map((d) => _EventCard.fromDoc(d.id, d.data()))
          .where((e) =>
              e.status == 'published' &&
              (e.endDate == null || e.endDate!.isAfter(now)))
          .toList()
        ..sort((a, b) => (a.startDate ?? now).compareTo(b.startDate ?? now));
      return cards;
    } catch (_) {
      return const [];
    }
  }

  Future<List<_CommunityCard>> _loadCommunities() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('communities')
          .where('createdByUserId', isEqualTo: widget.business.userId)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => _CommunityCard.fromDoc(d.id, d.data()))
          .where((c) => c.isPublic)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photos = widget.business.photoUrls;
    final coverUrl = photos.isNotEmpty ? photos.first : null;
    final avatarUrl = photos.isNotEmpty ? photos.first : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            pinned: true,
            expandedHeight: 220,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary),
              ),
              onPressed: () => SafeNavigation.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverFallback(),
                    )
                  : _coverFallback(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name + verified badge + category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundCard,
                          border: Border.all(
                              color: AppColors.richGold.withOpacity(0.5),
                              width: 2),
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarUrl == null
                            ? const Icon(Icons.storefront,
                                color: AppColors.richGold, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.business.businessVerified) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: l10n.businessVerifiedBadgeTooltip,
                                    child: const VerifiedBadge(
                                        size: 20, isPremium: true),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.business.businessCategory != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.business.businessCategory!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Follow + Contact actions
                  Row(
                    children: [
                      BusinessFollowButton(
                        businessId: widget.business.userId,
                        currentUserId: widget.currentUserId,
                      ),
                      const SizedBox(width: 12),
                      BusinessContactButton(
                        businessProfile: widget.business,
                        currentUserId: widget.currentUserId,
                      ),
                    ],
                  ),
                  // Bio
                  if (widget.business.bio.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.about),
                    const SizedBox(height: 8),
                    Text(
                      widget.business.bio,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                  // Links
                  if (widget.business.socialLinks?.hasAnyLink ?? false) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.businessLinks),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildLinkChips(),
                    ),
                  ],
                  // Opening hours — graceful fallback: the Profile entity does
                  // not currently carry structured opening hours, so we show a
                  // neutral "hours not provided" note rather than a broken field.
                  const SizedBox(height: 24),
                  _sectionTitle(l10n.businessOpeningHours),
                  const SizedBox(height: 8),
                  Text(
                    l10n.businessHoursNotProvided,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  // Gallery
                  if (widget.business.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.businessGallery),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.business.photoUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                          child: Image.network(
                            widget.business.photoUrls[i],
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 110,
                              color: AppColors.backgroundCard,
                              child: const Icon(Icons.broken_image,
                                  color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Upcoming events
                  const SizedBox(height: 24),
                  _sectionTitle(l10n.businessUpcomingEvents),
                  const SizedBox(height: 12),
                  FutureBuilder<List<_EventCard>>(
                    future: _eventsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return _loadingRow();
                      }
                      final events = snap.data ?? const [];
                      if (events.isEmpty) {
                        return _emptyNote(l10n.businessNoUpcomingEvents);
                      }
                      return Column(
                        children: events
                            .map((e) => _eventTile(e))
                            .toList(),
                      );
                    },
                  ),
                  // Communities
                  const SizedBox(height: 24),
                  _sectionTitle(l10n.businessCommunities),
                  const SizedBox(height: 12),
                  FutureBuilder<List<_CommunityCard>>(
                    future: _communitiesFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return _loadingRow();
                      }
                      final comms = snap.data ?? const [];
                      if (comms.isEmpty) {
                        return _emptyNote(l10n.businessNoCommunities);
                      }
                      return Column(
                        children: comms.map((c) => _communityTile(c)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.richGold.withOpacity(0.25),
              AppColors.backgroundDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.storefront, size: 64, color: AppColors.richGold),
        ),
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _emptyNote(String t) => Text(
        t,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      );

  Widget _loadingRow() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.richGold),
          ),
        ),
      );

  List<Widget> _buildLinkChips() {
    final s = widget.business.socialLinks;
    if (s == null) return const [];
    final chips = <Widget>[];
    void add(IconData icon, String label, String? url) {
      if (url == null || url.isEmpty) return;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.richGold),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ));
    }

    add(Icons.camera_alt, 'Instagram', s.instagramUrl);
    add(Icons.facebook, 'Facebook', s.facebookUrl);
    add(Icons.music_note, 'TikTok', s.tiktokUrl);
    add(Icons.work, 'LinkedIn', s.linkedinUrl);
    add(Icons.alternate_email, 'X', s.xUrl);
    return chips;
  }

  Widget _eventTile(_EventCard e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: e.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(e.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: e.imageUrl == null
                ? const Icon(Icons.event, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (e.startDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fmtDate(e.startDate!),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityTile(_CommunityCard c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: c.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(c.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: c.imageUrl == null
                ? const Icon(Icons.groups, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
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
                  AppLocalizations.of(context)!
                      .businessMembersCount(c.memberCount),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Lightweight view model for a storefront event card (avoids importing the
/// events feature's model / entity into the business layer).
class _EventCard {
  const _EventCard({
    required this.title,
    required this.status,
    this.imageUrl,
    this.startDate,
    this.endDate,
  });

  final String title;
  final String status;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  factory _EventCard.fromDoc(String id, Map<String, dynamic> d) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return _EventCard(
      title: (d['title'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'draft',
      imageUrl: d['imageUrl'] as String?,
      startDate: ts(d['startDate']),
      endDate: ts(d['endDate']),
    );
  }
}

/// Lightweight view model for a storefront community card.
class _CommunityCard {
  const _CommunityCard({
    required this.name,
    required this.isPublic,
    required this.memberCount,
    this.imageUrl,
  });

  final String name;
  final bool isPublic;
  final int memberCount;
  final String? imageUrl;

  factory _CommunityCard.fromDoc(String id, Map<String, dynamic> d) {
    return _CommunityCard(
      name: (d['name'] as String?) ?? '',
      isPublic: (d['isPublic'] as bool?) ?? true,
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      imageUrl: d['imageUrl'] as String?,
    );
  }
}
