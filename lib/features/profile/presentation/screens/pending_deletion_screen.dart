import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/deletion_blockers_service.dart';
import '../widgets/deletion_blockers_sheet.dart';

/// The account deletion was requested while paid sales were not refunded
/// (Apple 5.1.1(v), 2026-10-22; server: functions/src/auth/scheduledDeletion.ts).
/// Shows the status, what still waits (refunds in progress / failed ->
/// "Upload refund proof"), and "Cancel deletion request" (the listings it
/// cancelled stay cancelled; the dialog says so).
class PendingDeletionScreen extends StatefulWidget {
  const PendingDeletionScreen({super.key, this.service, this.initial});

  final DeletionBlockersService? service;

  /// Already loaded state (skips the first fetch).
  final DeletionState? initial;

  static Future<void> open(BuildContext context,
      {DeletionBlockersService? service, DeletionState? initial}) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PendingDeletionScreen(service: service, initial: initial),
    ));
  }

  @override
  State<PendingDeletionScreen> createState() => _PendingDeletionScreenState();
}

class _PendingDeletionScreenState extends State<PendingDeletionScreen> {
  late final DeletionBlockersService _service =
      widget.service ?? DeletionBlockersService();
  DeletionState? _state;
  bool _loading = false;
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
    if (_state == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final s = await _service.fetchState();
      if (!mounted) return;
      setState(() => _state = s);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.deletionPendingCancel,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.deletionPendingCancelConfirm,
          key: const ValueKey('pending-deletion-cancel-confirm'),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
            key: const ValueKey('pending-deletion-keep-account'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deletionPendingKeepAccount,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await _service.cancelScheduledDeletion();
      if (!mounted) return;
      if (r == CancelDeletionResult.tooLate) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.deletionPendingTooLate),
          backgroundColor: AppColors.errorRed,
        ));
        await _load();
        return;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionPendingCancelled),
        backgroundColor: AppColors.successGreen,
      ));
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionBlockedActionFailed),
        backgroundColor: AppColors.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openItems(List<DeletionBlocker> blockers) async {
    await DeletionBlockersSheet.show(context,
        blockers: blockers, service: _service, requestMode: false);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.deletionPendingTitle),
      ),
      body: SafeArea(child: _body(context, l10n)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final s = _state;
    if (s == null) {
      if (_failed && !_loading) {
        return Center(
          child: TextButton(
              onPressed: _load, child: Text(l10n.deletionBlockedCheckFailed)),
        );
      }
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    final sched = s.scheduled;
    final locale = Localizations.localeOf(context).toString();
    final date = sched?.requestedAt == null
        ? ''
        : DateFormat.yMMMMd(locale).format(sched!.requestedAt!.toLocal());
    final failedOrders =
        s.blockers.fold<int>(0, (n, b) => n + b.failedOrderIds.length);
    const body = TextStyle(color: AppColors.textSecondary, height: 1.45);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.deletionPendingTitle,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sched == null)
            Text(l10n.deletionPendingNothingLeft, style: body)
          else if (sched.isDeleting)
            Text(l10n.deletionPendingDeleting,
                key: const ValueKey('pending-deletion-status'), style: body)
          else if (sched.isFailed)
            Text(l10n.deletionPendingFailed,
                key: const ValueKey('pending-deletion-status'), style: body)
          else
            Text(l10n.deletionPendingBody(date),
                key: const ValueKey('pending-deletion-status'), style: body),
          const SizedBox(height: 8),
          Text(l10n.deletionPendingHidden, style: body),
          const SizedBox(height: 16),
          if (s.blockers.isEmpty &&
              sched != null &&
              !sched.isDeleting &&
              !sched.isFailed)
            Text(l10n.deletionPendingNothingLeft, style: body),
          for (final b in s.blockers) _blockerTile(l10n, b),
          if (failedOrders > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('pending-deletion-upload-proof'),
              onPressed: _busy ? null : () => _openItems(s.blockers),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(l10n.deletionBlockedUploadProof),
            ),
          ],
          const SizedBox(height: 24),
          if (sched != null && !sched.isDeleting)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('pending-deletion-cancel'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold),
                onPressed: _busy ? null : _cancelRequest,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.deletionPendingCancel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blockerTile(AppLocalizations l10n, DeletionBlocker b) {
    final lines = <String>[
      if (b.refundsInProgress > 0)
        l10n.deletionBlockedInProgress(b.refundsInProgress),
      if (b.failedRefunds > 0) l10n.deletionBlockedFailedCount(b.failedRefunds),
      if (b.pendingReview > 0) l10n.deletionBlockedReviewCount(b.pendingReview),
      if (b.refundsInProgress + b.failedRefunds + b.pendingReview == 0 &&
          b.paidOrders > 0)
        l10n.deletionBlockedPaidCount(b.paidOrders),
    ];
    return Padding(
      key: ValueKey('pending_blocker_${b.kind}_${b.listingId}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b.isEvent ? l10n.deletionBlockedEvent : l10n.deletionBlockedExperience}: '
            '${b.title.isEmpty ? b.listingId : b.title}',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          for (final t in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(t,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
