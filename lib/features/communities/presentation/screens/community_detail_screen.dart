import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/community_message.dart';
import '../bloc/communities_bloc.dart';
import '../bloc/communities_event.dart';
import '../bloc/communities_state.dart';
import '../widgets/announcement_composer_sheet.dart';
import '../widgets/community_events_tab.dart';
import '../widgets/community_member_tile.dart';
import '../widgets/community_report.dart';
import '../widgets/community_message_bubble.dart';
import '../widgets/community_rules_header.dart';
import '../widgets/join_requests_sheet.dart';
import '../widgets/member_moderation_sheet.dart';
import '../widgets/rules_editor_sheet.dart';
import '../widgets/tip_composer_sheet.dart';
import '../widgets/sponsored_badge.dart';
import '../widgets/sponsored_promo_card.dart';
import '../widgets/sponsorship_editor_sheet.dart';
import '../widgets/sponsorship_gate.dart';

/// Community Detail Screen
///
/// Shows the community group chat, members, and info.
/// Allows joining/leaving and sending messages.
class CommunityDetailScreen extends StatefulWidget {

  const CommunityDetailScreen({
    required this.community, super.key,
  });
  final Community community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;
  String? _currentUserId;
  String _currentUserName = '';
  String? _currentUserPhoto;
  bool _isLocalGuide = false;
  List<String> _userLanguages = [];
  bool _isMember = false;
  bool _isBusiness = false;
  MembershipTier _membershipTier = MembershipTier.free;
  CommunityMessageType _selectedMessageType = CommunityMessageType.text;

  // Current user's role within THIS community (derived from the members list).
  CommunityRole? _myRole;
  bool _isMuted = false;
  // Granular writer permissions for the current user (admin-designated).
  bool _canWriteTips = false;
  bool _canWriteAnnouncements = false;

  // One-shot guard so we load pending join requests only once (dispatching on
  // every CommunityDetailLoaded would loop, since the load re-emits that state).
  bool _requestsRequested = false;

  // Tips tab: active filter (null = all tip types).
  CommunityMessageType? _tipFilter;
  String _tipSearch = '';

  /// The current user owns this community (creator) or holds the owner role.
  bool get _isOwner =>
      _currentUserId != null &&
      (_currentUserId == _community.createdByUserId ||
          _myRole == CommunityRole.owner);

  /// The current user can moderate (owner or admin).
  bool get _isModerator => _isOwner || _myRole == CommunityRole.admin;

  /// Freshest community (starts as the passed-in one, refreshed from the
  /// detail state and after sponsorship edits) — drives the header badge and
  /// pinned promo.
  late Community _community;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserInfo();
    _loadCommunityDetail();
  }

  void _loadUserInfo() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      _currentUserName = profileState.profile.displayName;
      _currentUserPhoto = profileState.profile.photoUrls.isNotEmpty
          ? profileState.profile.photoUrls.first
          : null;
      _isLocalGuide = profileState.profile.isLocalGuide;
      _userLanguages = profileState.profile.preferredLanguages;
      _isBusiness = profileState.profile.isBusiness;
      _membershipTier = profileState.profile.membershipTier;
    }
  }

  /// Whether the current user owns this community AND is an eligible
  /// (Platinum) business — the only case that may edit sponsorship/promo.
  bool get _canEditSponsorship {
    final uid = _currentUserId;
    if (uid == null || uid != _community.createdByUserId) return false;
    return SponsorshipGate.canSponsor(
      isBusiness: _isBusiness,
      tier: _membershipTier,
    );
  }

  void _loadCommunityDetail() {
    context.read<CommunitiesBloc>().add(
          LoadCommunityDetail(communityId: widget.community.id),
        );

    // Subscribe to message stream
    context.read<CommunitiesBloc>().add(
          SubscribeToCommunityMessages(communityId: widget.community.id),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: BlocConsumer<CommunitiesBloc, CommunitiesState>(
        listener: (context, state) {
          if (state is CommunityJoined) {
            setState(() => _isMember = true);
            _loadCommunityDetail();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.communitiesJoined),
                backgroundColor: AppColors.successGreen,
              ),
            );
          } else if (state is CommunityLeft) {
            setState(() => _isMember = false);
            Navigator.of(context).pop();
          } else if (state is CommunitiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          } else if (state is CommunityJoinRequested) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.communitiesJoinRequestSent),
                backgroundColor: AppColors.successGreen,
              ),
            );
          } else if (state is CommunityDetailLoaded) {
            // Check membership + role + refresh the community (sponsor/promo may
            // have changed since navigation).
            final userId = _currentUserId;
            if (mounted) {
              final me = userId == null
                  ? null
                  : state.members
                      .where((m) => m.userId == userId)
                      .cast<CommunityMember?>()
                      .firstWhere((m) => true, orElse: () => null);
              setState(() {
                _community = state.community;
                _isMember = me != null;
                _myRole = me?.role;
                _isMuted = me?.isMuted ?? false;
                _canWriteTips = me?.mayWriteTips ?? false;
                _canWriteAnnouncements = me?.mayWriteAnnouncements ?? false;
              });
              // Owners/admins: load pending join requests ONCE (guarded so the
              // re-emit from the load doesn't loop the listener).
              final canModerate = (me?.isAdminOrOwner ?? false) ||
                  userId == state.community.createdByUserId;
              if (canModerate && !_requestsRequested) {
                _requestsRequested = true;
                context
                    .read<CommunitiesBloc>()
                    .add(LoadJoinRequests(communityId: state.community.id));
              }
            }
          }
        },
        builder: (context, state) {
          if (state is CommunitiesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (state is CommunityDetailLoaded) {
            final promo = _community.pinnedPromo;
            return Column(
              children: [
                // Hero/cover image banner (when the community has one).
                if ((_community.imageUrl ?? '').isNotEmpty)
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      _community.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),

                // Pinned sponsor promo (glass card at the very top)
                if (promo != null)
                  SponsoredPromoCard(
                    promo: promo,
                    currentUserId: _currentUserId ?? '',
                  ),

                // Pinned Rules & Resources header (owner/admin can edit).
                if (_community.hasRulesOrResources || _isModerator)
                  CommunityRulesHeader(
                    community: _community,
                    canEdit: _isModerator,
                    onEdit: _editRules,
                  ),

                // Chat · Tips · Announcements · Events
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatTab(state),
                      _buildTipsTab(state),
                      _buildAnnouncementsTab(state),
                      CommunityEventsTab(
                        community: _community,
                        canManage: _isModerator,
                        currentUserId: _currentUserId ?? '',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Text(
              AppLocalizations.of(context)!.communitiesUnableToLoad,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  _community.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_community.isSponsored) ...[
                const SizedBox(width: 8),
                const SponsoredBadge(),
              ],
            ],
          ),
          Text(
            AppLocalizations.of(context)!.communitiesMembersCount(_community.memberCount),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.richGold,
        labelColor: AppColors.richGold,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.communitiesTabChat),
          Tab(text: AppLocalizations.of(context)!.communitiesTabTips),
          Tab(text: AppLocalizations.of(context)!.communitiesTabAnnouncements),
          Tab(text: AppLocalizations.of(context)!.communitiesTabEvents),
        ],
      ),
      actions: [
        // Members list button
        IconButton(
          icon: const Icon(Icons.people_outline, color: AppColors.textSecondary),
          onPressed: _showMembersSheet,
        ),
        // Info / More button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          color: AppColors.backgroundCard,
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showCommunityInfo();
                break;
              case 'requests':
                _showJoinRequests();
                break;
              case 'sponsor':
                _editSponsorship();
                break;
              case 'leave':
                _confirmLeave();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.communitiesCommunityInfo,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            // Owner/admin of a PRIVATE community: review join requests.
            if (_isModerator && !_community.isPublic)
              PopupMenuItem(
                value: 'requests',
                child: Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined,
                        color: AppColors.richGold, size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.communitiesJoinRequestsTitle,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            if (_canEditSponsorship)
              PopupMenuItem(
                value: 'sponsor',
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium,
                        color: AppColors.richGold, size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.communitiesEditSponsorship,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            if (_isMember)
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, color: AppColors.errorRed, size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.communitiesLeaveCommunity,
                        style: const TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  /// Chat tab — the live conversation, EXCLUDING tips and announcements (those
  /// live in their own tabs so they don't scroll away).
  Widget _buildChatTab(CommunityDetailLoaded state) {
    final chat = state.messages
        .where((m) => !m.isTip && !m.isAnnouncement)
        .toList();
    return Column(
      children: [
        Expanded(
          child: chat.isEmpty ? _buildEmptyChat() : _buildMessagesList(chat),
        ),
        if (_isMember) _buildMessageInput(state) else _buildJoinBar(),
      ],
    );
  }

  /// Tips tab — a filterable board of language tips / cultural facts / city
  /// tips, so shared knowledge stays put instead of scrolling past in chat.
  Widget _buildTipsTab(CommunityDetailLoaded state) {
    var tips = state.messages.where((m) => m.isTip).toList();
    if (_tipFilter != null) {
      tips = tips.where((m) => m.type == _tipFilter).toList();
    }
    final q = _tipSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      tips = tips
          .where((m) =>
              m.content.toLowerCase().contains(q) ||
              m.senderName.toLowerCase().contains(q))
          .toList();
    }
    return Column(
      children: [
        _buildTipSearch(),
        _buildTipFilterBar(),
        Expanded(
          child: tips.isEmpty
              ? _buildTabEmpty(
                  Icons.lightbulb_outline,
                  AppLocalizations.of(context)!.communitiesTipsEmpty,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingS),
                  itemCount: tips.length,
                  itemBuilder: (context, index) => CommunityMessageBubble(
                    message: tips[index],
                    isCurrentUser: tips[index].senderId == _currentUserId,
                    showSenderInfo: true,
                    currentUserLanguage: _viewerLanguage,
                  ),
                ),
        ),
        // Only admins/owners or admin-designated tip-writers can add tips.
        if (_isMember && _canWriteTips) _buildAddTipBar(),
      ],
    );
  }

  Widget _buildTipSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM, AppDimensions.paddingS, AppDimensions.paddingM, 0),
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        onChanged: (v) => setState(() => _tipSearch = v),
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context)!.communitiesSearchTips,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildAddTipBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addTip,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.richGold,
              side: const BorderSide(color: AppColors.richGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context)!.communitiesAddTip),
          ),
        ),
      ),
    );
  }

  Future<void> _addTip() async {
    // City tips are available to any permitted tip-writer (admins/owners or
    // admin-designated writers) — the whole tip composer is already gated to
    // that group, so no separate local-guide restriction is needed.
    final result = await TipComposerSheet.show(context, allowCityTip: true);
    if (result == null || result.text.trim().isEmpty || !mounted) return;
    final userId = _currentUserId;
    if (userId == null) return;
    context.read<CommunitiesBloc>().add(
          SendCommunityMessage(
            communityId: _community.id,
            senderId: userId,
            senderName: _currentUserName,
            senderPhotoUrl: _currentUserPhoto,
            content: result.text.trim(),
            type: result.type,
          ),
        );
    HapticFeedback.mediumImpact();
  }

  /// Announcements tab — read-only broadcast feed. Owner/admin get a composer
  /// bar; members only read.
  Widget _buildAnnouncementsTab(CommunityDetailLoaded state) {
    final anns = state.messages.where((m) => m.isAnnouncement).toList();
    return Column(
      children: [
        Expanded(
          child: anns.isEmpty
              ? _buildTabEmpty(
                  Icons.campaign_outlined,
                  AppLocalizations.of(context)!.communitiesAnnouncementsEmpty,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingS),
                  itemCount: anns.length,
                  itemBuilder: (context, index) => CommunityMessageBubble(
                    message: anns[index],
                    isCurrentUser: anns[index].senderId == _currentUserId,
                    showSenderInfo: true,
                    currentUserLanguage: _viewerLanguage,
                  ),
                ),
        ),
        if (_canWriteAnnouncements) _buildAnnounceComposerBar(),
      ],
    );
  }

  Widget _buildTipFilterBar() {
    final l10n = AppLocalizations.of(context)!;
    Widget chip(String label, CommunityMessageType? type) {
      final selected = _tipFilter == type;
      // Center-aligned so the pill hugs its text instead of stretching to the
      // full row height (was 48px tall / mis-proportioned).
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _tipFilter = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.richGold.withValues(alpha: 0.15)
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.richGold : AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color:
                      selected ? AppColors.richGold : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        children: [
          chip(l10n.filterAll, null),
          chip(l10n.communitiesLanguageTipLabel,
              CommunityMessageType.languageTip),
          chip(l10n.communitiesCulturalFactLabel,
              CommunityMessageType.culturalFact),
          chip(l10n.communitiesCityTipLabel, CommunityMessageType.cityTip),
        ],
      ),
    );
  }

  Widget _buildAnnounceComposerBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _postAnnouncement,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            icon: const Icon(Icons.campaign, size: 18),
            label: Text(
              AppLocalizations.of(context)!.communitiesPostAnnouncement,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabEmpty(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: AppDimensions.paddingM),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// The viewer's preferred language for on-demand translation of content.
  String get _viewerLanguage =>
      _userLanguages.isNotEmpty ? _userLanguages.first : 'en';

  Widget _buildMessagesList(List<CommunityMessage> messages) {
    // Messages come in reverse order (newest first) from Firestore
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == _currentUserId;

        // Determine if we should show sender info (group chat style)
        var showSenderInfo = true;
        if (index < messages.length - 1) {
          final prevMessage = messages[index + 1]; // Previous in display (next in list)
          if (prevMessage.senderId == message.senderId) {
            showSenderInfo = false;
          }
        }

        return CommunityMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          showSenderInfo: showSenderInfo,
          currentUserLanguage: _viewerLanguage,
          onReport: isCurrentUser || _currentUserId == null
              ? null
              : () => _reportMessage(message),
        );
      },
    );
  }

  /// Report a message's author (reuses the app-wide safety report flow).
  void _reportMessage(CommunityMessage message) {
    final me = _currentUserId;
    if (me == null) return;
    showCommunityReportSheet(
      context,
      reporterId: me,
      reportedUserId: message.senderId,
      reportedUserName: message.senderName,
      communityId: _community.id,
      contentId: message.id,
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            AppLocalizations.of(context)!.communitiesNoMessagesYet,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.communitiesBeFirstToSay,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(CommunityDetailLoaded state) {
    // A muted member can read but not post.
    if (_isMuted) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_off,
                  color: AppColors.textTertiary, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.communitiesMutedNotice,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    // For local guide communities, non-guides can only send regular text
    final isLocalGuideCommunity =
        widget.community.type == CommunityType.localGuides;
    final canPostCityTip = isLocalGuideCommunity && _isLocalGuide;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message type selector (for authorized users)
            if (canPostCityTip || !isLocalGuideCommunity)
              _buildMessageTypeSelector(canPostCityTip),

            Row(
              children: [
                // Message input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.backgroundInput,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: state.isSending ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: state.isSending
                          ? AppColors.richGold.withValues(alpha: 0.5)
                          : AppColors.richGold,
                      shape: BoxShape.circle,
                    ),
                    child: state.isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepBlack,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.deepBlack,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeSelector(bool canPostCityTip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeChip(
              label: AppLocalizations.of(context)!.communitiesTextLabel,
              icon: Icons.chat_bubble_outline,
              type: CommunityMessageType.text,
            ),
            const SizedBox(width: 6),
            _buildTypeChip(
              label: AppLocalizations.of(context)!.communitiesLanguageTipLabel,
              icon: Icons.lightbulb_outline,
              type: CommunityMessageType.languageTip,
            ),
            const SizedBox(width: 6),
            _buildTypeChip(
              label: AppLocalizations.of(context)!.communitiesCulturalFactLabel,
              icon: Icons.auto_awesome,
              type: CommunityMessageType.culturalFact,
            ),
            if (canPostCityTip) ...[
              const SizedBox(width: 6),
              _buildTypeChip(
                label: AppLocalizations.of(context)!.communitiesCityTipLabel,
                icon: Icons.location_on,
                type: CommunityMessageType.cityTip,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required CommunityMessageType type,
  }) {
    final isSelected = _selectedMessageType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMessageType = type);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.richGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.richGold : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.richGold : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _joinCommunity,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            child: Text(
              _community.isPublic
                  ? AppLocalizations.of(context)!.communitiesJoinCommunity
                  : AppLocalizations.of(context)!.communitiesRequestToJoin,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedMessageType) {
      case CommunityMessageType.text:
        return l10n.communitiesTypeAMessage;
      case CommunityMessageType.languageTip:
        return l10n.communitiesShareLanguageTip;
      case CommunityMessageType.culturalFact:
        return l10n.communitiesShareCulturalFact;
      case CommunityMessageType.cityTip:
        return l10n.communitiesShareCityTip;
      default:
        return l10n.communitiesTypeAMessage;
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userId = _currentUserId;
    if (userId == null) return;

    context.read<CommunitiesBloc>().add(
          SendCommunityMessage(
            communityId: widget.community.id,
            senderId: userId,
            senderName: _currentUserName,
            senderPhotoUrl: _currentUserPhoto,
            content: content,
            type: _selectedMessageType,
          ),
        );

    _messageController.clear();
    setState(() => _selectedMessageType = CommunityMessageType.text);
    HapticFeedback.lightImpact();
  }

  void _joinCommunity() {
    final userId = _currentUserId;
    if (userId == null) return;

    if (_community.isPublic) {
      context.read<CommunitiesBloc>().add(
            JoinCommunity(
              communityId: widget.community.id,
              userId: userId,
              displayName: _currentUserName,
              photoUrl: _currentUserPhoto,
              languages: _userLanguages,
              isLocalGuide: _isLocalGuide,
            ),
          );
    } else {
      // Private community → submit a join request for owner/admin approval.
      context.read<CommunitiesBloc>().add(
            RequestToJoinCommunity(
              communityId: widget.community.id,
              userId: userId,
              displayName: _currentUserName,
              photoUrl: _currentUserPhoto,
              languages: _userLanguages,
              isLocalGuide: _isLocalGuide,
            ),
          );
    }

    HapticFeedback.mediumImpact();
  }

  Future<void> _editRules() async {
    final result = await RulesEditorSheet.show(
      context,
      initialRules: _community.rules,
      initialLinks: _community.resourceLinks,
    );
    if (result == null || !mounted) return;

    final trimmed = result.rules?.trim();
    final updated = _community.copyWith(
      rules: trimmed,
      clearRules: trimmed == null || trimmed.isEmpty,
      resourceLinks: result.links,
    );
    setState(() => _community = updated);
    context.read<CommunitiesBloc>().add(UpdateCommunity(community: updated));
    HapticFeedback.mediumImpact();
  }

  Future<void> _postAnnouncement() async {
    final text = await AnnouncementComposerSheet.show(context);
    if (text == null || text.trim().isEmpty || !mounted) return;
    final userId = _currentUserId;
    if (userId == null) return;

    context.read<CommunitiesBloc>().add(
          SendCommunityMessage(
            communityId: _community.id,
            senderId: userId,
            senderName: _currentUserName,
            senderPhotoUrl: _currentUserPhoto,
            content: text.trim(),
            type: CommunityMessageType.announcement,
          ),
        );
    HapticFeedback.mediumImpact();
  }

  void _showJoinRequests() {
    final bloc = context.read<CommunitiesBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: JoinRequestsSheet(communityId: _community.id),
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(this.context)!.communitiesLeaveTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(this.context)!.communitiesLeaveConfirm(widget.community.name),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(this.context)!.communitiesCancelLabel,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final userId = _currentUserId;
              if (userId != null) {
                this.context.read<CommunitiesBloc>().add(
                      LeaveCommunity(
                        communityId: widget.community.id,
                        userId: userId,
                      ),
                    );
              }
            },
            child: Text(
              AppLocalizations.of(this.context)!.communitiesLeaveLabel,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSponsorship() async {
    final uid = _currentUserId;
    if (uid == null) return;

    // Defensive re-check (the action is only shown to owner-businesses, but
    // tier could change): non-eligible users get the standard gated message.
    if (!_canEditSponsorship) {
      await SponsorshipGate.showGate(
        context,
        currentTier: _membershipTier,
        userId: uid,
      );
      return;
    }

    final result = await SponsorshipEditorSheet.show(
      context,
      initialSponsored: _community.isSponsored,
      initialPromo: _community.pinnedPromo,
    );
    if (result == null || !mounted) return;

    final updated = result.isSponsored
        ? _community.copyWith(
            isSponsored: true,
            sponsorId: uid,
            pinnedPromo: result.pinnedPromo,
            clearPinnedPromo: result.pinnedPromo == null,
          )
        : _community.copyWith(
            isSponsored: false,
            clearSponsorId: true,
            clearPinnedPromo: true,
          );

    setState(() => _community = updated);
    context.read<CommunitiesBloc>().add(UpdateCommunity(community: updated));
    HapticFeedback.mediumImpact();
  }

  void _showMembersSheet() {
    final bloc = context.read<CommunitiesBloc>();
    if (bloc.state is! CommunityDetailLoaded) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return BlocBuilder<CommunitiesBloc, CommunitiesState>(
                builder: (context, state) {
                  // Banned members are hidden from the roster.
                  final members = state is CommunityDetailLoaded
                      ? state.members.where((m) => !m.isBanned).toList()
                      : const <CommunityMember>[];
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                          vertical: AppDimensions.paddingS,
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .communitiesMembersTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${members.length})',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isSelf = member.userId == _currentUserId;
                            return InkWell(
                              onTap: isSelf
                                  ? null
                                  : () => _onMemberTap(context, bloc, member),
                              child: CommunityMemberTile(member: member),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Tapping a member (not yourself): owner/admin get the moderation actions;
  /// everyone else gets a Report option.
  void _onMemberTap(
    BuildContext sheetContext,
    CommunitiesBloc bloc,
    CommunityMember member,
  ) {
    final me = _currentUserId;
    if (me == null) return;

    if (_isModerator && !member.isOwner) {
      showMemberModerationSheet(
        sheetContext,
        bloc: bloc,
        communityId: _community.id,
        member: member,
        canReport: true,
        onReport: () => showCommunityReportSheet(
          sheetContext,
          reporterId: me,
          reportedUserId: member.userId,
          reportedUserName: member.displayName,
          communityId: _community.id,
        ),
      );
    } else {
      showCommunityReportSheet(
        sheetContext,
        reporterId: me,
        reportedUserId: member.userId,
        reportedUserName: member.displayName,
        communityId: _community.id,
      );
    }
  }

  void _showCommunityInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Community name
                  Text(
                    widget.community.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.community.type.displayName,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    AppLocalizations.of(this.context)!.communitiesDescription,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.community.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Languages
                  if (widget.community.languages.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(this.context)!.communitiesLanguages,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.community.languages.map((lang) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (widget.community.tags.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(this.context)!.communitiesTags,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.community.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // City / Country
                  if (widget.community.city != null ||
                      widget.community.country != null) ...[
                    Text(
                      AppLocalizations.of(this.context)!.communitiesLocation,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textTertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          [
                            widget.community.city,
                            widget.community.country,
                          ].whereType<String>().join(', '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats
                  Text(
                    AppLocalizations.of(this.context)!.communitiesStats,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.people_outline,
                        '${widget.community.memberCount}',
                        AppLocalizations.of(this.context)!.communitiesMembersStatLabel,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        Icons.calendar_today_outlined,
                        _formatDate(widget.community.createdAt),
                        AppLocalizations.of(this.context)!.communitiesCreatedStatLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Created by
                  Text(
                    AppLocalizations.of(this.context)!.communitiesCreatedBy(widget.community.createdByName),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
