import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/membership/data/models/membership_model.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

/// Master Test Plan — Membership Firestore serialization.
/// Guards the tier UPPERCASE wire value on write and the tolerant parse on read
/// through a fake Firestore document.
void main() {
  final now = DateTime(2026, 7, 15, 8);

  test('MembershipModel round-trips through Firestore preserving the tier',
      () async {
    final db = FakeFirebaseFirestore();
    final model = MembershipModel(
      membershipId: 'ignored-on-write',
      userId: 'u1',
      tier: MembershipTier.gold,
      couponCode: 'WELCOME',
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      isActive: true,
      createdAt: now,
      updatedAt: now,
      activatedBy: 'admin_1',
    );

    await db.collection('memberships').doc('u1').set(model.toJson());
    final doc = await db.collection('memberships').doc('u1').get();
    final read = MembershipModel.fromFirestore(doc);

    expect(read.membershipId, 'u1'); // doc id wins on fromFirestore
    expect(read.userId, 'u1');
    expect(read.tier, MembershipTier.gold);
    expect(read.couponCode, 'WELCOME');
    expect(read.startDate, now);
    expect(read.endDate, now.add(const Duration(days: 30)));
    expect(read.isActive, isTrue);
    expect(read.activatedBy, 'admin_1');
  });

  test('tier is stored as the UPPERCASE wire value', () async {
    final db = FakeFirebaseFirestore();
    final model = MembershipModel(
      membershipId: 'm',
      userId: 'u2',
      tier: MembershipTier.platinum,
      startDate: now,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await db.collection('memberships').doc('u2').set(model.toJson());
    final raw =
        (await db.collection('memberships').doc('u2').get()).data()!;
    expect(raw['tier'], 'PLATINUM');
  });

  test('createFreeMembership builds an active FREE membership', () {
    final m = MembershipModel.createFreeMembership('u3');
    expect(m.tier, MembershipTier.free);
    expect(m.isActive, isTrue);
    expect(m.userId, 'u3');
    expect(m.endDate, isNull);
  });
}
