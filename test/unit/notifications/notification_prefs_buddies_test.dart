import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/notifications/data/models/notification_preferences_model.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification_preferences.dart';

/// The "Buddies" notification category: key `categories.buddies`, default ON
/// (same as the server's CATEGORY_DEFAULTS in functions/src/notifications/prefs.ts).
void main() {
  test('defaults to ON when never set, and round-trips through Firestore', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('notification_preferences').doc('u1').set({
      'pushEnabled': true,
      'categories': {'tips': true},
    });
    final m = NotificationPreferencesModel.fromFirestore(
        await db.collection('notification_preferences').doc('u1').get());
    expect(m.buddies, isTrue);

    final off = NotificationPreferencesModel.fromEntity(m.copyWith(buddies: false));
    expect((off.toFirestore()['categories'] as Map)['buddies'], isFalse);
    await db.collection('notification_preferences').doc('u1').set(off.toFirestore());
    final back = NotificationPreferencesModel.fromFirestore(
        await db.collection('notification_preferences').doc('u1').get());
    expect(back.buddies, isFalse);
    expect(back.tips, isTrue);
    expect(const NotificationPreferences(userId: 'x').buddies, isTrue);
  });
}
