import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/validators.dart';

/// Master Test Plan — A. Authentication & Session (input validation).
/// Pure-logic tests for the shared [Validators] used by the login, register,
/// forgot-password and change-password forms. These guard the exact accept /
/// reject boundaries the UI relies on for form gating.
void main() {
  group('Validators.validateEmail', () {
    test('rejects null and empty as required', () {
      expect(Validators.validateEmail(null), 'Email is required');
      expect(Validators.validateEmail(''), 'Email is required');
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        'plainaddress',
        'missing@tld',
        '@no-local.com',
        'spaces in@email.com',
        'no-at-sign.com',
        'trailing@dot.',
      ]) {
        expect(Validators.validateEmail(bad), 'Please enter a valid email',
            reason: '"$bad" must be rejected');
      }
    });

    test('accepts well-formed addresses (returns null)', () {
      for (final ok in [
        'ava@greengo.app',
        'bruno.costa@example.com',
        'user+tag@sub.domain.co',
        'A_B-c123@mail.io',
      ]) {
        expect(Validators.validateEmail(ok), isNull,
            reason: '"$ok" must be accepted');
      }
    });
  });

  group('Validators.validatePassword', () {
    test('rejects null / empty as required', () {
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword(''), 'Password is required');
    });

    test('enforces minimum length of 8', () {
      expect(Validators.validatePassword('Ab1!xy'),
          'Password must be at least 8 characters');
    });

    test('requires an uppercase letter', () {
      expect(Validators.validatePassword('abcdefg1!'),
          'Password must contain at least one uppercase letter');
    });

    test('requires a lowercase letter', () {
      expect(Validators.validatePassword('ABCDEFG1!'),
          'Password must contain at least one lowercase letter');
    });

    test('requires a digit', () {
      expect(Validators.validatePassword('Abcdefg!'),
          'Password must contain at least one number');
    });

    test('requires a special character', () {
      expect(Validators.validatePassword('Abcdefg1'),
          'Password must contain at least one special character');
    });

    test('accepts a strong compliant password (returns null)', () {
      expect(Validators.validatePassword('Str0ng!Pass'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('rejects empty confirmation', () {
      expect(Validators.validateConfirmPassword('', 'Str0ng!Pass'),
          'Please confirm your password');
    });

    test('rejects mismatch', () {
      expect(Validators.validateConfirmPassword('Other1!aa', 'Str0ng!Pass'),
          'Passwords do not match');
    });

    test('accepts exact match (returns null)', () {
      expect(
          Validators.validateConfirmPassword('Str0ng!Pass', 'Str0ng!Pass'),
          isNull);
    });
  });

  group('Validators.validatePhone', () {
    // NOTE: the production rule is "at least 10 digits after stripping
    // non-digits" (a permissive superset of E.164), not strict E.164.
    test('rejects null / empty', () {
      expect(Validators.validatePhone(null), 'Phone number is required');
      expect(Validators.validatePhone(''), 'Phone number is required');
    });

    test('rejects fewer than 10 digits', () {
      expect(Validators.validatePhone('+1 202-555'),
          'Phone number must be at least 10 digits');
    });

    test('accepts a formatted 10+ digit number, ignoring separators', () {
      expect(Validators.validatePhone('+1 (202) 555-0173'), isNull);
      expect(Validators.validatePhone('351912345678'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('rejects empty and too-short names', () {
      expect(Validators.validateName(''), 'Name is required');
      expect(Validators.validateName('A'), 'Name must be at least 2 characters');
    });

    test('rejects names with digits or symbols', () {
      expect(Validators.validateName('Ava3'),
          'Name can only contain letters and spaces');
    });

    test('accepts letters and spaces (returns null)', () {
      expect(Validators.validateName('Ava Reyes'), isNull);
    });
  });

  group('Validators.validateAge', () {
    test('rejects null and under-18 by default', () {
      expect(Validators.validateAge(null), 'Age is required');
      expect(Validators.validateAge(17), 'You must be at least 18 years old');
    });

    test('rejects impossible age and accepts a valid adult age', () {
      expect(Validators.validateAge(150), 'Invalid age');
      expect(Validators.validateAge(30), isNull);
    });
  });

  group('Validators.validateBio', () {
    test('treats empty/null bio as optional (returns null)', () {
      expect(Validators.validateBio(null), isNull);
      expect(Validators.validateBio(''), isNull);
    });

    test('rejects a bio over the max length', () {
      final tooLong = 'x' * 501;
      expect(Validators.validateBio(tooLong),
          'Bio must be less than 500 characters');
    });
  });

  group('Validators password strength meter', () {
    test('empty password scores 0 (Very Weak)', () {
      expect(Validators.getPasswordStrength(''), 0);
      expect(Validators.getPasswordStrengthLabel(0), 'Very Weak');
    });

    test('a long mixed password caps at 4 (Very Strong)', () {
      expect(Validators.getPasswordStrength('Str0ng!Password'), 4);
      expect(Validators.getPasswordStrengthLabel(4), 'Very Strong');
    });

    test('strength never exceeds the 0..4 range', () {
      final s = Validators.getPasswordStrength('A' * 40 + 'a1!');
      expect(s, inInclusiveRange(0, 4));
    });
  });
}
