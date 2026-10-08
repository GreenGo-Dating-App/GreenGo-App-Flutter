import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';
import 'ticket_order_screen.dart';

/// Buyer: "My purchases" — every ticket order, newest first (one indexed,
/// bounded query). Open orders can be resumed (pay / "I've paid"); paid ones
/// show their tickets and QR codes (cached for offline use).
class MyTicketOrdersScreen extends StatefulWidget {
  const MyTicketOrdersScreen({super.key, required this.uid, this.service});

  final String uid;
  final TicketPaymentsService? service;

  static Route<void> route(String uid) =>
      MaterialPageRoute(builder: (_) => MyTicketOrdersScreen(uid: uid));

  @override
  State<MyTicketOrdersScreen> createState() => _MyTicketOrdersScreenState();
}

class _MyTicketOrdersScreenState extends State<MyTicketOrdersScreen> {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  late Future<List<TicketOrder>> _orders = _svc.myOrders(widget.uid);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, title: Text(l.tpMyPurchases)),
      body: FutureBuilder<List<TicketOrder>>(
        future: _orders,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          }
          final list = snap.data ?? const <TicketOrder>[];
          if (list.isEmpty) {
            return Center(
                child: Text(l.tpNoPurchases, style: const TextStyle(color: AppColors.textSecondary)));
          }
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: () async {
              final f = _svc.myOrders(widget.uid);
              setState(() => _orders = f);
              await f;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = list[i];
                final paid = o.status == TicketOrderStatus.paid;
                return ListTile(
                  tileColor: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(paid ? Icons.qr_code_2 : Icons.receipt_long,
                      color: paid ? AppColors.richGold : AppColors.textTertiary),
                  title: Text(o.title ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    [
                      formatTicketAmount(o.totalAmount, o.currency),
                      l.tpTicketsCount(o.quantity),
                      TicketL10n.orderStatus(l, o.status),
                      if (o.startsAt != null) DateFormat.MMMd().add_Hm().format(o.startsAt!),
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => Navigator.of(context).push(TicketOrderScreen.route(o.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
