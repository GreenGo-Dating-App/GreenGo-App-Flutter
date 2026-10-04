import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/user_error.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    ));
    return ctx;
  }

  setUp(resetUserErrorDialogGuard);

  testWidgets('shows a friendly popup instead of the raw error',
      (tester) async {
    final ctx = await pumpHost(tester);
    showUserError(ctx, const FormatException('error document format'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text(l10n.userErrorTitle), findsOneWidget);
    expect(find.text(l10n.userErrorGeneric), findsOneWidget);
    expect(find.textContaining('FormatException'), findsNothing);
    expect(find.textContaining('document format'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    // No retry callback -> only the OK button.
    expect(find.text(l10n.ok), findsOneWidget);
    expect(find.text(l10n.tryAgain), findsNothing);

    await tester.tap(find.text(l10n.ok));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(isUserErrorDialogOpen, isFalse);
  });

  testWidgets('does not stack duplicate dialogs', (tester) async {
    final ctx = await pumpHost(tester);
    showUserError(ctx, Exception('one'));
    await tester.pump();
    showUserError(ctx, Exception('two'));
    showUserErrorMessage(ctx, 'three');
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('three'), findsNothing);

    await tester.tap(find.text(l10n.ok));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Once closed, a new error can be shown again.
    showUserErrorMessage(ctx, 'three');
    await tester.pumpAndSettle();
    expect(find.text('three'), findsOneWidget);
  });

  testWidgets('Try again closes the popup and calls onRetry', (tester) async {
    final ctx = await pumpHost(tester);
    var retried = 0;
    showUserError(ctx, Exception('x'), onRetry: () => retried++);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();
    expect(retried, 1);
    expect(find.byType(Dialog), findsNothing);
  });
}
