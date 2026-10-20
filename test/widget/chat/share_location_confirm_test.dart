import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/share_location_confirm.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Owner notes 2026-10-20: sharing a location in chat asks first
/// ("Are you sure you want to share your exact location?" Cancel / Share)
/// and only sends on Share.
void main() {
  Future<List<String>> run(WidgetTester tester, Locale locale,
      Future<void> Function() answer) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              // Same gate as ChatScreen / GroupChatScreen._sendLocation.
              if (await confirmShareLocation(context)) sent.add('location');
            },
            child: const Text('share'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await answer();
    await tester.pumpAndSettle();
    return sent;
  }

  testWidgets('Share sends', (tester) async {
    final sent = await run(tester, const Locale('en'), () async {
      expect(
          find.text('Are you sure you want to share your exact location?'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('share-location-confirm-share')));
    });
    expect(sent, ['location']);
    expect(find.byKey(const ValueKey('share-location-confirm')), findsNothing);
  });

  testWidgets('Cancel does not send', (tester) async {
    final sent = await run(tester, const Locale('en'), () async {
      await tester.tap(find.byKey(const ValueKey('share-location-cancel')));
    });
    expect(sent, isEmpty);
  });

  testWidgets('tapping outside does not send', (tester) async {
    final sent = await run(tester, const Locale('en'), () async {
      await tester.tapAt(const Offset(5, 5));
    });
    expect(sent, isEmpty);
  });

  testWidgets('localized (pt_BR)', (tester) async {
    await run(tester, const Locale('pt', 'BR'), () async {
      expect(
          find.text(
              'Tem certeza de que quer compartilhar sua localização exata?'),
          findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
    });
  });

  test('both chat screens ask before sending a location', () {
    for (final path in [
      'lib/features/chat/presentation/screens/chat_screen.dart',
      'lib/features/chat/presentation/screens/group_chat_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      final start = src.indexOf('Future<void> _sendLocation(');
      expect(start, isNonNegative, reason: path);
      final body = src.substring(start, src.indexOf('MessageType.location', start));
      expect(body, contains('confirmShareLocation(context)'), reason: path);
    }
  });
}
