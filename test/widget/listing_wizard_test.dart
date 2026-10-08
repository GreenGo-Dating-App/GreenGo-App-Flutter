import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/listing_wizard.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Harness mirroring the event wizard: Basics (title required) -> Tickets
/// (free switch) -> Payment (skipped when free) -> Review.
class _Harness extends StatefulWidget {
  const _Harness({this.editMode = false, this.store});
  final bool editMode;
  final WizardDraftStore? store;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final title = TextEditingController();
  bool free = true;
  String? provider;

  @override
  void initState() {
    super.initState();
    final st = widget.store;
    if (st != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final d = await st.read();
        if (d == null || !mounted) return;
        if (await WizardDraftStore.askResume(context)) {
          setState(() => title.text = d['title'] as String? ?? '');
        } else {
          await st.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListingWizard(
          editMode: widget.editMode,
          onStepChanged: (_) => widget.store?.write({'title': title.text}),
          steps: [
            WizardStep(
              title: 'Basics',
              icon: Icons.edit,
              error: () => title.text.trim().isEmpty ? 'Add a title.' : null,
              summary: () => title.text,
              builder: (_) => TextField(key: const ValueKey('title'), controller: title, onChanged: (_) => setState(() {})),
            ),
            WizardStep(
              title: 'Tickets',
              icon: Icons.confirmation_number,
              builder: (_) => SwitchListTile(
                key: const ValueKey('free'),
                title: const Text('Free'),
                value: free,
                onChanged: (v) => setState(() => free = v),
              ),
            ),
            WizardStep(
              title: 'Payment',
              icon: Icons.payments,
              skip: free,
              error: () => provider == null ? 'Choose how to get paid.' : null,
              builder: (_) => TextButton(onPressed: () => setState(() => provider = 'link'), child: const Text('pick')),
            ),
            WizardStep(title: 'Review', icon: Icons.check, builder: (_) => const Text('REVIEW')),
          ],
        ),
      );
}

Widget _app(Widget child, {Size size = const Size(400, 800)}) => MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

ElevatedButton _next(WidgetTester t) => t.widget<ElevatedButton>(find.byKey(const ValueKey('wizard-next')));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Next is disabled until the step is valid, with the inline reason', (t) async {
    await t.pumpWidget(_app(const _Harness()));
    await t.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget); // payment skipped while free
    expect(_next(t).onPressed, isNull);
    expect(find.text('Add a title.'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('title')), 'Samba');
    await t.pump();
    expect(_next(t).onPressed, isNotNull);
    await t.tap(find.byKey(const ValueKey('wizard-next')));
    await t.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('payment step is skipped for free listings and required for paid ones', (t) async {
    await t.pumpWidget(_app(const _Harness()));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('title')), 'Samba');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('wizard-next')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('wizard-next')));
    await t.pumpAndSettle();
    expect(find.text('REVIEW'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('wizard-back')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('free')));
    await t.pumpAndSettle();
    expect(find.text('Step 2 of 4'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('wizard-next')));
    await t.pumpAndSettle();
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(_next(t).onPressed, isNull);
    expect(find.text('Choose how to get paid.'), findsOneWidget);
    await t.tap(find.text('pick'));
    await t.pump();
    expect(_next(t).onPressed, isNotNull);
  });

  testWidgets('edit mode opens the overview and "Edit" jumps to that step', (t) async {
    await t.pumpWidget(_app(const _Harness(editMode: true)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('wizard-overview-1')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('wizard-edit-1')));
    await t.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('free')), findsOneWidget);
  });

  testWidgets('draft autosave + resume restores the fields', (t) async {
    const store = WizardDraftStore('wizard_test');
    await store.write({'title': 'Half-written event'});
    await t.pumpWidget(_app(const _Harness(store: store)));
    await t.pumpAndSettle();
    expect(find.text('Continue your draft?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('wizard-resume')));
    await t.pumpAndSettle();
    expect(find.text('Half-written event'), findsOneWidget);
    expect(_next(t).onPressed, isNotNull);
    await t.tap(find.byKey(const ValueKey('wizard-next')));
    await t.pumpAndSettle();
    expect((await store.read())!['title'], 'Half-written event');
  });

  testWidgets('start over clears the draft', (t) async {
    const store = WizardDraftStore('wizard_test');
    await store.write({'title': 'Old'});
    await t.pumpWidget(_app(const _Harness(store: store)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('wizard-start-over')));
    await t.pumpAndSettle();
    expect(await store.read(), isNull);
  });

  testWidgets('wide screens: vertical stepper on the left', (t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(const _Harness(), size: const Size(1280, 900)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('wizard-side-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('wizard-chip-0')), findsNothing);
  });
}
