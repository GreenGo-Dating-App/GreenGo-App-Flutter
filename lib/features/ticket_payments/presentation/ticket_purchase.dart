import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/own_profile_store.dart';
import '../../../core/utils/base_membership_gate.dart';
import '../../../generated/app_localizations.dart';
import '../data/ticket_payments_service.dart';
import 'screens/ticket_order_screen.dart';
import 'ticket_l10n.dart';

/// Starts a ticket purchase and shows its order screen.
///
/// Instant (Stripe / MP): the checkout opens INSIDE the app (Custom Tab /
/// SFSafariViewController); on web the same tab is redirected and the return
/// page deep-links back to `/t/{orderId}`. Free ticket types: the order screen
/// shows the tickets right away. (Payment links are no longer accepted.)
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
    if (!r.isFree && r.checkoutUrl != null) {
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
    // No Base membership (owner rule 2026-10-11): the upsell, not an error.
    final uid = OwnProfileStore.instance.uid;
    if (e is TicketPaymentException &&
        uid != null &&
        context.mounted &&
        await BaseMembershipGate.handleParticipationError(context,
            userId: uid, reason: e.reason)) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
  }
}
