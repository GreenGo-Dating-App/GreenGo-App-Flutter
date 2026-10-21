import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/reauthenticate_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/community_transfer_service.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/repositories/communities_repository.dart';
import 'community_member_tile.dart';

/// Loads one page of members (ordered by joinedAt; [after] = keyset cursor).
typedef CommunityMembersPageLoader = Future<List<CommunityMember>> Function(
    String communityId,
    {DateTime? after,
    required int limit});

/// "Confirm it's you": password for email accounts, the Google / Apple sign-in
/// again for social accounts (see reauthenticate_dialog.dart).
typedef ReauthenticateFn = Future<bool> Function(BuildContext context);

/// User-facing text of a transfer refusal.
String communityTransferFailureText(
    AppLocalizations l10n, CommunityTransferFailure f) {
  switch (f) {
    case CommunityTransferFailure.requiresRecentLogin:
      return l10n.communityTransferErrorRecentLogin;
    case CommunityTransferFailure.notMember:
      return l10n.communityTransferErrorNotMember;
    case CommunityTransferFailure.unavailable:
      return l10n.communityTransferErrorUnavailable;
    case CommunityTransferFailure.pending:
      return l10n.communityTransferErrorPending;
    case CommunityTransferFailure.limit:
      return l10n.communityTransferErrorLimit;
    case CommunityTransferFailure.gone:
      return l10n.communityTransferErrorGone;
    case CommunityTransferFailure.failed:
      return l10n.communityTransferErrorGeneric;
  }
}

void _snack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: error ? AppColors.errorRed : AppColors.successGreen,
  ));
}

Future<List<CommunityMember>> _defaultMembersLoader(String communityId,
    {DateTime? after, required int limit}) async {
  final r = await di.sl<CommunitiesRepository>().getCommunityMembers(
      communityId,
      limit: limit,
      startAfterJoinedAt: after);
  return r.fold((_) => throw Exception('members_load_failed'), (m) => m);
}

// ─────────────────────────────────────────────────────────── picker screen

/// Owner-only: choose the new owner among the current members, read the
/// warning, confirm with the password, and send the offer.
class CommunityTransferScreen extends StatefulWidget {
  const CommunityTransferScreen({
    required this.community,
    required this.currentUserId,
    this.blockedIds = const <String>{},
    this.service,
    this.loadMembers,
    this.reauthenticate,
    super.key,
  });

  final Community community;
  final String currentUserId;
  final Set<String> blockedIds;
  final CommunityTransferService? service;
  final CommunityMembersPageLoader? loadMembers;
  final ReauthenticateFn? reauthenticate;

  static const int pageSize = 30;

  @override
  State<CommunityTransferScreen> createState() =>
      _CommunityTransferScreenState();
}

class _CommunityTransferScreenState extends State<CommunityTransferScreen> {
  final _search = TextEditingController();
  final List<CommunityMember> _members = [];
  bool _loading = false;
  bool _hasMore = true;
  bool _sending = false;
  bool _loadFailed = false;

  CommunityTransferService get _service =>
      widget.service ?? CommunityTransferService.instance;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final page = await (widget.loadMembers ?? _defaultMembersLoader)(
        widget.community.id,
        after: _members.isEmpty ? null : _members.last.joinedAt,
        limit: CommunityTransferScreen.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(page);
        _hasMore = page.length >= CommunityTransferScreen.pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Members who can receive the community: not me, not banned, not blocked,
  /// matching the search (name, case-insensitive).
  List<CommunityMember> get _eligible {
    final q = _search.text.trim().toLowerCase();
    return _members.where((m) {
      if (m.userId == widget.currentUserId) return false;
      if (m.isBanned) return false;
      if (widget.blockedIds.contains(m.userId)) return false;
      if (q.isEmpty) return true;
      return m.displayName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _pick(CommunityMember m) async {
    final l10n = AppLocalizations.of(context)!;
    final name = m.displayName.trim().isEmpty ? l10n.chatUnknown : m.displayName;
    final sponsored = widget.community.isSponsored ||
        widget.community.pinnedPromo != null ||
        (widget.community.sponsorId ?? '').isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.communityTransferConfirmTitle(name),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityTransferWarning,
                key: const Key('communityTransferWarning'),
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4)),
            if (sponsored) ...[
              const SizedBox(height: 12),
              Text(l10n.communityTransferSponsorshipWarning,
                  key: const Key('communityTransferSponsorshipWarning'),
                  style: const TextStyle(
                      color: AppColors.richGold, height: 1.4)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            key: const Key('communityTransferConfirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.communityTransferConfirmButton,
                style: const TextStyle(
                    color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // The password (or provider sign-in) EVERY time: the server checks the
    // token's auth_time is under 5 minutes old.
    final reauthed =
        await (widget.reauthenticate ?? reauthenticateCurrentUser)(context);
    if (!reauthed || !mounted) return;

    setState(() => _sending = true);
    try {
      await _service.request(
          communityId: widget.community.id, toUserId: m.userId);
      if (!mounted) return;
      _snack(context, l10n.communityTransferSent(name));
      Navigator.of(context).pop(true);
    } on CommunityTransferException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(context, communityTransferFailureText(l10n, e.failure),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligible = _eligible;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(l10n.communityTransferPickTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: AbsorbPointer(
        absorbing: _sending,
        child: Column(
          children: [
            if (_sending) const LinearProgressIndicator(color: AppColors.richGold),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
                  AppDimensions.paddingM, AppDimensions.paddingM, 0),
              child: Text(l10n.communityTransferPickHint,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: TextField(
                key: const Key('communityTransferSearch'),
                controller: _search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.communityTransferSearchHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textTertiary),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: eligible.length + 1,
                itemBuilder: (context, i) {
                  if (i < eligible.length) {
                    final m = eligible[i];
                    return CommunityMemberTile(
                      key: ValueKey('communityTransferMember-${m.userId}'),
                      member: m,
                      onTap: () => _pick(m),
                    );
                  }
                  if (_loading) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.richGold)),
                    );
                  }
                  if (_hasMore || _loadFailed) {
                    return Center(
                      child: TextButton(
                        key: const Key('communityTransferLoadMore'),
                        onPressed: _loadMore,
                        child: Text(l10n.communityTransferLoadMore,
                            style: const TextStyle(color: AppColors.richGold)),
                      ),
                    );
                  }
                  if (eligible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.communityTransferNoMembers,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return const SizedBox(height: 24);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── banner

/// Shown at the top of a community: to the TARGET of a pending ownership
/// offer (Accept / Decline) and to its OWNER (pending + Cancel). Nothing for
/// anybody else.
class CommunityTransferBanner extends StatefulWidget {
  const CommunityTransferBanner({
    required this.communityId,
    required this.currentUserId,
    required this.isCreator,
    this.service,
    this.onResolved,
    super.key,
  });

  final String communityId;
  final String currentUserId;

  /// The viewer is the community's creator (owner side of an offer).
  final bool isCreator;
  final CommunityTransferService? service;

  /// Called when the offer is resolved: this user accepted it, or a pending
  /// offer went away (answered elsewhere) - the screen reloads the community
  /// so owner-only menus follow the new creator.
  final VoidCallback? onResolved;

  @override
  State<CommunityTransferBanner> createState() =>
      _CommunityTransferBannerState();
}

class _CommunityTransferBannerState extends State<CommunityTransferBanner> {
  StreamSubscription<CommunityTransferOffer?>? _sub;
  CommunityTransferOffer? _offer;
  bool _busy = false;

  CommunityTransferService get _service =>
      widget.service ?? CommunityTransferService.instance;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(CommunityTransferBanner old) {
    super.didUpdateWidget(old);
    if (old.isCreator != widget.isCreator ||
        old.communityId != widget.communityId ||
        old.currentUserId != widget.currentUserId) {
      _listen();
    }
  }

  void _listen() {
    _sub?.cancel();
    _offer = null;
    if (widget.currentUserId.isEmpty) return;
    _sub = _service
        .watchOffer(
          communityId: widget.communityId,
          userId: widget.currentUserId,
          asOwner: widget.isCreator,
        )
        .listen((o) {
      if (!mounted) return;
      final wasPending = _offer != null;
      setState(() => _offer = o);
      if (wasPending && o == null) widget.onResolved?.call();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done,
      {VoidCallback? after}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _offer = null;
      });
      _snack(context, done);
      after?.call();
    } on CommunityTransferException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context, communityTransferFailureText(l10n, e.failure),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _offer;
    if (o == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final isTarget = o.toUserId == widget.currentUserId;
    final isOwner = o.fromUserId == widget.currentUserId;
    if (!isTarget && !isOwner) return const SizedBox.shrink();

    const spinner = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.richGold));

    return Container(
      key: Key(isTarget ? 'communityTransferInvite' : 'communityTransferPending'),
      margin: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM, AppDimensions.paddingS, AppDimensions.paddingM, 0),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.richGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.swap_horiz, color: AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTarget
                      ? l10n.communityTransferInviteTitle(
                          o.fromName.isEmpty ? l10n.chatUnknown : o.fromName)
                      : l10n.communityTransferPendingBanner(
                          o.toName.isEmpty ? l10n.chatUnknown : o.toName),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
              ),
            ],
          ),
          if (isTarget) ...[
            const SizedBox(height: 6),
            Text(l10n.communityTransferInviteBody,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _busy
                ? [spinner]
                : isTarget
                    ? [
                        TextButton(
                          key: const Key('communityTransferDecline'),
                          onPressed: () => _run(
                              () => _service.respond(
                                  communityId: widget.communityId,
                                  accept: false),
                              l10n.communityTransferDeclined),
                          child: Text(l10n.communityTransferDecline,
                              style: const TextStyle(
                                  color: AppColors.textTertiary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('communityTransferAccept'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.richGold,
                              foregroundColor: Colors.black),
                          onPressed: () => _run(
                              () => _service.respond(
                                  communityId: widget.communityId,
                                  accept: true),
                              l10n.communityTransferAccepted,
                              after: widget.onResolved),
                          child: Text(l10n.communityTransferAccept),
                        ),
                      ]
                    : [
                        TextButton(
                          key: const Key('communityTransferCancel'),
                          onPressed: () => _run(
                              () => _service.cancel(
                                  communityId: widget.communityId),
                              l10n.communityTransferCancelled),
                          child: Text(l10n.communityTransferCancel,
                              style:
                                  const TextStyle(color: AppColors.errorRed)),
                        ),
                      ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── notification

/// Accept / Decline under a `community_transfer_offer` notification. An offer
/// that was already answered, cancelled or expired is refused by the server
/// ("This offer is no longer available").
class CommunityTransferNotificationActions extends StatefulWidget {
  const CommunityTransferNotificationActions({
    required this.communityId,
    this.service,
    super.key,
  });

  final String communityId;
  final CommunityTransferService? service;

  @override
  State<CommunityTransferNotificationActions> createState() =>
      _CommunityTransferNotificationActionsState();
}

class _CommunityTransferNotificationActionsState
    extends State<CommunityTransferNotificationActions> {
  bool _busy = false;
  bool _done = false;

  Future<void> _respond(bool accept) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await (widget.service ?? CommunityTransferService.instance)
          .respond(communityId: widget.communityId, accept: accept);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      _snack(context,
          accept ? l10n.communityTransferAccepted : l10n.communityTransferDeclined);
    } on CommunityTransferException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = e.failure == CommunityTransferFailure.gone;
      });
      _snack(context, communityTransferFailureText(l10n, e.failure),
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.richGold)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            key: const Key('notifCommunityTransferDecline'),
            onPressed: () => _respond(false),
            child: Text(l10n.communityTransferDecline,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('notifCommunityTransferAccept'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black),
            onPressed: () => _respond(true),
            child: Text(l10n.communityTransferAccept),
          ),
        ],
      ),
    );
  }
}
