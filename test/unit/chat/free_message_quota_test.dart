import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/services/free_message_quota.dart';

/// Owner rule 2026-10-25: without Base, 30 messages a day in total, each
/// committed in one batch with the counter (the Firestore rules check it).
void main() {
  const uid = 'u1';
  late FakeFirebaseFirestore fs;
  late FreeMessageQuota q;

  setUp(() {
    fs = FakeFirebaseFirestore();
    q = FreeMessageQuota(firestore: fs);
  });

  Future<void> send(String id, {DateTime? now}) => q.commitWith(
      uid, (b) => b.set(fs.doc('conversations/c1/messages/$id'), {'senderId': uid}),
      now: now);

  test('a message and the counter are written together', () async {
    expect(await q.remaining(uid), 30);
    await send('m1');
    expect((await fs.doc('conversations/c1/messages/m1').get()).exists, isTrue);
    final c = (await fs.doc('free_message_usage/$uid').get()).data()!;
    expect(c['count'], 1);
    expect(c['at'], isA<Timestamp>());
    expect(await q.remaining(uid), 29);
  });

  test('the 31st message of the day is refused before any write', () async {
    await fs.doc('free_message_usage/$uid').set({'at': Timestamp.now(), 'count': 29});
    await send('m30');
    expect(await q.remaining(uid), 0);
    await expectLater(send('m31'), throwsA(isA<FreeMessageLimitException>()));
    expect((await fs.doc('conversations/c1/messages/m31').get()).exists, isFalse);
  });

  test('a count from a previous UTC day starts again at 1', () async {
    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
    await fs.doc('free_message_usage/$uid').set({'at': Timestamp.fromDate(yesterday), 'count': 30});
    expect(await q.remaining(uid), 30);
    await send('m1');
    expect((await fs.doc('free_message_usage/$uid').get()).data()!['count'], 1);
  });

  test('UTC day start', () {
    final t = DateTime.utc(2026, 10, 25, 23, 59);
    expect(FreeMessageQuota.utcDayStartMs(t), DateTime.utc(2026, 10, 25).millisecondsSinceEpoch);
  });
}
