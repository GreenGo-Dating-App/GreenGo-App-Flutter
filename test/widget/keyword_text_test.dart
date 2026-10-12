import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';
import 'package:greengo_chat/core/services/chat_datasets/keyword_matcher.dart';
import 'package:greengo_chat/features/chat/domain/message_insights.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/keyword_text.dart';

List<InlineSpan> _spans(WidgetTester t) {
  final rich = t.widget<RichText>(find.byType(RichText).first);
  return (rich.text as TextSpan).children?.first is TextSpan
      ? ((rich.text as TextSpan).children!.first as TextSpan).children ?? const []
      : const [];
}

void main() {
  setUp(() {
    ChatDatasets.instance.debugSet(
      keywords: KeywordIndex.fromJson({
        'a': {'1': ['IT', 'rome', 'Colosseum']},
        'c': {'IT:rome': ['Rome']},
        'k': {'IT': 'Italy'},
        'n': [
          ['colosseo', 'a', '1', 0],
          ['roma', 'c', 'IT:rome', 0],
        ],
      }),
    );
  });

  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('highlights keywords when on', (t) async {
    await t.pumpWidget(app(const KeywordText('Il Colosseo a Roma',
        style: TextStyle(color: Colors.white))));
    final texts = _spans(t).whereType<TextSpan>().map((s) => s.text).toList();
    expect(texts, ['Il ', 'Colosseo', ' a ', 'Roma']);
    final hit = _spans(t).whereType<TextSpan>().firstWhere((s) => s.text == 'Colosseo');
    expect(hit.recognizer, isNotNull);
  });

  testWidgets('plain text when highlighting is off', (t) async {
    await t.pumpWidget(app(const KeywordText('Il Colosseo a Roma',
        highlight: false, style: TextStyle(color: Colors.white))));
    expect(_spans(t), isEmpty);
    expect(find.text('Il Colosseo a Roma'), findsOneWidget);
  });

  test('MessageInsights stores entities and validates them', () {
    final meta = MessageInsights.metadataFor('Domani Colosseo', language: 'it');
    final stored = MessageInsights.storedEntities(meta, 'Domani Colosseo');
    expect(stored!.single.refs, ['1']);
    expect(MessageInsights.storedEntities(meta, 'short'), isEmpty);
    expect(MessageInsights.storedLevel({'level': 'B2'}), 'B2');
    expect(MessageInsights.storedLevel({'level': 'Z9'}), isNull);
  });
}
