import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';

/// One ticket order, live (`ticket_orders/{id}`):
///  * instant (Stripe / MP): "Waiting for payment confirmation…", 30-min
///    countdown, Pay again / Cancel; the provider webhook flips it to paid;
///  * manual: amount + GG- code + the organizer's method, "I've paid" (optional
///    receipt) and then "Waiting for the organizer…";
///  * paid: one QR per ticket (cached for offline use; each can be shared).
/// The QR exists only after the payment is confirmed.
class TicketOrderScreen extends StatefulWidget {
  const TicketOrderScreen({super.key, required this.orderId, this.service});

  final String orderId;
  final TicketPaymentsService? service;

  static Route<void> route(String orderId) =>
      MaterialPageRoute(builder: (_) => TicketOrderScreen(orderId: orderId));

  @override
  State<TicketOrderScreen> createState() => _TicketOrderScreenState();
}

class _TicketOrderScreenState extends State<TicketOrderScreen> with WidgetsBindingObserver {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  late final Stream<TicketOrder?> _order = _svc.watchOrder(widget.orderId);
  Timer? _tick;
  bool _busy = false;
  Uint8List? _receipt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    unawaited(_svc.syncOrder(widget.orderId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  /// Back from the in-app browser: ask the provider directly (webhook may lag).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_svc.syncOrder(widget.orderId));
  }

  Future<void> _run(Future<void> Function() f) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickReceipt() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 75);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _receipt = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, title: Text(l.tpOrderTitle)),
      body: StreamBuilder<TicketOrder?>(
        stream: _order,
        builder: (context, snap) {
          final o = snap.data;
          if (o == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(o.title ?? '',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${formatTicketAmount(o.totalAmount, o.currency)} · ${l.tpTicketsCount(o.quantity)}',
                key: const ValueKey('ticket-order-amount'),
                style: const TextStyle(color: AppColors.richGold, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _statusCard(l, o),
            const SizedBox(height: 16),
            ..._body(l, o),
          ]);
        },
      ),
    );
  }

  Widget _statusCard(AppLocalizations l, TicketOrder o) {
    final paid = o.status == TicketOrderStatus.paid;
    final bad = !o.status.isOpen && !paid;
    final color = paid ? AppColors.successGreen : (bad ? AppColors.errorRed : AppColors.warningAmber);
    final left = o.expiresAt?.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(paid ? Icons.verified : (bad ? Icons.error_outline : Icons.hourglass_top), color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(paid ? l.tpPaymentConfirmed : TicketL10n.orderStatus(l, o.status),
                key: const ValueKey('ticket-order-status'),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            if (o.status.isOpen && left != null && !left.isNegative)
              Text(l.tpHoldCountdown(_fmt(left)),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            if (o.status == TicketOrderStatus.pending && o.provider == TicketProvider.mercadoPago)
              Text(l.tpPixHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            if (o.status == TicketOrderStatus.rejected && (o.rejectReason ?? '').isNotEmpty)
              Text(o.rejectReason!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ]),
        ),
      ]),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  List<Widget> _body(AppLocalizations l, TicketOrder o) {
    switch (o.status) {
      case TicketOrderStatus.creating:
      case TicketOrderStatus.pending:
        return [
          _primary(l.tpPayAgain, Icons.open_in_new,
              o.checkoutUrl == null ? null : () => TicketPaymentsService.openInApp(o.checkoutUrl!),
              key: 'ticket-pay-again'),
          const SizedBox(height: 8),
          _secondary(l.tpCancelOrder, () => _run(() => _svc.cancelOrder(o.id))),
        ];
      case TicketOrderStatus.pendingPayment:
        return [
          ..._linkInstructions(l, o),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickReceipt,
            icon: Icon(_receipt == null ? Icons.add_photo_alternate_outlined : Icons.check_circle,
                color: AppColors.richGold),
            label: Text(_receipt == null ? l.tpAttachReceipt : l.tpReceiptAttached),
          ),
          const SizedBox(height: 8),
          _primary(l.tpIvePaid, Icons.done_all,
              () => _run(() => _svc.markPaymentSent(o.id, receipt: _receipt)),
              key: 'ticket-ive-paid'),
          const SizedBox(height: 8),
          _secondary(l.tpCancelOrder, () => _run(() => _svc.cancelOrder(o.id))),
        ];
      case TicketOrderStatus.awaitingConfirmation:
        return [
          ..._linkInstructions(l, o),
          const SizedBox(height: 12),
          Text(l.tpAwaitingOrganizerInfo,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          _secondary(l.tpCancelOrder, () => _run(() => _svc.cancelOrder(o.id))),
        ];
      case TicketOrderStatus.paid:
        return [_TicketsList(service: _svc, orderId: o.id)];
      default:
        return [
          Text(l.tpOrderClosedInfo, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _secondary(l.tpClose, () => Navigator.of(context).maybePop()),
        ];
    }
  }

  List<Widget> _linkInstructions(AppLocalizations l, TicketOrder o) {
    final value = o.paymentValue;
    final isUrl = value != null && value.startsWith('http');
    return [
      Text(l.tpPayWith(TicketL10n.method(l, o.paymentMethod ?? '')),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _copyRow(l, l.tpAmountLabel, formatTicketAmount(o.totalAmount, o.currency)),
      if (o.code != null) _copyRow(l, l.tpCodeLabel, o.code!, key: 'ticket-code'),
      if (o.code != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.tpCodeHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ),
      if (value != null) _copyRow(l, TicketL10n.method(l, o.paymentMethod ?? ''), value),
      if (isUrl)
        _primary(l.tpOpenPaymentLink, Icons.open_in_new, () => TicketPaymentsService.openInApp(value)),
      if ((o.paymentInstructions ?? '').isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(o.paymentInstructions!, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      const SizedBox(height: 8),
      Text(l.tpManualDisclaimer, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
    ];
  }

  Widget _copyRow(AppLocalizations l, String label, String value, {String? key}) => Container(
        key: key == null ? null : ValueKey(key),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.backgroundInput, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
              SelectableText(value,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
          IconButton(
            tooltip: l.tpCopy,
            icon: const Icon(Icons.copy, color: AppColors.richGold, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.tpCopied)));
            },
          ),
        ]),
      );

  Widget _primary(String label, IconData icon, VoidCallback? onTap, {String? key}) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: key == null ? null : ValueKey(key),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );

  Widget _secondary(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: TextButton(onPressed: _busy ? null : onTap, child: Text(label)),
      );
}

/// The paid tickets of one order, each with its own QR (works offline once
/// shown: the payloads are cached on the device).
class _TicketsList extends StatelessWidget {
  const _TicketsList({required this.service, required this.orderId});

  final TicketPaymentsService service;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<IssuedTicket>>(
      stream: service.watchOrderTickets(uid, orderId),
      builder: (context, snap) {
        final list = snap.data ?? const <IssuedTicket>[];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
          );
        }
        return Column(children: [for (final t in list) TicketQrCard(ticket: t)]);
      },
    );
  }
}

/// One ticket: QR (single use at the door), type badge, party size, share.
class TicketQrCard extends StatelessWidget {
  const TicketQrCard({super.key, required this.ticket});

  final IssuedTicket ticket;

  Future<void> _share(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final title = ticket.title ?? '';
    final text = l.tpShareTicketText(title, ticket.index, ticket.of);
    try {
      if (!kIsWeb) {
        final painter = QrPainter(data: ticket.qrPayload, version: QrVersions.auto, gapless: true,
            eyeStyle: const QrEyeStyle(color: Colors.black), dataModuleStyle: const QrDataModuleStyle(color: Colors.black));
        final img = await painter.toImageData(900, format: ui.ImageByteFormat.png);
        if (img != null) {
          await Share.shareXFiles(
            [XFile.fromData(img.buffer.asUint8List(), mimeType: 'image/png', name: 'ticket-${ticket.id}.png')],
            text: text,
          );
          return;
        }
      }
      await Share.share('$text\n${ticket.qrPayload}');
    } catch (_) {/* share sheet dismissed / unavailable */}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final valid = ticket.isValid;
    return Container(
      key: ValueKey('ticket-${ticket.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: valid ? AppColors.richGold.withValues(alpha: 0.5) : AppColors.errorRed),
      ),
      child: Column(children: [
        Row(children: [
          Text(l.tpTicketIndex(ticket.index, ticket.of),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const Spacer(),
          if (ticket.typeName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.richGold, borderRadius: BorderRadius.circular(8)),
              child: Text(ticket.typeName!.toUpperCase(),
                  style: const TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.w800)),
            ),
        ]),
        if (ticket.partySize > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l.tpGroupOf(ticket.partySize),
                style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 10),
        if (valid)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: QrImageView(data: ticket.qrPayload, size: 220, backgroundColor: Colors.white),
          )
        else
          Text(l.tpTicketInvalid, style: const TextStyle(color: AppColors.errorRed)),
        if (ticket.checkedIn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.tpTicketUsed, style: const TextStyle(color: AppColors.textTertiary)),
          ),
        if (valid)
          TextButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text(l.tpShareTicket),
          ),
      ]),
    );
  }
}
