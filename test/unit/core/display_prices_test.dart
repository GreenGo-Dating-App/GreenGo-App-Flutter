import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/display_prices.dart';

void main() {
  group('parseDisplayPrices (web shop prices from getDisplayPrices)', () {
    test('maps productId -> server display label (IT -> EUR)', () {
      final map = parseDisplayPrices({
        'prices': {
          'greengo_coins_100': {'display': '0,99 €', 'currency': 'EUR', 'amountCents': 99},
          '1_month_gold': {'display': '9,99 €', 'currency': 'EUR', 'amountCents': 999},
          'greengo_base_membership': {'display': '4,99 €', 'currency': 'EUR', 'amountCents': 499},
        },
      });
      expect(map, {
        'greengo_coins_100': '0,99 €',
        '1_month_gold': '9,99 €',
        'greengo_base_membership': '4,99 €',
      });
    });

    test('keeps BRL labels as the server formats them', () {
      final map = parseDisplayPrices({
        'prices': {
          'greengo_coins_100': {'display': r'R$ 4,99', 'currency': 'BRL', 'amountCents': 499},
        },
      });
      expect(map['greengo_coins_100'], r'R$ 4,99');
    });

    test('skips malformed entries, keeps the valid ones', () {
      final map = parseDisplayPrices({
        'prices': {
          'ok': {'display': r'$0.99'},
          'noDisplay': {'currency': 'USD'},
          'empty': {'display': '  '},
          'notAMap': 'oops',
          'number': {'display': 99},
        },
      });
      expect(map, {'ok': r'$0.99'});
    });

    test('null / unexpected payloads -> empty map (callers keep fallbacks)', () {
      expect(parseDisplayPrices(null), isEmpty);
      expect(parseDisplayPrices('x'), isEmpty);
      expect(parseDisplayPrices({'prices': null}), isEmpty);
      expect(parseDisplayPrices({'prices': ['a']}), isEmpty);
    });
  });
}
