import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/collapsible_how_it_works.dart';
import 'package:greengo_chat/core/widgets/helpful_empty_state.dart';
import 'package:greengo_chat/core/widgets/info_button.dart';
import 'package:greengo_chat/core/widgets/locked_reason_sheet.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four reusable "in-app explanation" widgets (+ the consequence sheet).
void main() {
  final l = AppLocalizationsEn();

  Widget app(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  /// A button that runs [onTap] with a context under the MaterialApp.
  Widget launcher(Future<void> Function(BuildContext) onTap) => app(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => onTap(context),
              child: const Text('open'),
            ),
          ),
        ),
      );

  group('InfoButton', () {
    testWidgets(
        'has a localized tooltip and opens a sheet with title, text and bullets',
        (t) async {
      await t.pumpWidget(app(const Center(
        child: InfoButton(
          title: 'Fees',
          message: 'Paid by the seller.',
          bullets: ['First bullet'],
        ),
      )));
      expect(find.byTooltip(l.xplMoreInfoAbout('Fees')), findsOneWidget);

      await t.tap(find.byType(InfoButton));
      await t.pumpAndSettle();
      expect(find.text('Fees'), findsOneWidget);
      expect(find.text('Paid by the seller.'), findsOneWidget);
      expect(find.text('First bullet'), findsOneWidget);

      await t.tap(find.text(l.xplGotIt));
      await t.pumpAndSettle();
      expect(find.text('Paid by the seller.'), findsNothing);
    });
  });

  group('HelpfulEmptyState', () {
    testWidgets('shows the sentence and runs the actions', (t) async {
      var primary = 0;
      var secondary = 0;
      await t.pumpWidget(app(HelpfulEmptyState(
        icon: Icons.event_busy,
        title: 'No events',
        message: 'Create one or widen your filters.',
        actions: [
          HelpfulEmptyAction(label: 'Create', onPressed: () => primary++),
          HelpfulEmptyAction(label: 'Widen', onPressed: () => secondary++),
        ],
      )));
      expect(find.text('No events'), findsOneWidget);
      expect(find.text('Create one or widen your filters.'), findsOneWidget);
      await t.tap(find.text('Create'));
      await t.tap(find.text('Widen'));
      expect(primary, 1);
      expect(secondary, 1);
    });

    testWidgets('works inside another scroll view (unbounded height)',
        (t) async {
      await t.pumpWidget(app(ListView(children: const [
        HelpfulEmptyState(icon: Icons.people_outline, message: 'Nobody yet.'),
      ])));
      expect(find.text('Nobody yet.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('allows at most two actions', (t) async {
      await t.pumpWidget(app(HelpfulEmptyState(
        icon: Icons.abc,
        message: 'x',
        actions: [
          for (var i = 0; i < 3; i++)
            HelpfulEmptyAction(label: '$i', onPressed: () {}),
        ],
      )));
      expect(t.takeException(), isA<AssertionError>());
    });
  });

  group('LockedReasonSheet', () {
    testWidgets('explains why and runs the action only when tapped', (t) async {
      var acted = 0;
      bool? result;
      await t.pumpWidget(launcher((c) async {
        result = await LockedReasonSheet.show(
          c,
          title: 'Album full',
          reason: 'Maximum 6 photos.',
          actionLabel: 'Upgrade',
          onAction: () => acted++,
        );
      }));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('Album full'), findsOneWidget);
      expect(find.text('Maximum 6 photos.'), findsOneWidget);
      // "Not now" closes without acting.
      await t.tap(find.text(l.notNow));
      await t.pumpAndSettle();
      expect(acted, 0);
      expect(result, isFalse);

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text('Upgrade'));
      await t.pumpAndSettle();
      expect(acted, 1);
      expect(result, isTrue);
    });

    testWidgets('without an action shows only "Got it"', (t) async {
      await t.pumpWidget(launcher((c) => LockedReasonSheet.show(
            c,
            title: 'Storefront not complete',
            reason: 'Add a business picture.',
          )));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text(l.xplGotIt), findsOneWidget);
      expect(find.text(l.notNow), findsNothing);
    });

    testWidgets('plan limit names the plan that unlocks it', (t) async {
      await t.pumpWidget(launcher((c) => LockedReasonSheet.showPlanRequired(
            c,
            userId: 'u1',
            reason: l.userErrorTierRequired,
            requiredTier: MembershipTier.gold,
          )));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text(l.xplLockedPlanTitle), findsOneWidget);
      expect(find.textContaining('Gold'), findsOneWidget);
      expect(find.text(l.xplSeePlans), findsOneWidget);
    });

    testWidgets('phone verification says why and offers Verify now', (t) async {
      var verify = 0;
      await t.pumpWidget(launcher((c) => LockedReasonSheet.showPhoneRequired(
            c,
            onVerify: () => verify++,
          )));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text(l.xplLockedPhoneTitle), findsOneWidget);
      expect(find.text(l.xplLockedPhoneBody), findsOneWidget);
      await t.tap(find.text(l.verifyNow));
      await t.pumpAndSettle();
      expect(verify, 1);
    });
  });

  group('ConsequenceConfirmSheet', () {
    testWidgets('lists the consequences; confirm -> true, cancel -> false',
        (t) async {
      bool? result;
      await t.pumpWidget(launcher((c) async {
        result = await ConsequenceConfirmSheet.show(
          c,
          title: 'Delete event',
          consequences: [l.xplDeleteEventRemoved, l.xplDeleteEventNoRefund],
          confirmLabel: 'Delete',
          destructive: true,
          confirmKey: const ValueKey('confirm'),
        );
      }));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text(l.xplDeleteEventNoRefund), findsOneWidget);
      await t.tap(find.text(l.cancel));
      await t.pumpAndSettle();
      expect(result, isFalse);

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('confirm')));
      await t.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('CollapsibleHowItWorks', () {
    testWidgets('expanded by default; collapsing is remembered per device',
        (t) async {
      SharedPreferences.setMockInitialValues({});
      Widget card() => app(const CollapsibleHowItWorks(
            id: 'test_card',
            steps: ['Step one', 'Step two'],
          ));
      await t.pumpWidget(card());
      await t.pumpAndSettle();
      expect(find.text(l.xplHowItWorks), findsOneWidget);
      expect(find.text('Step one'), findsOneWidget);

      await t.tap(find.text(l.xplHowItWorks));
      await t.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getBool(CollapsibleHowItWorks.prefsKey('test_card')), isTrue);

      // A fresh card (new screen visit) starts collapsed.
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(card());
      await t.pumpAndSettle();
      final fade = t.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));
      expect(fade.crossFadeState, CrossFadeState.showFirst);
    });
  });
}
