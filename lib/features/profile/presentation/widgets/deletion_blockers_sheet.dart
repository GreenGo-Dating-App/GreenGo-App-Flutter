import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/deletion_blockers_service.dart';

/// Delete account is refused while the user sells paid, unrefunded tickets /
/// bookings (owner rule 2026-10-21). This sheet lists them with
/// "Cancel & refund" (buyers are refunded automatically by the server) and,
/// for a refund that failed, "Upload refund proof". Deletion is possible only
/// once the list is empty (the server re-checks on delete).
class DeletionBlockersSheet extends StatefulWidget {
  const DeletionBlockersSheet({
    super.key,
    required this.initial,
    required this.service,
  });

  final List<DeletionBlocker> initial;
  final DeletionBlockersService service;

  /// Shows the sheet; resolves to true when nothing blocks any more.
  static Future<bool> show(
    BuildContext context, {
    required List<DeletionBlocker> blockers,
    DeletionBlockersService? service,
  }) async {
    final r = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeletionBlockersSheet(
        initial: blockers,
        service: service ?? DeletionBlockersService(),
      ),
    );
    return r ?? false;
  }

  @override
  State<DeletionBlockersSheet> createState() => _DeletionBlockersSheetState();
}

class _DeletionBlockersSheetState extends State<DeletionBlockersSheet> {
  late List<DeletionBlocker> _items = widget.initial;
  String? _busy;

  Future<void> _refresh() async {
    try {
      final next = await widget.service.fetch();
      if (!mounted) return;
      setState(() => _items = next);
      if (next.isEmpty) Navigator.of(context).pop(true);
    } catch (_) {
      // Keep the current list; the user can retry.
    }
  }

  Future<bool> _confirm(String message) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.deletionBlockedCancelRefund,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deletionBlockedCancelRefund,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _cancel(DeletionBlocker b) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(b.isEvent
        ? l10n.deletionBlockedConfirmEvent
        : l10n.deletionBlockedConfirmExperience)) {
      return;
    }
    setState(() => _busy = b.listingId);
    try {
      if (b.isEvent) {
        await widget.service.cancelEvent(b.listingId);
      } else {
        await widget.service.cancelBookings(b.bookingIds);
      }
      await _refresh();
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionBlockedActionFailed),
        backgroundColor: AppColors.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _uploadProof(DeletionBlocker b, String orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
      withData: true,
    );
    final file = picked?.files.isNotEmpty == true ? picked!.files.first : null;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null ||
        bytes.length > kRefundProofMaxBytes ||
        refundProofContentType(file.name) == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionBlockedProofTooBig),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }
    setState(() => _busy = orderId);
    try {
      await widget.service.submitRefundProof(orderId: orderId, bytes: bytes, fileName: file.name);
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionBlockedProofSent),
        backgroundColor: AppColors.successGreen,
      ));
      await _refresh();
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deletionBlockedActionFailed),
        backgroundColor: AppColors.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: AppColors.richGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.deletionBlockedTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.deletionBlockedBody,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, i) => _tile(context, _items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, DeletionBlocker b) {
    final l10n = AppLocalizations.of(context)!;
    final lines = <String>[
      if (b.paidOrders > 0) l10n.deletionBlockedPaidCount(b.paidOrders),
      if (b.refundsInProgress > 0) l10n.deletionBlockedInProgress(b.refundsInProgress),
      if (b.failedRefunds > 0) l10n.deletionBlockedFailedCount(b.failedRefunds),
      if (b.pendingReview > 0) l10n.deletionBlockedReviewCount(b.pendingReview),
    ];
    final busy = _busy != null;
    return Column(
      key: ValueKey('blocker_${b.kind}_${b.listingId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${b.isEvent ? l10n.deletionBlockedEvent : l10n.deletionBlockedExperience}: '
          '${b.title.isEmpty ? b.listingId : b.title}',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        for (final s in lines)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (b.canCancel)
              OutlinedButton.icon(
                onPressed: busy ? null : () => _cancel(b),
                icon: _busy == b.listingId
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.event_busy_outlined, size: 18),
                label: Text(l10n.deletionBlockedCancelRefund),
              ),
            for (final orderId in b.failedOrderIds)
              OutlinedButton.icon(
                onPressed: busy ? null : () => _uploadProof(b, orderId),
                icon: _busy == orderId
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(l10n.deletionBlockedUploadProof),
              ),
          ],
        ),
      ],
    );
  }
}
