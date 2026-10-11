import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/effective_tier.dart';
import 'package:greengo_chat/core/services/own_profile_store.dart';
import 'package:greengo_chat/core/utils/base_membership_gate.dart';
import 'package:greengo_chat/core/widgets/base_membership_required_dialog.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../support/profile_fixtures.dart';

/// Owner rule (2026-10-11): joining events / booking experiences needs Base.
/// The app shows the Base-membership upsell INSTEAD of joining, and maps the
/// server's `base_membership_required` refusal to the same dialog.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final future = DateTime.now().add(const Duration(days: 30));
  const uid = 'participant_1';

  Future<BuildContext> pumpHost(WidgetTester tester, {Widget? child}) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return child ?? const SizedBox();
        }),
      ),
    ));
    return ctx;
  }

  /// A join button wired like the event / experience screens.
  Widget joinButton(String uid, ProfileModel profile, VoidCallback onJoined) =>
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            if (!await BaseMembershipGate.ensureCanParticipate(
                context: context, userId: uid, profile: profile)) {
              return;
            }
            onJoined();
          },
          child: const Text('Join'),
        ),
      );

  testWidgets('free user: the upsell is shown instead of joining',
      (tester) async {
    var joined = false;
    await pumpHost(tester,
        child: joinButton(uid, buildProfile(userId: uid) as ProfileModel,
            () => joined = true));
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joined, isFalse);
    expect(find.byKey(const ValueKey('base-membership-required-dialog')),
        findsOneWidget);
    expect(find.text(l10n.participationBaseRequiredTitle), findsOneWidget);
    expect(find.text(l10n.participationBaseRequiredBody), findsOneWidget);
    expect(find.text(l10n.participationBaseRequiredCta), findsOneWidget);

    await tester.tap(find.text(l10n.notNow));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('base-membership-required-dialog')),
        findsNothing);
    expect(joined, isFalse);
  });

  testWidgets('Base and paid-tier users join without any dialog',
      (tester) async {
    for (final p in [
      buildProfile(
          userId: uid, hasBaseMembership: true, baseMembershipEndDate: future),
      buildProfile(
          userId: uid,
          membershipTier: MembershipTier.silver,
          membershipEndDate: future),
    ]) {
      var joined = false;
      await pumpHost(tester,
          child: joinButton(uid, p as ProfileModel, () => joined = true));
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
      expect(joined, isTrue);
      expect(find.byType(BaseMembershipRequiredDialog), findsNothing);
    }
  });

  testWidgets('server refusal base_membership_required -> the same dialog',
      (tester) async {
    final ctx = await pumpHost(tester);
    final handled = BaseMembershipGate.handleParticipationError(ctx,
        userId: uid,
        error: FirebaseFunctionsException(
          code: 'failed-precondition',
          message: kBaseMembershipRequiredCode,
          details: {'code': kBaseMembershipRequiredCode},
        ));
    await tester.pumpAndSettle();
    expect(find.text(l10n.participationBaseRequiredTitle), findsOneWidget);
    await tester.tap(find.text(l10n.notNow));
    await tester.pumpAndSettle();
    expect(await handled, isTrue);
  });

  testWidgets('booking failure code (BookingFailure / TicketPaymentException)',
      (tester) async {
    final ctx = await pumpHost(tester);
    final handled = BaseMembershipGate.handleParticipationError(ctx,
        userId: uid, reason: kBaseMembershipRequiredCode);
    await tester.pumpAndSettle();
    expect(find.byType(BaseMembershipRequiredDialog), findsOneWidget);
    await tester.tap(find.text(l10n.notNow));
    await tester.pumpAndSettle();
    expect(await handled, isTrue);
  });

  testWidgets('other refusals are left to the caller', (tester) async {
    final ctx = await pumpHost(tester);
    expect(
        await BaseMembershipGate.handleParticipationError(ctx,
            userId: uid, reason: 'sold_out'),
        isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(BaseMembershipRequiredDialog), findsNothing);
  });

  testWidgets('lock hint: shown for a free own profile, hidden for Base',
      (tester) async {
    OwnProfileStore.instance.reset();
    await pumpHost(tester,
        child: const BaseMembershipRequiredHint(userId: 'hint_user'));
    // Unknown own profile: nothing.
    expect(find.text(l10n.participationBaseRequiredHint), findsNothing);

    OwnProfileStore.instance.seed('hint_user',
        (buildProfile(userId: 'hint_user') as ProfileModel).toJson());
    await tester.pump();
    expect(find.text(l10n.participationBaseRequiredHint), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    OwnProfileStore.instance.seed(
        'hint_user',
        (buildProfile(
                userId: 'hint_user',
                hasBaseMembership: true,
                baseMembershipEndDate: future) as ProfileModel)
            .toJson());
    await tester.pump();
    expect(find.text(l10n.participationBaseRequiredHint), findsNothing);
    OwnProfileStore.instance.reset();
  });
}
