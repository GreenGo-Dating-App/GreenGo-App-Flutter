import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_text_warning.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Apple 4.3(b): the community create/edit form shows a gentle note while
/// dating wording is typed (it never blocks saving).
void main() {
  testWidgets('appears while dating wording is typed, disappears when removed',
      (tester) async {
    final name = TextEditingController();
    final description = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(children: [
          TextField(key: const Key('name'), controller: name),
          TextField(key: const Key('desc'), controller: description),
          CommunityTextWarning(controllers: [name, description]),
        ]),
      ),
    ));
    const warning = ValueKey('community-text-dating-warning');
    expect(find.byKey(warning), findsNothing);

    await tester.enterText(find.byKey(const Key('name')), 'Save the date: Lisbon meetup');
    await tester.pump();
    expect(find.byKey(warning), findsNothing, reason: 'event "date" is fine');

    await tester.enterText(find.byKey(const Key('desc')), 'Gringos para namorar');
    await tester.pump();
    expect(find.byKey(warning), findsOneWidget);
    expect(find.textContaining('friendship, culture and networking'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('desc')), 'Language exchange and food');
    await tester.pump();
    expect(find.byKey(warning), findsNothing);
  });
}
