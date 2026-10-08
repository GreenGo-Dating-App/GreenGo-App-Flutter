import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/payment_links.dart';
import 'package:greengo_chat/features/profile/domain/pix_br_code.dart';

void main() {
  group('pixCopiaECola', () {
    test('builds a valid static BR Code (CRC cross-checked vs BCB example)', () {
      expect(
        pixCopiaECola(
          pixKey: 'maria@example.com',
          receiverName: 'João da Silva',
          receiverCity: 'São Paulo',
        ),
        '00020126390014br.gov.bcb.pix0117maria@example.com5204000053039865802BR'
        '5913JOAO DA SILVA6009SAO PAULO62070503***6304DC19',
      );
    });

    test('caps name to 25 chars and falls back when city is empty', () {
      final code = pixCopiaECola(
        pixKey: '+5511987654321',
        receiverName: 'A very very long display name here',
      );
      expect(code, contains('5924A VERY VERY LONG DISPLAY6006'));
          });
  });

  group('PaymentMethod.normalize', () {
    test('handles and provider links', () {
      expect(PaymentMethod.paypal.normalize('@maria'), 'maria');
      expect(PaymentMethod.paypal.normalize('https://paypal.me/maria'), 'maria');
      expect(PaymentMethod.venmo.normalize('venmo.com/u/maria-s'), 'maria-s');
      expect(PaymentMethod.cashApp.normalize(r'$maria'), 'maria');
      expect(PaymentMethod.cashApp.normalize(r'https://cash.app/$maria'), 'maria');
      expect(PaymentMethod.wise.normalize('https://wise.com/pay/me/mariar'), 'mariar');
      expect(PaymentMethod.cashApp.url('maria'), r'https://cash.app/$maria');
    });

    test('rejects links from other domains (anti-phishing)', () {
      expect(PaymentMethod.paypal.normalize('https://paypa1.me/maria'), isNull);
      expect(PaymentMethod.revolut.normalize('https://evil.com/maria'), isNull);
      expect(PaymentMethod.stripe.normalize('https://evil.com/pay'), isNull);
      expect(PaymentMethod.mercadoPago.normalize('https://mercadopago.com.evil.io/x'), isNull);
      expect(PaymentMethod.paypal.normalize('has space'), isNull);
    });

    test('link-only providers keep the full https link', () {
      expect(PaymentMethod.mercadoPago.normalize('link.mercadopago.com.br/maria'),
          'https://link.mercadopago.com.br/maria');
      expect(PaymentMethod.mercadoPago.normalize('https://mpago.la/2abc'),
          'https://mpago.la/2abc');
      expect(PaymentMethod.stripe.normalize('https://buy.stripe.com/abc123'),
          'https://buy.stripe.com/abc123');
      expect(PaymentMethod.mercadoPago.normalize('maria'), isNull);
    });

    test('Pix keys', () {
      expect(PaymentMethod.pix.normalize('Maria@Example.com'), 'maria@example.com');
      expect(PaymentMethod.pix.normalize('529.982.247-25'), '52998224725'); // valid CPF
      expect(PaymentMethod.pix.normalize('123.456.789-00'), isNull); // bad CPF
      expect(PaymentMethod.pix.normalize('11.222.333/0001-81'), '11222333000181'); // valid CNPJ
      expect(PaymentMethod.pix.normalize('+55 (11) 98765-4321'), '+5511987654321');
      expect(PaymentMethod.pix.normalize('+1 555 123 4567'), isNull);
      expect(PaymentMethod.pix.normalize('123E4567-E12B-12D1-A456-426655440000'),
          '123e4567-e12b-12d1-a456-426655440000');
    });
  });

  group('PaymentLinksModel', () {
    test('round-trips, writes null for unset keys and ignores unknown keys', () {
      const links = PaymentLinks({PaymentMethod.pix: 'a@b.co', PaymentMethod.paypal: 'maria'});
      final json = PaymentLinksModel.fromEntity(links).toJson();
      expect(json['pix'], 'a@b.co');
      expect(json.containsKey('venmo'), isTrue);
      expect(json['venmo'], isNull);
      expect(PaymentLinksModel.fromJson({...json, 'gone': 'x'}).values, links.values);
    });
  });
}
