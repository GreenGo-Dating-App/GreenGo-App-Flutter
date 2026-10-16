import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/menu_row.dart';
import 'package:greengo_chat/core/widgets/settings_accordion.dart';

void main() {
  Widget app({bool open = false}) => MaterialApp(
        home: Scaffold(
          body: SettingsAccordion(
            title: 'Account',
            icon: Icons.person,
            initiallyExpanded: open,
            children: [MenuRow(key: const ValueKey('row'), title: 'Email', onTap: () {})],
          ),
        ),
      );

  testWidgets('header is a menu row; tapping it opens and closes the section', (t) async {
    await t.pumpWidget(app());
    expect(find.byType(MenuRow), findsWidgets);
    expect(find.text('Email'), findsNothing);
    await t.tap(find.text('Account'));
    await t.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    await t.tap(find.text('Account'));
    await t.pumpAndSettle();
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('initiallyExpanded shows the rows', (t) async {
    await t.pumpWidget(app(open: true));
    expect(find.text('Email'), findsOneWidget);
  });
}
