import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/entities/payment_links.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/payment_methods_editor.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  PaymentLinks? initial,
  required Future<bool> Function(PaymentLinks) onSave,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: PaymentMethodsEditor(initial: initial, onSave: onSave),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

ButtonStyleButton _saveButton(WidgetTester tester) => tester
    .widget<ButtonStyleButton>(find.byKey(const ValueKey('payment-methods-save')));

void main() {
  testWidgets('shows every payment method, incl. Mercado Pago and Stripe',
      (tester) async {
    await _pump(tester, onSave: (_) async => true);
    for (final m in PaymentMethod.values) {
      expect(find.widgetWithText(TextField, m.label), findsOneWidget,
          reason: m.label);
    }
  });

  testWidgets('Save is disabled until something changes, then saves '
      'normalized links', (tester) async {
    PaymentLinks? saved;
    await _pump(tester, onSave: (links) async {
      saved = links;
      return true;
    });
    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(
        find.widgetWithText(TextField, PaymentMethod.paypal.label),
        'https://paypal.me/greengo');
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('payment-methods-save')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.valueOf(PaymentMethod.paypal), isNotNull);
    // After a successful save nothing is pending any more.
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('invalid value is rejected without calling onSave',
      (tester) async {
    var calls = 0;
    await _pump(tester, onSave: (_) async {
      calls++;
      return true;
    });
    await tester.enterText(
        find.widgetWithText(TextField, PaymentMethod.paypal.label),
        'https://evil.example.com/x');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('payment-methods-save')));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
