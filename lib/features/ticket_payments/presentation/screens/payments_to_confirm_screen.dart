import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';

/// Organizer: manual (payment link / cash / bank transfer) payments that the
/// buyer marked as sent. Confirm (one tap, or several at once) issues the
/// tickets; Reject (with a reason) frees the seats. GreenGo does not verify
/// these payments: check your own account for the amount and the GG- code.
class PaymentsToConfirmScreen extends StatefulWidget {
  const PaymentsToConfirmScreen({super.key, required this.uid, this.service});

  final String uid;
  final TicketPaymentsService? service;

  static Route<void> route(String uid) =>
      MaterialPageRoute(builder: (_) => PaymentsToConfirmScreen(uid: uid));

  @override
  State<PaymentsToConfirmScreen> createState() => _PaymentsToConfirmScreenState();
}

class _PaymentsToConfirmScreenState extends State<PaymentsToConfirmScreen> {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  final Set<String> _selected = {};
  bool _busy = false;

  Future<void> _confirm(List<String> ids) async {
    if (ids.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final r = await _svc.confirm(ids);
      final ok = r.values.where((v) => v == 'paid' || v == 'already').length;
      messenger.showSnackBar(SnackBar(content: Text(l.tpConfirmedCount(ok))));
      setState(() => _selected.removeAll(ids));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(TicketOrder o) async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.tpRejectTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLength: 300,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: l.tpRejectReason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(l.tpReject, style: const TextStyle(color: AppColors.errorRed))),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _svc.reject(o.id, reason);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
    }
  }

  Future<void> _showReceipt(TicketOrder o) async {
    final url = await _svc.receiptUrl(o.receiptPath!);
    if (url == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.backgroundCard,
        child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, title: Text(l.tpToConfirmTitle)),
      body: StreamBuilder<List<TicketOrder>>(
        stream: _svc.watchToConfirm(widget.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.tpToConfirmEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(l.tpToConfirmInfo,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
            ),
            if (suggestInstantForPending(orders.length))
              Container(
                key: const ValueKey('to-confirm-instant-hint'),
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(l.tpTiredOfConfirming,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _tile(l, orders[i]),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack),
                    onPressed: _busy || _selected.isEmpty ? null : () => _confirm(_selected.toList()),
                    icon: const Icon(Icons.done_all),
                    label: Text(l.tpConfirmSelected(_selected.length)),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _tile(AppLocalizations l, TicketOrder o) {
    final when = o.sentAt == null ? '' : DateFormat.MMMd().add_Hm().format(o.sentAt!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Checkbox(
            value: _selected.contains(o.id),
            activeColor: AppColors.richGold,
            onChanged: (v) => setState(() => v == true ? _selected.add(o.id) : _selected.remove(o.id)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${o.code ?? ''} · ${formatTicketAmount(o.totalAmount, o.currency)} · ${l.tpTicketsCount(o.quantity)}',
                  style: const TextStyle(color: AppColors.richGold, fontSize: 13)),
              Text('${TicketL10n.method(l, o.paymentMethod ?? '')} · $when',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ]),
          ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (o.receiptPath != null)
            TextButton.icon(
              onPressed: () => _showReceipt(o),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(l.tpViewReceipt),
            ),
          TextButton(
            onPressed: _busy ? null : () => _reject(o),
            child: Text(l.tpReject, style: const TextStyle(color: AppColors.errorRed)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen, foregroundColor: Colors.white),
            onPressed: _busy ? null : () => _confirm([o.id]),
            child: Text(l.tpConfirm),
          ),
        ]),
      ]),
    );
  }
}
