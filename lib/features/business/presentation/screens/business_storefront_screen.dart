import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/business_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/interactive_location_map.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../communities/domain/entities/community.dart';
import '../../../communities/domain/repositories/communities_repository.dart';
import '../../../communities/presentation/bloc/communities_bloc.dart';
import '../../../communities/presentation/screens/community_detail_screen.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../data/services/follow_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/business_contact_phone.dart';
import '../../data/business_upcoming_events.dart';
import '../widgets/storefront_chat_button.dart';
import '../widgets/storefront_event_tile.dart';
import 'business_upcoming_events_screen.dart';
import '../../../follows/presentation/widgets/public_follower_count_line.dart';
import '../widgets/business_follow_button.dart';
import '../widgets/opening_hours_section.dart';
import '../widgets/business_rating.dart';
import '../../../safety/presentation/widgets/safety_actions_menu.dart';
import '../../../../core/services/deep_link_service.dart';

/// Public Business Storefront.
///
/// A public-facing page for a business account: cover + avatar + name + gold
/// verified badge, bio / links, a photo gallery strip, the business's upcoming
/// events and the communities they own, plus Follow + Contact actions.
///
/// Reads are deliberately cheap and index-free so this scales to millions:
///   * Events: [BusinessUpcomingEventsRepository.preview] - upcoming
///     (future + ongoing), published, not hidden/private, soonest first, on the
///     existing events(organizerId, startDate) / (organizerId, endDate)
///     indexes; "See all" pages through every upcoming event (20 per page).
///   * Communities: `communities.where(createdByUserId == businessId)` limited
///     to 20, filtered to public client side.
class BusinessStorefrontScreen extends StatefulWidget {
  const BusinessStorefrontScreen({
    required this.business,
    required this.currentUserId,
    this.eventsRepository,
    this.firestore,
    super.key,
  });

  final Profile business;
  final String currentUserId;

  /// Injectable for tests; defaults to the Firestore-backed repository.
  final BusinessUpcomingEventsRepository? eventsRepository;

  /// Injectable for tests (communities + contact phone reads); defaults to
  /// [FirebaseFirestore.instance].
  final FirebaseFirestore? firestore;

  /// Hero image: curated cover, else the FIRST storefront gallery image, else
  /// the profile photo (legacy); null = branded placeholder (never empty).
  static String? heroImageFor(Profile b) {
    final cover = b.coverImageUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    for (final u in b.galleryImages) {
      if (u.trim().isNotEmpty) return u;
    }
    for (final u in b.photoUrls) {
      if (u.trim().isNotEmpty) return u;
    }
    return null;
  }

  /// Header avatar circle: the dedicated business profile picture
  /// (`businessLogoUrl`), else the owner's first photo (legacy); null = icon.
  static String? avatarImageFor(Profile b) {
    final logo = b.businessLogoOrNull;
    if (logo != null) return logo;
    for (final u in b.photoUrls) {
      if (u.trim().isNotEmpty) return u;
    }
    return null;
  }

  @override
  State<BusinessStorefrontScreen> createState() =>
      _BusinessStorefrontScreenState();
}

class _BusinessStorefrontScreenState extends State<BusinessStorefrontScreen> {
  late Future<List<StorefrontEvent>> _eventsFuture;
  late final BusinessUpcomingEventsRepository _eventsRepo =
      widget.eventsRepository ?? BusinessUpcomingEventsRepository();
  late Future<List<_CommunityCard>> _communitiesFuture;

  // Follower count: the owner streams the private follow_counts doc; other
  // viewers read the public count (owner decision 2026-10-19).
  final FollowService _followService = di.sl<FollowService>();

  bool get _isOwner => widget.currentUserId == widget.business.userId;

  /// Created once (not per build, which re-subscribed on every repaint).
  late final Stream<int> _followerCount = _isOwner
      ? _followService.followerCount(widget.business.userId)
      : const Stream<int>.empty();

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
    _communitiesFuture = _loadCommunities();
    _contactPhoneFuture = BusinessContactPhoneRepository(firestore: widget.firestore)
        .publicPhone(widget.business.userId)
        .catchError((Object _) => null);
  }

  /// The optional business contact number, only when the business chose
  /// "Show on my storefront" (never the account's verified phone).
  late Future<String?> _contactPhoneFuture;

  Future<void> _callBusiness(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  /// Decode width (physical px) for an image [logical] dp wide.
  int _px(double logical) =>
      (logical * MediaQuery.of(context).devicePixelRatio).round();

  ImageProvider _thumb(String url, double logical) =>
      ResizeImage.resizeIfNeeded(
          _px(logical), null, CachedNetworkImageProvider(url));

  String get _title =>
      (widget.business.businessName?.trim().isNotEmpty ?? false)
          ? widget.business.businessName!.trim()
          : widget.business.displayName;

  /// Long-form storefront description, falling back to the profile bio.
  String get _storefrontDescription {
    final sb = widget.business.storefrontBio?.trim() ?? '';
    return sb.isNotEmpty ? sb : widget.business.bio;
  }

  /// Curated storefront gallery, falling back to the owner's profile photos.
  List<String> get _galleryImages => widget.business.galleryImages.isNotEmpty
      ? widget.business.galleryImages
      : widget.business.photoUrls;

  Future<List<StorefrontEvent>> _loadEvents() async {
    try {
      return await _eventsRepo.preview(widget.business.userId);
    } catch (_) {
      return const [];
    }
  }

  void _openAllEvents() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BusinessUpcomingEventsScreen(
        businessId: widget.business.userId,
        businessName: _title,
        currentUserId: widget.currentUserId,
        repository: _eventsRepo,
      ),
    ));
  }

  Future<List<_CommunityCard>> _loadCommunities() async {
    try {
      final snap = await (widget.firestore ?? FirebaseFirestore.instance)
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
    // Featured/cover (hero) image: prefer the curated coverImageUrl, then fall
    // back to the first profile photo, then a branded placeholder.
    final coverUrl = BusinessStorefrontScreen.heroImageFor(widget.business);
    // Avatar circle: the business profile picture first (owner 2026-10-19).
    final avatarUrl = BusinessStorefrontScreen.avatarImageFor(widget.business);

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
              background: _buildHero(coverUrl),
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
                                  image: _thumb(avatarUrl, 64),
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
                                    child: const CheckBadge(
                                        size: 20, isPremium: true),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.business.businessCategory != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                localizedBusinessCategory(
                                    l10n, widget.business.businessCategory!),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            // Follower count: the NUMBER is public (owner
                            // decision 2026-10-19). Owner: live private
                            // counter; everyone else: the public count
                            // (hidden at 0, not tappable - the list stays
                            // private).
                            if (_isOwner) ...[
                              const SizedBox(height: 6),
                              _followersLine(l10n),
                            ] else
                              PublicFollowerCountLine(
                                  userId: widget.business.userId),
                            const SizedBox(height: 6),
                            BusinessRatingSummary(
                                businessId: widget.business.userId),
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
                      // Primary "Chat" (business inbox), right next to
                      // Share. It replaces the former "Contact" pill here
                      // (same action) so the header has no duplicate.
                      StorefrontChatButton(
                        business: widget.business,
                        currentUserId: widget.currentUserId,
                      ),
                      // Share this storefront/profile via its deep link
                      // (https://greengo-chat.web.app/u/{userId}).
                      // Builder: the BUTTON's context anchors the iPad
                      // share popover.
                      Builder(
                        builder: (buttonContext) => IconButton(
                          icon: const Icon(Icons.ios_share,
                              color: AppColors.richGold),
                          tooltip: l10n.shareProfileTooltip,
                          onPressed: () => shareProfileLink(
                            buttonContext,
                            widget.business.userId,
                            displayName: _title,
                          ),
                        ),
                      ),
                      if (widget.currentUserId != widget.business.userId) ...[
                        const Spacer(),
                        SafetyActionsMenu(
                          currentUserId: widget.currentUserId,
                          reportedUserId: widget.business.userId,
                          reportedUserName: _title,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  BusinessRatingBar(
                    businessId: widget.business.userId,
                    raterId: widget.currentUserId,
                  ),
                  // Bio — prefer the long-form storefront description, falling
                  // back to the standard profile bio.
                  if (_storefrontDescription.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.about),
                    const SizedBox(height: 8),
                    Text(
                      _storefrontDescription,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                  // Links — social handles plus any custom storefront URLs.
                  if ((widget.business.socialLinks?.hasAnyLink ?? false) ||
                      widget.business.storefrontLinks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.businessLinks),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._buildLinkChips(),
                        ..._buildStorefrontLinkChips(),
                      ],
                    ),
                  ],
                  // Business contact number (tap to call), when shown.
                  FutureBuilder<String?>(
                    future: _contactPhoneFuture,
                    builder: (context, snap) {
                      final phone = snap.data;
                      if (phone == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(l10n.businessContactPhoneStorefrontTitle),
                            const SizedBox(height: 8),
                            InkWell(
                              key: const ValueKey('storefront-call-business'),
                              onTap: () => _callBusiness(phone),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusM),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundCard,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.call,
                                        size: 18, color: AppColors.richGold),
                                    const SizedBox(width: 8),
                                    Text(phone,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(l10n.businessContactPhoneCall,
                                        style: const TextStyle(
                                            color: AppColors.richGold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Address + map (like events), when the business set one.
                  if (widget.business.businessAddress case final a?) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.storefrontAddressTitle),
                    const SizedBox(height: 8),
                    InteractiveLocationMap(
                      key: const ValueKey('storefront-address-map'),
                      lat: a.latitude,
                      lng: a.longitude,
                      label: widget.business.businessName ?? widget.business.displayName,
                      subtitle: a.summary,
                      height: 190,
                    ),
                  ],
                  // Opening hours — render the structured per-weekday block when
                  // provided, otherwise a neutral "hours not provided" note.
                  const SizedBox(height: 24),
                  _sectionTitle(l10n.businessOpeningHours),
                  const SizedBox(height: 8),
                  if (widget.business.openingHours.isNotEmpty)
                    OpeningHoursSection(
                      hours: widget.business.openingHours,
                      closedLabel: l10n.adminClosed,
                    )
                  else
                    Text(
                      l10n.businessHoursNotProvided,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  // Gallery — dedicated storefront gallery, falling back to the
                  // owner's profile photos when no gallery has been curated.
                  if (_galleryImages.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(l10n.businessGallery),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _galleryImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                          child: CachedNetworkImage(
                            imageUrl: _galleryImages[i],
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            memCacheWidth: _px(110),
                            placeholder: (_, __) => Container(
                              width: 110,
                              height: 110,
                              color: AppColors.backgroundCard,
                            ),
                            errorWidget: (_, __, ___) => Container(
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
                  FutureBuilder<List<StorefrontEvent>>(
                    future: _eventsFuture,
                    builder: (context, snap) => Row(
                      children: [
                        Expanded(
                            child:
                                _sectionTitle(l10n.businessUpcomingEvents)),
                        if ((snap.data ?? const []).isNotEmpty)
                          TextButton(
                            key: const ValueKey('storefront-events-see-all'),
                            onPressed: _openAllEvents,
                            child: Text(l10n.seeAll,
                                style: const TextStyle(
                                    color: AppColors.richGold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<StorefrontEvent>>(
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
                        children: [
                          for (final e in events)
                            StorefrontEventTile(
                              event: e,
                              onTap: () => _openStorefrontEvent(e.id),
                            ),
                        ],
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

  /// Featured/cover hero banner: cached network image with a gradient scrim so
  /// the back button and avatar stay legible over any image, falling back to a
  /// branded gradient placeholder when no cover/photo is available.
  Widget _buildHero(String? coverUrl) => Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.backgroundCard),
              errorWidget: (_, __, ___) => _coverFallback(),
            )
          else
            _coverFallback(),
          // Scrim for control/legibility over the image.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.black54,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
      );

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

  /// "N followers" line for the OWNER's own storefront header. Streams the
  /// private `follow_counts/{businessId}` via [FollowService] (one doc) and
  /// formats it with the existing `businessFollowersCount` plural.
  Widget _followersLine(AppLocalizations l10n) => StreamBuilder<int>(
        stream: _followerCount,
        builder: (context, snap) {
          final count = snap.data ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.businessFollowersCount(count),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
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

  /// Chips for arbitrary custom storefront links (websites, booking, menu…).
  /// The visible label is a cleaned-up host/path so long URLs stay tidy.
  List<Widget> _buildStorefrontLinkChips() {
    return widget.business.storefrontLinks
        .where((url) => url.trim().isNotEmpty)
        .map((url) {
      final label = _prettyLinkLabel(url);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 16, color: AppColors.richGold),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _prettyLinkLabel(String url) {
    var s = url.trim();
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.replaceFirst(RegExp(r'^www\.'), '');
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Open the storefront event's detail page (loads by id).
  void _openStorefrontEvent(String eventId) {
    if (eventId.isEmpty) return;
    Navigator.of(context).push(
      EventDetailLoaderScreen.route(
        eventId: eventId,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  /// Open the storefront community's detail page (fetch by id, then push with
  /// the blocs CommunityDetailScreen needs).
  ///
  /// The page opens at once (spinner) and the fetch runs inside it, instead of
  /// the tap waiting for the read before anything happens. A missing
  /// community closes the page again (same outcome as before: no detail).
  Future<void> _openStorefrontCommunity(String communityId) async {
    if (communityId.isEmpty) return;
    final currentUserId = widget.currentUserId;
    final load = di
        .sl<CommunitiesRepository>()
        .getCommunityById(communityId)
        .then<Community?>((r) => r.fold((_) => null, (c) => c),
            onError: (Object _) => null);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FutureBuilder<Community?>(
          future: load,
          builder: (context, snap) {
            final community = snap.data;
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                backgroundColor: AppColors.backgroundDark,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                ),
              );
            }
            if (community == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.of(context).maybePop();
              });
              return const Scaffold(backgroundColor: AppColors.backgroundDark);
            }
            return MultiBlocProvider(
              providers: [
                BlocProvider<CommunitiesBloc>(
                  create: (_) => di.sl<CommunitiesBloc>(),
                ),
                BlocProvider<ProfileBloc>(
                  create: (_) => di.sl<ProfileBloc>()
                    ..add(ProfileLoadRequested(userId: currentUserId)),
                ),
              ],
              child: CommunityDetailScreen(community: community),
            );
          },
        ),
      ),
    );
  }

  Widget _communityTile(_CommunityCard c) {
    return InkWell(
      onTap: () => _openStorefrontCommunity(c.id),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
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
                      image: _thumb(c.imageUrl!, 48), fit: BoxFit.cover)
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
      ),
    );
  }

}

/// Lightweight view model for a storefront community card.
class _CommunityCard {
  const _CommunityCard({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.memberCount,
    this.imageUrl,
  });

  final String id;
  final String name;
  final bool isPublic;
  final int memberCount;
  final String? imageUrl;

  factory _CommunityCard.fromDoc(String id, Map<String, dynamic> d) {
    return _CommunityCard(
      id: id,
      name: (d['name'] as String?) ?? '',
      isPublic: (d['isPublic'] as bool?) ?? true,
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      imageUrl: d['imageUrl'] as String?,
    );
  }
}
