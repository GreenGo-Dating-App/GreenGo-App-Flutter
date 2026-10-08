import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../data/ticket_payments_service.dart';
import 'screens/ticket_order_screen.dart';
import 'ticket_l10n.dart';

/// Starts a ticket purchase and shows its order screen.
///
/// Instant (Stripe / MP): the checkout opens INSIDE the app (Custom Tab /
/// SFSafariViewController); on web the same tab is redirected and the return
/// page deep-links back to `/t/{orderId}`. Manual: the order screen shows the
/// amount, the GG- code and the organizer's payment method.
Future<void> startTicketPurchase(
  BuildContext context, {
  required String kind,
  required String id,
  String? bookingId,
  int quantity = 1,
  Map<String, int>? items,
  TicketPaymentsService? service,
}) async {
  final l = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final svc = service ?? TicketPaymentsService();
  try {
    final r = await svc.createCheckout(
      kind: kind,
      id: id,
      bookingId: bookingId,
      quantity: quantity,
      items: items,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    if (!r.isLink && !r.isFree && r.checkoutUrl != null) {
      if (kIsWeb) {
        await TicketPaymentsService.openInApp(r.checkoutUrl!);
        return;
      }
      // The order screen is underneath when the in-app browser closes.
      // ignore: unawaited_futures
      navigator.push(TicketOrderScreen.route(r.orderId));
      await TicketPaymentsService.openInApp(r.checkoutUrl!);
      return;
    }
    await navigator.push(TicketOrderScreen.route(r.orderId));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
  }
}
