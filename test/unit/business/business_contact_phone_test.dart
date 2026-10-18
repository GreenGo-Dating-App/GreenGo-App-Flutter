import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/dial_codes.dart';
import 'package:greengo_chat/features/business/data/business_contact_phone.dart';

/// Optional business contact number (owner rule 2026-10-17): any country,
/// landline allowed, private unless "Show on my storefront" is on. Rules
/// mirror: businessContactPhoneOk / privateProfileShapeOk
/// (business-contact-phone.emulator.test.ts).
void main() {
  group('validation', () {
    test('E.164 numbers from any country, landlines included', () {
      expect(isValidBusinessContactPhone('+390212345678'), isTrue); // IT landline
      expect(isValidBusinessContactPhone('+912212345678'), isTrue); // IN
      expect(isValidBusinessContactPhone('+74951234567'), isTrue); // RU (contact only)
      expect(isValidBusinessContactPhone('+1234'), isFalse);
      expect(isValidBusinessContactPhone('0212345678'), isFalse);
      expect(isValidBusinessContactPhone('+0212345678'), isFalse);
      expect(isValidBusinessContactPhone('+1234567890123456'), isFalse);
      expect(isValidBusinessContactPhone(null), isFalse);
    });

    test('normalize from picker dial code + typed text', () {
      expect(normalizeBusinessContactPhone('+39', '02 1234 5678'),
          '+390212345678');
      expect(normalizeBusinessContactPhone('+44', '020 7946 0958'),
          '+442079460958');
      expect(normalizeBusinessContactPhone('+55', '(11) 3333-4444'),
          '+551133334444');
      expect(normalizeBusinessContactPhone('+351', '   '), '');
      expect(normalizeBusinessContactPhone('+351', '12'), isNull);
    });
  });

  group('writes', () {
    test('hidden: private only, public mirror cleared', () {
      final w = businessContactPhoneWrites(phone: '+351212345678', show: false);
      expect(w.private, {kBusinessContactPhoneField: '+351212345678'});
      expect(w.public,
          {kShowBusinessPhoneField: false, kBusinessContactPhoneField: null});
    });

    test('shown: public mirror written', () {
      final w = businessContactPhoneWrites(phone: '+351212345678', show: true);
      expect(w.public, {
        kShowBusinessPhoneField: true,
        kBusinessContactPhoneField: '+351212345678',
      });
    });

    test('removed: both cleared, switch forced off', () {
      final w = businessContactPhoneWrites(phone: null, show: true);
      expect(w.private, {kBusinessContactPhoneField: null});
      expect(w.public,
          {kShowBusinessPhoneField: false, kBusinessContactPhoneField: null});
    });

    test('invalid number throws', () {
      expect(() => businessContactPhoneWrites(phone: '12345', show: true),
          throwsArgumentError);
    });
  });

  test('storefront shows only a switched-on valid mirror', () {
    expect(
        publicBusinessContactPhone({
          kShowBusinessPhoneField: true,
          kBusinessContactPhoneField: '+351212345678',
        }),
        '+351212345678');
    expect(
        publicBusinessContactPhone({
          kShowBusinessPhoneField: false,
          kBusinessContactPhoneField: '+351212345678',
        }),
        isNull);
    expect(publicBusinessContactPhone({kShowBusinessPhoneField: true}), isNull);
    expect(publicBusinessContactPhone(null), isNull);
    // The account's verified phone is never a storefront number.
    expect(publicBusinessContactPhone({'verificationPhone': '+351912345678'}),
        isNull);
  });

  test('dial-code table round trip', () {
    expect(isoForE164('+390212345678'), 'IT');
    expect(isoForE164('+390212345678', preferred: 'VA'), 'VA');
    expect(isoForE164('+14155550123', preferred: 'CA'), 'CA');
    expect(isoForE164('+351212345678'), 'PT');
    expect(isoForE164('+447700900123'), 'GB');
    expect(kDialCodes.length, greaterThan(200));
  });
}
