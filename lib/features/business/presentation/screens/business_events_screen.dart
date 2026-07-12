import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/screens/event_analytics_screen.dart';
import '../../../coins/domain/usecases/purchase_feature.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/bloc/events_bloc.dart';
import '../../../events/presentation/bloc/events_event.dart';
import '../../../events/presentation/bloc/events_state.dart';
import '../../../events/presentation/screens/events_screen.dart'
    show CreateEventScreen, buildEventStatusBadges, kFeatureEventCost;
import '../../../profile/domain/entities/profile.dart';

/// "Manage my events" — a business/organizer's control room for their OWN
/// events. Lists every event the user organized (including drafts and scheduled
/// ones, with status badges) and exposes quick manage actions per event:
///
///  - Edit      → the existing create/edit event screen
///  - Cancel    → delete a standalone event, or cancel a whole recurring series
///  - Feature   → the existing paid coin "Feature this event" placement
///  - Analytics → the per-event [EventAnalyticsScreen] dashboard
///
/// It owns its own [EventsBloc] (via DI) so it stays self-contained and can be
/// opened from anywhere (e.g. the Business hub) without a provider in scope.
class BusinessEventsScreen extends StatelessWidget {
  const BusinessEventsScreen({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsBloc>(
      create: (_) =>
          sl<EventsBloc>()..add(LoadUserEvents(userId: profile.userId)),
      child: _BusinessEventsView(profile: profile),
    );
  }
}

class _BusinessEventsView extends StatelessWidget {
  const _BusinessEventsView({required this.profile});

  final Profile profile;

  String get _uid => profile.userId;

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
          l10n.businessEventsTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state is EventsLoading || state is EventsInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            );
          }

          // Only events this user ORGANIZED (drafts + scheduled included).
          final events = <Event>[];
          if (state is EventsLoaded) {
            events.addAll(
              state.userEvents.where((e) => e.organizerId == _uid),
            );
          }

          if (events.isEmpty) {
            return _buildEmpty(l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _EventRow(
              event: events[i],
              profile: profile,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note,
                    color: AppColors.richGold, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.businessEventsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single manageable event card with its quick actions.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.profile});

  final Event event;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.groups,
                            color: AppColors.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${event.goingCount}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: buildEventStatusBadges(context, event,
                              compact: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (event.isCurrentlyFeatured)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.star, color: AppColors.richGold, size: 20),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              _action(
                context,
                icon: Icons.bar_chart,
                label: l10n.businessEventsAnalytics,
                onTap: () => _openAnalytics(context),
              ),
              _action(
                context,
                icon: Icons.edit,
                label: l10n.eventsEditEvent,
                onTap: () => _openEdit(context),
              ),
              if (!event.isCurrentlyFeatured)
                _action(
                  context,
                  icon: Icons.rocket_launch,
                  label: l10n.featureThisEvent,
                  onTap: () => _handleFeature(context),
                ),
              _action(
                context,
                icon: Icons.cancel_outlined,
                label: l10n.cancel,
                danger: true,
                onTap: () => _confirmCancel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.errorRed : AppColors.richGold;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openAnalytics(BuildContext context) async {
    final allowed = await TierGate()
        .ensureAnalytics(context, _uid, knownTier: profile.membershipTier);
    if (!allowed || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventAnalyticsScreen(
          eventId: event.id,
          tier: profile.membershipTier,
          eventTitle: event.title,
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    final bloc = context.read<EventsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => BlocProvider.value(
          value: bloc,
          child: CreateEventScreen(
            currentUserId: _uid,
            existing: event,
            onEventCreated: (e) {
              bloc.add(UpdateEvent(event: e));
              Navigator.of(ctx).pop();
            },
            onEventDeleted: () {
              bloc.add(DeleteEvent(eventId: event.id));
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<EventsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final isSeries = event.isRecurring &&
        event.seriesId != null &&
        event.seriesId!.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(
          l10n.businessEventsCancelTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isSeries
              ? l10n.businessEventsCancelSeriesMessage
              : l10n.businessEventsCancelMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.businessEventsCancelConfirm,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (isSeries) {
      try {
        await sl<EventsRemoteDataSource>().cancelSeries(event.seriesId!);
      } catch (_) {
        // fall through to a single-event delete as a safety net
        bloc.add(DeleteEvent(eventId: event.id));
      }
      bloc.add(LoadUserEvents(userId: _uid));
    } else {
      bloc.add(DeleteEvent(eventId: event.id));
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.businessEventsCancelled)),
    );
  }

  /// Reuses the existing paid coin "Feature this event" flow.
  Future<void> _handleFeature(BuildContext context) async {
    const cost = kFeatureEventCost;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();

    final afford = await sl<CanAffordFeature>()(userId: _uid, cost: cost);
    if (!context.mounted) return;
    if (!afford.fold((_) => false, (v) => v)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.eventsInsufficientCoins)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(l10n.featureThisEvent,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.featureEventCostLabel(cost),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.featureThisEvent,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final charge = await sl<PurchaseFeature>()(
      userId: _uid,
      featureName: 'event_featured',
      cost: cost,
      relatedId: event.id,
    );
    if (!context.mounted) return;
    if (!charge.fold((_) => false, (_) => true)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.eventsInsufficientCoins)),
      );
      return;
    }
    bloc.add(
      UpdateEvent(
        event: event.copyWith(
          isFeatured: true,
          featuredUntil: DateTime.now().add(const Duration(days: 7)),
        ),
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventsBoosted)));
  }

  String get _uid => profile.userId;
}
