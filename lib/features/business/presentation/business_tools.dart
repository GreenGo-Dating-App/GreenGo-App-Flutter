import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/tier_gate.dart';
import '../../analytics/presentation/screens/analytics_screen.dart';
import '../../experience_bookings/domain/entities/booking.dart';
import '../../experience_bookings/presentation/screens/bookings_list_screen.dart';
import '../../explore/presentation/screens/qr_hub_screen.dart';
import '../../finance_documents/presentation/screens/finance_documents_screen.dart';
import '../../my_space/presentation/screens/my_space_screen.dart';
import '../../profile/domain/entities/profile.dart';
import '../../profile/presentation/bloc/profile_bloc.dart';
import '../../ticket_payments/presentation/screens/get_paid_screen.dart';
import '../../ticket_payments/presentation/screens/payments_to_confirm_screen.dart';
import 'screens/business_account_screen.dart';
import 'screens/business_events_screen.dart';
import 'screens/business_leads_screen.dart';
import 'screens/business_storefront_screen.dart';
import 'screens/business_verification_request_screen.dart';
import 'screens/followers_screen.dart';
import 'screens/promote_screen.dart';
import 'screens/storefront_editor_screen.dart';

/// Every business tool's destination, shared by the Business Center and the
/// (paused-state) Business hub so both open exactly the same screens. Screens
/// that edit the profile get the caller's [ProfileBloc].
class BusinessTools {
  const BusinessTools._();

  static Future<void> _push(BuildContext context, Route<void> route) => Navigator.of(context).push(route);

  static Route<void> _withBloc(BuildContext context, Widget child) {
    final bloc = context.read<ProfileBloc>();
    return MaterialPageRoute<void>(builder: (_) => BlocProvider.value(value: bloc, child: child));
  }

  static Future<void> openBusinessAccount(BuildContext context, Profile p) =>
      _push(context, _withBloc(context, BusinessAccountScreen(profile: p)));

  /// [TierGate.ensureAnalytics] shows the upgrade dialog below Platinum.
  static Future<void> openAnalytics(BuildContext context, Profile p) async {
    final allowed = await TierGate().ensureAnalytics(context, p.userId, knownTier: p.effectiveTier);
    if (!allowed || !context.mounted) return;
    await _push(context, MaterialPageRoute<void>(builder: (_) => AnalyticsScreen(userId: p.userId, tier: p.effectiveTier)));
  }

  static Future<void> openStorefrontEditor(BuildContext context, Profile p) =>
      _push(context, _withBloc(context, StorefrontEditorScreen(profile: p)));

  /// Public preview of the own storefront (isBusiness forced so it renders
  /// even before the account write settles).
  static Future<void> openStorefront(BuildContext context, Profile p) => _push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BusinessStorefrontScreen(business: p.copyWith(isBusiness: true), currentUserId: p.userId),
      ));

  static Future<void> openLeads(BuildContext context, Profile p) =>
      _push(context, MaterialPageRoute<void>(builder: (_) => BusinessLeadsScreen(businessId: p.userId)));

  static Future<void> openManageEvents(BuildContext context, Profile p) =>
      _push(context, MaterialPageRoute<void>(builder: (_) => BusinessEventsScreen(profile: p)));

  static Future<void> openGetPaid(BuildContext context, Profile p) => _push(context, GetPaidScreen.route(p.userId));

  static Future<void> openPaymentsToConfirm(BuildContext context, Profile p) =>
      _push(context, PaymentsToConfirmScreen.route(p.userId));

  static Future<void> openBookingRequests(BuildContext context, Profile p) => _push(
      context, BookingsListScreen.route(role: BookingRole.host, currentUserId: p.userId, openToConfirm: true));

  static Future<void> openFollowers(BuildContext context, Profile p) =>
      _push(context, FollowersScreen.route(businessId: p.userId));

  /// Door scanner: routes each scanned ticket to the right event's check-in.
  static Future<void> openScanner(BuildContext context, Profile p) =>
      _push(context, QrScanScreen.route(currentUserId: p.userId));

  static Future<void> openPromote(BuildContext context, Profile p) =>
      _push(context, MaterialPageRoute<void>(builder: (_) => PromoteScreen(business: p)));

  /// Fee invoices + monthly statements (also reachable while paused).
  static Future<void> openInvoices(BuildContext context) =>
      _push(context, MaterialPageRoute<void>(builder: (_) => const FinanceDocumentsScreen()));

  static Future<void> openVerification(BuildContext context, Profile p) =>
      _push(context, MaterialPageRoute<void>(builder: (_) => BusinessVerificationRequestScreen(profile: p)));

  /// Experiences are managed in My Space (owner, 2026-10-14: "that is the
  /// right page").
  static Future<void> openMySpace(BuildContext context, Profile p) =>
      _push(context, MySpaceScreen.route(currentUserId: p.userId));
}
