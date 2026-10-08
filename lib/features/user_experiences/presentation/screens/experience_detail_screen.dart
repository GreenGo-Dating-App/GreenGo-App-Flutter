import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/widgets/translatable_text.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../../experience_bookings/domain/repositories/bookings_repository.dart';
import '../../../experience_bookings/presentation/screens/book_experience_screen.dart';
import '../../../experience_bookings/presentation/screens/bookings_list_screen.dart';
import '../../../experience_bookings/presentation/screens/experience_door_screen.dart';
import '../../../experience_bookings/presentation/screens/experience_slots_screen.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../bloc/experience_detail_bloc.dart';
import '../bloc/experience_reviews_bloc.dart';
import '../experience_l10n.dart';
import '../experience_safety_flow.dart';
import '../widgets/booking_consent_dialog.dart';
import '../widgets/experience_policy_widgets.dart';
import '../widgets/experience_reviews_section.dart';
import '../widgets/experience_widgets.dart';
import '../widgets/report_experience_sheet.dart';
import 'experience_editor_screen.dart';

/// What the detail screen reports back to the list that opened it.
class ExperienceDetailResult {
  const ExperienceDetailResult({this.deletedId, this.updated});
  final String? deletedId;
  final UserExperience? updated;
}

/// Detail of a member-hosted experience: gallery, host, price + external
/// payment link, what's included, practical info and reviews.
class ExperienceDetailScreen extends StatelessWidget {
  const ExperienceDetailScreen({
    super.key,
    required this.experienceId,
    required this.currentUserId,
    this.initial,
  });

  final String experienceId;
  final String currentUserId;
  final UserExperience? initial;

  /// Route by id (notifications / deep links) or from a card ([initial]).
  static Route<ExperienceDetailResult> route({
    required String experienceId,
    required String currentUserId,
    UserExperience? initial,
  }) =>
      MaterialPageRoute(
        builder: (_) => ExperienceDetailScreen(
          experienceId: experienceId,
          currentUserId: currentUserId,
          initial: initial,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = di.sl<UserExperiencesRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ExperienceDetailBloc(repository: repo)
            ..add(ExperienceDetailRequested(experienceId, initial: initial)),
        ),
        BlocProvider(
          create: (_) => ExperienceReviewsBloc(repository: repo)
            ..add(ReviewsStarted(
                experienceId: experienceId, uid: currentUserId)),
        ),
      ],
      child: _DetailView(
          experienceId: experienceId, currentUserId: currentUserId),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.experienceId, required this.currentUserId});
  final String experienceId;
  final String currentUserId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _pageCtrl = PageController();
  int _photo = 0;
  Timer? _refresh;
  UserExperience? _edited;

  /// Upcoming open dates, full ones included (null = loading / failed).
  /// Any date → "Book" opens the booking flow (full dates shown disabled),
  /// never the dateless direct pay.
  List<ExperienceSlot>? _slots;

  /// When [_slots] was read (handed to the booking flow so it can skip its
  /// own re-read of the same dates).
  DateTime? _slotsAt;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final r = await di.sl<BookingsRepository>().slots(widget.experienceId);
    if (!mounted) return;
    r.fold((_) {}, (list) {
      final now = DateTime.now();
      setState(() {
        _slots = list.where((x) => x.isOpen && x.start.isAfter(now)).toList();
        _slotsAt = now;
      });
    });
  }

  bool get _hasSlots => _slots?.isNotEmpty ?? false;

  /// Book a date (bookings) — or, for a listing without dates, the earlier
  /// direct pay flow.
  Future<void> _book(UserExperience e) async {
    if (!_hasSlots) return _pay(e);
    await Navigator.of(context).push(BookExperienceScreen.route(
        experience: e,
        currentUserId: widget.currentUserId,
        initialSlots: _slots,
        initialSlotsAt: _slotsAt));
    if (mounted) _loadSlots();
  }

  Future<void> _openDates(UserExperience e) async {
    final updated = await Navigator.of(context).push(
        ExperienceSlotsScreen.route(
            experience: e, currentUserId: widget.currentUserId));
    if (!mounted) return;
    _loadSlots();
    if (updated != null && updated.requestToBook != e.requestToBook) {
      _edited = updated;
      context
          .read<ExperienceDetailBloc>()
          .add(ExperienceDetailRequested(updated.id, initial: updated));
    }
  }

  void _openDoor(UserExperience e) => Navigator.of(context).push(
      ExperienceDoorScannerScreen.route(
          experience: e, currentUserId: widget.currentUserId));

  void _openBookings(UserExperience e) => Navigator.of(context).push(
        BookingsListScreen.route(
          role: BookingRole.host,
          currentUserId: widget.currentUserId,
          experienceId: e.id,
          title: e.title,
        ),
      );

  @override
  void dispose() {
    _pageCtrl.dispose();
    _refresh?.cancel();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  void _pop(ExperienceDetailResult r) => Navigator.of(context).pop(r);

  /// Pay / Book: ID document uploaded (asked for in place, then continues),
  /// consent dialog (+ method choice), consent recorded, THEN the link opens
  /// (or, for cash, the guest is told to pay at the meeting).
  Future<void> _pay(UserExperience e) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!e.isBookable) return;
    if (!await ExperienceSafetyFlow.ensureIdDocument(
        context, widget.currentUserId, IdDocPurpose.payAsGuest)) {
      return;
    }
    if (!mounted) return;
    final method = await BookingConsentDialog.show(context, e);
    if (method == null || !mounted) return;
    final saved = await di.sl<UserExperiencesRepository>().recordBookingConsent(
          experienceId: e.id,
          uid: widget.currentUserId,
          policy: e.cancellationPolicy,
          version: BookingConsentDialog.version,
          method: method,
        );
    if (!mounted) return;
    if (saved.isLeft()) {
      unawaited(showUserError(context, saved.fold((f) => f, (_) => null)));
      return;
    }
    if (method == PaymentMethod.cash) {
      messenger.showSnackBar(SnackBar(content: Text(l.uexpBookedCash)));
      return;
    }
    final link = e.paymentLink;
    if (link == null) return;
    if (!link.isOpenable) {
      // PIX key (or any non-URL value): copy it.
      await Clipboard.setData(ClipboardData(text: link.value));
      messenger.showSnackBar(SnackBar(content: Text(l.uexpPixCopied)));
      return;
    }
    final uri = Uri.tryParse(link.value);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)
            .catchError((_) => false);
    if (!ok && mounted) {
      unawaited(showUserErrorMessage(context, l.uexpOpenLinkFailed));
    }
  }

  Future<void> _openMaps(UserExperience e) async {
    final q = e.hasCoordinates
        ? '${e.lat},${e.lng}'
        : Uri.encodeComponent(e.locationName);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
  }

  Future<void> _share(UserExperience e) async {
    final l = AppLocalizations.of(context)!;
    await Share.share(
      l.uexpShareText(e.title, 'https://${DeepLinkService.linkHost}'),
      subject: e.title,
    );
  }

  /// "Report scam": reason chips + text → `reports` (3 distinct reporters
  /// auto-hide the listing pending admin review).
  Future<void> _report() async {
    final bloc = context.read<ExperienceDetailBloc>();
    final input = await ReportExperienceSheet.show(context);
    if (input == null) return;
    bloc.add(ExperienceDetailReported(widget.currentUserId,
        reason: input.reason.wire, details: input.details));
  }

  /// Publish through the server with the guided safety prompts.
  Future<void> _publish(UserExperience e) async {
    final bloc = context.read<ExperienceDetailBloc>();
    final published =
        await ExperienceSafetyFlow.publish(context, widget.currentUserId, e);
    if (published != null && mounted) {
      _edited = published;
      bloc.add(ExperienceDetailReplaced(published));
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceDetailBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.uexpDeleteConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l.uexpDeleteConfirmBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.uexpDelete,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(const ExperienceDetailDeleted());
  }

  Future<void> _edit(UserExperience e) async {
    final bloc = context.read<ExperienceDetailBloc>();
    final saved = await Navigator.of(context).push<UserExperience>(
      ExperienceEditorScreen.route(
          currentUserId: widget.currentUserId, existing: e),
    );
    if (saved != null && mounted) {
      _edited = saved;
      bloc.add(ExperienceDetailRequested(saved.id, initial: saved));
    }
  }

  /// Aggregates are recomputed server-side after a review; refresh shortly.
  void _scheduleRefresh(String id) {
    _refresh?.cancel();
    _refresh = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.read<ExperienceDetailBloc>().add(ExperienceDetailRequested(id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<ExperienceDetailBloc, ExperienceDetailState>(
      listenWhen: (a, b) => a.actionSeq != b.actionSeq,
      listener: (context, s) {
        final m = ScaffoldMessenger.of(context);
        switch (s.action) {
          case ExperienceDetailAction.deleted:
            m.showSnackBar(SnackBar(
                content: Text(l.uexpDeleted),
                backgroundColor: AppColors.successGreen));
            _pop(ExperienceDetailResult(deletedId: s.experience?.id));
          case ExperienceDetailAction.reported:
            m.showSnackBar(SnackBar(content: Text(l.uexpReported)));
          case ExperienceDetailAction.statusChanged:
            _edited = s.experience;
            m.showSnackBar(SnackBar(
                content: Text(s.experience?.isPublished == true
                    ? l.uexpPublished
                    : l.uexpUnpublished)));
          case ExperienceDetailAction.failed:
            showUserErrorMessage(context, l.userErrorGeneric);
          case ExperienceDetailAction.none:
            break;
        }
      },
      builder: (context, s) {
        final e = s.experience;
        if (e == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(backgroundColor: AppColors.backgroundDark),
            body: Center(
              child: s.load == ExperienceDetailLoad.loading
                  ? const CircularProgressIndicator(color: AppColors.richGold)
                  : Text(
                      s.load == ExperienceDetailLoad.notFound
                          ? l.uexpNotFound
                          : l.somethingWentWrong,
                      style: const TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _pop(ExperienceDetailResult(updated: _edited));
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: CustomScrollView(
              slivers: [
                _appBar(e, l),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (e.isHidden && e.hostId == widget.currentUserId)
                        _hiddenNotice(l),
                      _header(e, l),
                      const SizedBox(height: 16),
                      _priceCard(e, l),
                      const SizedBox(height: 20),
                      TranslatableText(
                        text: e.description,
                        autoTranslate: true,
                        targetLang: _lang,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      _infoCard(e, l),
                      if (!e.isFree) ...[
                        const SizedBox(height: 20),
                        CancellationPolicyCard(
                          policy: e.cancellationPolicy,
                          notes: e.cancellationNotes,
                          targetLang: _lang,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _itemsSection(l.uexpIncluded, e.included, included: true),
                      if (e.notIncluded.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _itemsSection(l.uexpNotIncluded, e.notIncluded,
                            included: false),
                      ],
                      const SizedBox(height: 28),
                      ExperienceReviewsSection(
                        experience: e,
                        currentUserId: widget.currentUserId,
                        onReviewChanged: () => _scheduleRefresh(e.id),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _appBar(UserExperience e, AppLocalizations l) {
    final photos = e.allPhotos;
    final isHost = e.hostId == widget.currentUserId;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.backgroundDark,
      leading: BackButton(
          onPressed: () => _pop(ExperienceDetailResult(updated: _edited))),
      actions: [
        IconButton(
          tooltip: l.uexpShare,
          icon: const Icon(Icons.share_outlined),
          onPressed: () => _share(e),
        ),
        // A door helper the host authorised: straight to the scanner.
        if (!isHost && e.allowedScannerIds.contains(widget.currentUserId))
          IconButton(
            tooltip: l.expDoorTitle,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openDoor(e),
          ),
        if (isHost)
          PopupMenuButton<String>(
            color: AppColors.backgroundCard,
            onSelected: (v) {
              final bloc = context.read<ExperienceDetailBloc>();
              switch (v) {
                case 'edit':
                  _edit(e);
                case 'dates':
                  _openDates(e);
                case 'bookings':
                  _openBookings(e);
                case 'door':
                  _openDoor(e);
                case 'attendance':
                  Navigator.of(context).push(ExperienceAttendanceScreen.route(
                      experience: e, currentUserId: widget.currentUserId));
                case 'publish':
                  _publish(e);
                case 'unpublish':
                  bloc.add(const ExperienceDetailStatusChanged(
                      ExperienceStatus.draft));
                case 'delete':
                  _delete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Text(l.uexpEdit,
                      style: const TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(
                  value: 'dates',
                  child: Text(l.bkDatesTitle,
                      style: const TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(
                  value: 'bookings',
                  child: Text(l.bkBookings,
                      style: const TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(
                  value: 'door',
                  child: Text(l.expDoorTitle,
                      style: const TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(
                  value: 'attendance',
                  child: Text(l.expAttendanceTitle,
                      style: const TextStyle(color: AppColors.textPrimary))),
              if (e.status == ExperienceStatus.draft)
                PopupMenuItem(
                    value: 'publish',
                    child: Text(l.uexpPublish,
                        style: const TextStyle(color: AppColors.textPrimary))),
              if (e.isPublished)
                PopupMenuItem(
                    value: 'unpublish',
                    child: Text(l.uexpUnpublish,
                        style: const TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(
                  value: 'delete',
                  child: Text(l.uexpDelete,
                      style: const TextStyle(color: AppColors.errorRed))),
            ],
          )
        else
          IconButton(
            tooltip: l.uexpReport,
            icon: const Icon(Icons.flag_outlined),
            onPressed: _report,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: photos.isEmpty ? 1 : photos.length,
            onPageChanged: (i) => setState(() => _photo = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: photos.isEmpty
                  ? null
                  : () => ExperiencePhotoViewer.open(context, photos, i),
              child: ExperienceImage(
                url: photos.isEmpty ? '' : photos[i],
                category: e.category,
              ),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    Container(
                      width: i == _photo ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _photo
                            ? AppColors.richGold
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
        ]),
      ),
    );
  }

  Widget _hiddenNotice(AppLocalizations l) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.visibility_off, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.uexpHiddenNotice,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ]),
      );

  Widget _header(UserExperience e, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: AppColors.richGold.withValues(alpha: 0.12),
            side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.4)),
            avatar: Icon(ExperienceL10n.categoryIcon(e.category),
                size: 16, color: AppColors.richGold),
            label: Text(ExperienceL10n.category(l, e.category),
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
          if (!e.isPublished)
            Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.warningAmber.withValues(alpha: 0.15),
              label: Text(ExperienceL10n.status(l, e.status),
                  style: const TextStyle(color: AppColors.warningAmber)),
            ),
        ]),
        const SizedBox(height: 8),
        TranslatableText(
          text: e.title,
          autoTranslate: true,
          targetLang: _lang,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(children: [
          StarRatingDisplay(rating: e.averageRating, size: 18),
          const SizedBox(width: 6),
          Text(
            e.ratingCount == 0
                ? l.uexpNoReviews
                : '${e.averageRating.toStringAsFixed(1)} · ${l.uexpReviewsCount(e.ratingCount)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.uexpHostedBy,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
              const SizedBox(height: 8),
              UserNameAvatar(
                uid: e.hostId,
                fallbackName: e.hostName,
                fallbackPhoto: e.hostPhotoUrl,
                radius: 18,
                trailing: UserVerifiedBadge(
                    uid: e.hostId, size: 16, showLabel: true),
                onTap: () => openExperienceUserProfile(
                    context, e.hostId, widget.currentUserId),
              ),
              const SizedBox(height: 6),
              HostRatingBadge(hostId: e.hostId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceCard(UserExperience e, AppLocalizations l) {
    final isHost = e.hostId == widget.currentUserId;
    // The host never books their own listing. With dates: the booking flow;
    // without: the earlier direct pay / book (link or cash).
    final canBook = !isHost && (_hasSlots || e.isBookable);
    final hasLink = e.acceptsLink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.richGold.withValues(alpha: 0.16),
          AppColors.backgroundCard,
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExperiencePriceBar(
            priceText: ExperienceL10n.price(l, e),
            // Cash only: "Book" (payment at the meeting); with a link:
            // "Pay / Book".
            payLabel: !canBook
                ? null
                : (_hasSlots
                    ? (e.requestToBook ? l.bkRequestToBook : l.uexpBook)
                    : (hasLink ? l.uexpPayBook : l.uexpBook)),
            payIcon: _hasSlots || !hasLink
                ? Icons.event_available
                : (!e.paymentLink!.isOpenable
                    ? Icons.copy_rounded
                    : Icons.open_in_new),
            onPay: () => _book(e),
          ),
          if (_slots != null && (!isHost || _hasSlots)) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 15, color: AppColors.richGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _hasSlots
                      ? l.bkDatesAvailable(_slots!
                          .where((x) => x.isBookableAt(DateTime.now()))
                          .length)
                      : l.bkNoDates,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ]),
          ],
          if (e.isBookable) ...[
            const SizedBox(height: 10),
            PaymentMethodsList(experience: e),
          ],
          if (hasLink || !e.isFree) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l.uexpPaymentDisclaimer,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(UserExperience e, AppLocalizations l) {
    Widget row(IconData icon, String label, Widget value, {VoidCallback? onTap}) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: AppColors.richGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(height: 2),
                    value,
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.open_in_new,
                    size: 16, color: AppColors.textTertiary),
            ]),
          ),
        );
    Text plain(String v) => Text(v,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14));
    Widget translated(String v) => TranslatableText(
          text: v,
          autoTranslate: true,
          targetLang: _lang,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        );

    final place = [e.city, e.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        row(Icons.place_outlined, l.uexpFieldLocation,
            plain([e.locationName, if (place.isNotEmpty && !e.locationName.contains(place)) place].join(' · ')),
            onTap: () => _openMaps(e)),
        if (e.meetingPoint != null)
          row(Icons.flag_circle_outlined, l.uexpMeetingPointLabel,
              translated(e.meetingPoint!)),
        row(Icons.schedule, l.uexpDuration,
            plain(ExperienceL10n.duration(l, e.durationMinutes))),
        row(Icons.groups_outlined, l.uexpGroupSize,
            plain(ExperienceL10n.groupSize(l, e.minGroupSize, e.maxGroupSize))),
        row(Icons.translate, l.uexpLanguages, plain(e.languages.join(', '))),
      ]),
    );
  }

  Widget _itemsSection(String title, List<String> items,
      {required bool included}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                included ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: included ? AppColors.successGreen : AppColors.errorRed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TranslatableText(
                  text: it,
                  autoTranslate: true,
                  targetLang: _lang,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
