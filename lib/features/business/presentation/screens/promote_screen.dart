import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../events/domain/entities/event.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../data/services/promotion_service.dart';
import '../widgets/promote_widgets.dart';

/// Promote screen for business/venue accounts.
///
/// Two ways to spend GreenGoCoins on visibility (in-economy, never real money):
///  1. Promote business — boost the storefront/profile in Explore for a period.
///  2. Promote an event — feature one of the business's own upcoming events.
///
/// Coins are charged exclusively through the existing coin API via
/// [PromotionService]; this screen only orchestrates the UX.
class PromoteScreen extends StatefulWidget {
  const PromoteScreen({required this.business, super.key});

  final Profile business;

  @override
  State<PromoteScreen> createState() => _PromoteScreenState();
}

class _PromoteScreenState extends State<PromoteScreen> {
  final PromotionService _service = PromotionService();

  bool _loading = true;
  DateTime? _businessPromotedUntil;

  String get _uid => widget.business.userId;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final until = await _service.getBusinessPromotedUntil(_uid);
    if (!mounted) return;
    setState(() {
      _businessPromotedUntil = until;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) => DateFormat('MMMM d, yyyy').format(d);

  // ---------------------------------------------------------------------------
  // Coin store routing (mirrors the pattern used elsewhere in the app).
  // ---------------------------------------------------------------------------
  void _openCoinStore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(_uid))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: _uid),
        ),
      ),
    );
  }

  Future<void> _handleInsufficientCoins() async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.promoteInsufficientCoins,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.promoteInsufficientCoinsBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.promoteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.promoteGetCoins,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
    if (go == true && mounted) _openCoinStore();
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content:
            Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.promoteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.promoteConfirmCta,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<T> _withBlockingLoader<T>(Future<T> Function() action) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: GlassContainer(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      ),
    );
    try {
      return await action();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _handleResult(PromotionResult result, {bool refreshBusiness = false}) {
    final l10n = AppLocalizations.of(context)!;
    switch (result.outcome) {
      case PromotionOutcome.success:
        HapticFeedback.mediumImpact();
        if (refreshBusiness) {
          setState(() => _businessPromotedUntil = result.promotedUntil);
        }
        _snack(l10n.promoteSuccess);
      case PromotionOutcome.insufficientCoins:
        _handleInsufficientCoins();
      case PromotionOutcome.error:
        _snack(l10n.promoteError);
    }
  }

  // ---------------------------------------------------------------------------
  // Promote business
  // ---------------------------------------------------------------------------
  Future<void> _promoteBusiness() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    final option = await showPromoteDurationSheet(
      context,
      target: PromoteTarget.business,
      heading: l10n.promoteBusinessOption,
    );
    if (option == null || !mounted) return;

    final ok = await _confirm(
      l10n.promoteConfirmTitle,
      l10n.promoteBusinessConfirm(option.days, option.businessCost),
    );
    if (!ok || !mounted) return;

    final result = await _withBlockingLoader(
      () => _service.promoteBusiness(
        _uid,
        days: option.days,
        cost: option.businessCost,
      ),
    );
    if (!mounted) return;
    _handleResult(result, refreshBusiness: true);
  }

  // ---------------------------------------------------------------------------
  // Promote an event
  // ---------------------------------------------------------------------------
  Future<void> _promoteEvents() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();

    final events = await _withBlockingLoader(
      () => _service.getPromotableEvents(_uid),
    );
    if (!mounted) return;
    if (events.isEmpty) {
      _snack(l10n.promoteNoEvents);
      return;
    }

    final event = await _pickEvent(events);
    if (event == null || !mounted) return;

    final option = await showPromoteDurationSheet(
      context,
      target: PromoteTarget.event,
      heading: event.title,
    );
    if (option == null || !mounted) return;

    final ok = await _confirm(
      l10n.promoteConfirmTitle,
      l10n.promoteEventConfirm(option.days, option.eventCost),
    );
    if (!ok || !mounted) return;

    final result = await _withBlockingLoader(
      () => _service.promoteEvent(
        event,
        days: option.days,
        cost: option.eventCost,
      ),
    );
    if (!mounted) return;
    _handleResult(result);
  }

  Future<Event?> _pickEvent(List<Event> events) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<Event>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            borderRadius: AppGlass.radiusSheet,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.promoteSelectEvent,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final e = events[i];
                      final featured = e.isCurrentlyFeatured;
                      return GlassContainer(
                        active: featured,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        onTap: () => Navigator.pop(ctx, e),
                        child: Row(
                          children: [
                            const Icon(Icons.event,
                                color: AppColors.richGold, size: 20),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    featured
                                        ? l10n.promoteEventAlreadyFeatured
                                        : DateFormat('MMM d, yyyy')
                                            .format(e.startDate),
                                    style: TextStyle(
                                      color: featured
                                          ? AppColors.richGold
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = _businessPromotedUntil != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.promoteTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.promoteSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                PromoteOptionCard(
                  icon: Icons.storefront,
                  title: l10n.promoteBusinessOption,
                  description: l10n.promoteBusinessDesc,
                  active: active,
                  statusLabel: active
                      ? l10n.promoteActiveUntil(
                          _formatDate(_businessPromotedUntil!))
                      : l10n.promoteNotActive,
                  onTap: _promoteBusiness,
                ),
                const SizedBox(height: 14),
                PromoteOptionCard(
                  icon: Icons.campaign,
                  title: l10n.promoteEventsOption,
                  description: l10n.promoteEventsDesc,
                  onTap: _promoteEvents,
                ),
              ],
            ),
    );
  }
}
