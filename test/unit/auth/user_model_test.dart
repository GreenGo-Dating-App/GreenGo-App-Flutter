import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/authentication/data/models/user_model.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart';

/// Master Test Plan — A. Authentication & Session (user identity mapping).
/// Pure model/entity tests for [User] and [UserModel] JSON round-tripping and
/// the Firebase `uid` compatibility getter that the rest of the app reads.
void main() {
  // DateTime has no const constructor, so this is a plain final.
  final fixedDate = DateTime(2026, 7, 15, 12);

  group('User entity', () {
    test('uid getter mirrors id (Firebase compatibility)', () {
      final user = User(
        id: 'abc123',
        email: 'ava@greengo.app',
        emailVerified: true,
        createdAt: fixedDate,
      );
      expect(user.uid, 'abc123');
      expect(user.uid, user.id);
    });

    test('is value-equal via Equatable on all props', () {
      final a = User(
        id: 'u1',
        email: 'a@b.com',
        emailVerified: false,
        createdAt: fixedDate,
      );
      final b = User(
        id: 'u1',
        email: 'a@b.com',
        emailVerified: false,
        createdAt: fixedDate,
      );
      expect(a, equals(b));
    });

    test('copyWith overrides only the provided fields', () {
      final user = User(
        id: 'u1',
        email: 'old@b.com',
        emailVerified: false,
        createdAt: fixedDate,
      );
      final updated = user.copyWith(email: 'new@b.com', emailVerified: true);
      expect(updated.email, 'new@b.com');
      expect(updated.emailVerified, isTrue);
      expect(updated.id, 'u1'); // untouched
    });
  });

  group('UserModel JSON mapping', () {
    test('fromJson applies safe defaults for missing fields', () {
      final model = UserModel.fromJson(const <String, dynamic>{});
      expect(model.id, '');
      expect(model.email, '');
      expect(model.emailVerified, isFalse);
      expect(model.displayName, isNull);
      expect(model.lastLoginAt, isNull);
    });

    test('fromJson parses ISO-8601 timestamps', () {
      final model = UserModel.fromJson(const {
        'id': 'u9',
        'email': 'clara@greengo.app',
        'emailVerified': true,
        'createdAt': '2026-01-02T03:04:05.000',
        'lastLoginAt': '2026-02-03T04:05:06.000',
      });
      expect(model.id, 'u9');
      expect(model.emailVerified, isTrue);
      expect(model.createdAt, DateTime.parse('2026-01-02T03:04:05.000'));
      expect(model.lastLoginAt, DateTime.parse('2026-02-03T04:05:06.000'));
    });

    test('toJson round-trips through fromJson', () {
      final original = UserModel(
        id: 'u2',
        email: 'diego@greengo.app',
        emailVerified: true,
        createdAt: fixedDate,
        displayName: 'Diego Alves',
        photoUrl: 'https://example.com/d.png',
      );
      final restored = UserModel.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.emailVerified, original.emailVerified);
      expect(restored.createdAt, original.createdAt);
    });

    test('toFirestore omits null lastLoginAt but keeps required keys', () {
      final model = UserModel(
        id: 'u3',
        email: 'elena@greengo.app',
        emailVerified: false,
        createdAt: fixedDate,
      );
      final map = model.toFirestore();
      expect(map['email'], 'elena@greengo.app');
      expect(map['emailVerified'], isFalse);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map['lastLoginAt'], isNull);
    });

    test('copyWith returns a UserModel (not a bare User)', () {
      final model = UserModel(
        id: 'u4',
        email: 'a@b.com',
        emailVerified: false,
        createdAt: fixedDate,
      );
      final copy = model.copyWith(displayName: 'Named');
      expect(copy, isA<UserModel>());
      expect(copy.displayName, 'Named');
    });
  });
}
