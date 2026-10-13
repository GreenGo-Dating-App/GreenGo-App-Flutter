import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/attraction_message.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Attraction _colosseum() => const Attraction(
      id: 401,
      slug: 'colosseum-rome',
      name: 'Colosseum',
      cityName: 'Rome',
      citySlug: 'rome',
      countryIso2: 'IT',
      imgBase: 'attractions/IT/401',
      imgHash: 'h',
      imgToken: 't',
      greengoScore: 99,
      scoreTier: 'iconic',
      names: {'en': 'Colosseum', 'it': 'Colosseo'},
    );

void main() {
  test('metadata + fallback text for a sent attraction', () {
    final m = ChatAttractionShare.metadataFor(_colosseum(), 'bucket');
    final a = ChatAttractionShare.of(m)!;
    expect(a['id'], 401);
    expect(a['score'], 99);
    expect(a['img'], contains('attractions%2FIT%2F401%2Fthumb-h.webp'));
    expect(ChatAttractionShare.contentFor(_colosseum(), const Locale('it')), startsWith('Colosseo · Rome\nhttps://'));
    expect(ChatAttractionShare.of({'text': 'x'}), isNull);
  });

  testWidgets('card shows the name in the app language, city and score', (tester) async {
    final a = ChatAttractionShare.of(ChatAttractionShare.metadataFor(_colosseum(), 'bucket'))!..remove('img');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AttractionMessageCard(attraction: a)),
    ));
    expect(find.text('Colosseo'), findsOneWidget);
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
    expect(find.byKey(const ValueKey('attraction-message-card')), findsOneWidget);
  });
}
