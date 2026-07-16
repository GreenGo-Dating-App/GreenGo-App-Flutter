import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';

/// Master Test Plan — F5 Communities (tips/announcements classification).
/// Pure mapping tests for CommunityMessageType — these guard the tip vs
/// announcement vs chat partitioning that the detail tabs rely on.
void main() {
  group('CommunityMessageType wire mapping', () {
    test('value() emits the exact snake_case wire strings', () {
      expect(CommunityMessageType.text.value, 'text');
      expect(CommunityMessageType.image.value, 'image');
      expect(CommunityMessageType.languageTip.value, 'language_tip');
      expect(CommunityMessageType.culturalFact.value, 'cultural_fact');
      expect(CommunityMessageType.cityTip.value, 'city_tip');
      expect(CommunityMessageType.announcement.value, 'announcement');
      expect(CommunityMessageType.system.value, 'system');
    });

    test('fromString round-trips every known value', () {
      for (final t in CommunityMessageType.values) {
        expect(CommunityMessageTypeExtension.fromString(t.value), t);
      }
    });

    test('fromString falls back to text for unknown/garbage', () {
      expect(CommunityMessageTypeExtension.fromString('tip'),
          CommunityMessageType.text);
      expect(CommunityMessageTypeExtension.fromString(''),
          CommunityMessageType.text);
      expect(CommunityMessageTypeExtension.fromString('🤖'),
          CommunityMessageType.text);
    });
  });

  group('CommunityMessage classification (Tips/Announcements/Chat)', () {
    CommunityMessage msg(CommunityMessageType type) => CommunityMessage(
          id: 'm1',
          communityId: 'c1',
          senderId: 'u1',
          senderName: 'Ava',
          content: 'hi',
          sentAt: DateTime(2026, 7, 15),
          type: type,
        );

    test('language_tip / cultural_fact / city_tip are Tips (not chat)', () {
      for (final t in [
        CommunityMessageType.languageTip,
        CommunityMessageType.culturalFact,
        CommunityMessageType.cityTip,
      ]) {
        final m = msg(t);
        expect(m.isTip, isTrue, reason: '$t must be a tip');
        expect(m.isAnnouncement, isFalse);
      }
    });

    test('announcement is an announcement only (not tip, not chat)', () {
      final m = msg(CommunityMessageType.announcement);
      expect(m.isAnnouncement, isTrue);
      expect(m.isTip, isFalse);
    });

    test('text is chat (neither tip nor announcement)', () {
      final m = msg(CommunityMessageType.text);
      expect(m.isTip, isFalse);
      expect(m.isAnnouncement, isFalse);
    });
  });
}
