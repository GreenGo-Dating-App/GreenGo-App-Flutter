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
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../bloc/experience_detail_bloc.dart';
import '../bloc/experience_reviews_bloc.dart';
import '../experience_l10n.dart';
import '../widgets/experience_reviews_section.dart';
import '../widgets/experience_widgets.dart';
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
      child: _DetailView(currentUserId: currentUserId),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _pageCtrl = PageController();
  int _photo = 0;
  Timer? _refresh;
  UserExperience? _edited;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _refresh?.cancel();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  void _pop(ExperienceDetailResult r) => Navigator.of(context).pop(r);

  Future<void> _pay(UserExperience e) async {
    final l = AppLocalizations.of(context)!;
    final link = e.paymentLink;
    if (link == null) return;
    final messenger = ScaffoldMessenger.of(context);
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
    if (!ok) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.uexpOpenLinkFailed),
          backgroundColor: AppColors.errorRed));
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

  Future<void> _report() async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceDetailBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.uexpReportTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l.uexpReportBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.uexpReport,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(ExperienceDetailReported(widget.currentUserId));
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
            m.showSnackBar(SnackBar(
                content: Text(l.somethingWentWrong),
                backgroundColor: AppColors.errorRed));
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
        if (isHost)
          PopupMenuButton<String>(
            color: AppColors.backgroundCard,
            onSelected: (v) {
              final bloc = context.read<ExperienceDetailBloc>();
              switch (v) {
                case 'edit':
                  _edit(e);
                case 'publish':
                  bloc.add(const ExperienceDetailStatusChanged(
                      ExperienceStatus.published));
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
                onTap: () => openExperienceUserProfile(
                    context, e.hostId, widget.currentUserId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceCard(UserExperience e, AppLocalizations l) {
    final hasLink = e.paymentLink != null;
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
          Row(children: [
            Expanded(
              child: Text(ExperienceL10n.price(l, e),
                  style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            if (hasLink)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                ),
                onPressed: () => _pay(e),
                icon: Icon(e.paymentLink!.isOpenable
                    ? Icons.open_in_new
                    : Icons.copy_rounded),
                label: Text(l.uexpPayBook),
              ),
          ]),
          if (hasLink) ...[
            const SizedBox(height: 6),
            Text(
              '${ExperienceL10n.paymentType(l, e.paymentLink!.type)}'
              '${e.paymentLink!.isOpenable ? '' : ' · ${e.paymentLink!.value}'}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
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
        if (e.availability != null)
          row(Icons.event_available, l.uexpAvailabilityLabel,
              translated(e.availability!)),
        if (e.cancellationPolicy != null)
          row(Icons.policy_outlined, l.uexpCancellationLabel,
              translated(e.cancellationPolicy!)),
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
