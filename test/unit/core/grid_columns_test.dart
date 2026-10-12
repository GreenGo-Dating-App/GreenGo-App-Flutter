import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/grid_columns.dart';

void main() {
  group('gridColumnsForWidth (events / experiences / attractions / network)', () {
    test('3 below 800, 4 from 800, 6 from 1100', () {
      expect(gridColumnsForWidth(0), 3);
      expect(gridColumnsForWidth(360), 3);
      expect(gridColumnsForWidth(430), 3);
      expect(gridColumnsForWidth(799.9), 3);
      expect(gridColumnsForWidth(800), 4);
      expect(gridColumnsForWidth(1099.9), 4);
      expect(gridColumnsForWidth(1100), 6);
      expect(gridColumnsForWidth(1920), 6);
    });

    testWidgets('gridColumnsOf reads the screen width', (tester) async {
      Future<int> colsAt(double w) async {
        late int cols;
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(size: Size(w, 800)),
          child: Builder(builder: (context) {
            cols = gridColumnsOf(context);
            return const SizedBox();
          }),
        ));
        return cols;
      }

      expect(await colsAt(390), 3);
      expect(await colsAt(900), 4);
      expect(await colsAt(1440), 6);
    });
  });

  group('discovery column rule (width-based, same on web and app)', () {
    test('auto: 2/3/4/6/8 at <300/<450/<800/<1200/wider', () {
      expect(discoveryAutoColumns(280), 2);
      expect(discoveryAutoColumns(299.9), 2);
      expect(discoveryAutoColumns(300), 3);
      expect(discoveryAutoColumns(382), 3); // a phone (app or browser)
      expect(discoveryAutoColumns(449.9), 3);
      expect(discoveryAutoColumns(450), 4);
      expect(discoveryAutoColumns(799.9), 4);
      expect(discoveryAutoColumns(800), 6);
      expect(discoveryAutoColumns(1199.9), 6);
      expect(discoveryAutoColumns(1200), 8);
      expect(discoveryAutoColumns(1920), 8);
    });

    test('picker choices by width only; 3 is offered at every width', () {
      expect(discoveryColumnChoices(390), [0, 2, 3, 4]);
      expect(discoveryColumnChoices(799.9), [0, 2, 3, 4]);
      expect(discoveryColumnChoices(800), [0, 2, 3, 4, 6, 8]);
      expect(discoveryColumnChoices(1920), [0, 2, 3, 4, 6, 8]);
    });

    test('a choice no longer offered falls back to auto', () {
      expect(discoveryEffectiveChoice(8, 390), 0);
      expect(discoveryEffectiveChoice(6, 799), 0);
      expect(discoveryEffectiveChoice(3, 390), 3);
      expect(discoveryEffectiveChoice(3, 1440), 3);
      expect(discoveryEffectiveChoice(8, 1440), 8);
      expect(discoveryEffectiveChoice(5, 1440), 0); // never offered
    });

    test('rendered columns: explicit choice, else auto of the grid width', () {
      expect(discoveryColumns(selected: 0, screenWidth: 390, gridWidth: 382), 3);
      expect(discoveryColumns(selected: 0, screenWidth: 1440, gridWidth: 1432), 8);
      expect(discoveryColumns(selected: 2, screenWidth: 390, gridWidth: 382), 2);
      expect(discoveryColumns(selected: 3, screenWidth: 1440, gridWidth: 1432), 3);
      // 8 picked on a wide window, then the window shrank to phone width.
      expect(discoveryColumns(selected: 8, screenWidth: 390, gridWidth: 382), 3);
    });
  });
}
