// Cover position (owner 2026-10-21): focal point + zoom stored next to the
// cover URL, the drag maths of the positioning step, the client-side crop
// rectangle (storefront logo) and the recommended-size rules.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/media/cover_crop.dart';
import 'package:greengo_chat/core/media/cover_focus.dart';
import 'package:greengo_chat/core/widgets/cover_image_size_hint.dart';
import 'package:greengo_chat/core/widgets/cover_positioner.dart';
import 'package:greengo_chat/features/communities/data/models/community_model.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';

void main() {
  group('CoverFocus', () {
    test('missing fields (every doc before 5.0.52) = centre, no zoom', () {
      expect(CoverFocus.fromMap(const {}), CoverFocus.center);
      expect(CoverFocus.fromMap(null), CoverFocus.center);
      expect(CoverFocus.center.alignment, Alignment.center);
    });

    test('round-trips and clamps bad values', () {
      const f = CoverFocus(x: -0.5, y: 0.25, zoom: 1.4);
      expect(f.toMap(),
          {'coverFocalX': -0.5, 'coverFocalY': 0.25, 'coverZoom': 1.4});
      expect(CoverFocus.fromMap(f.toMap()), f);
      expect(
          CoverFocus.fromMap(const {
            'coverFocalX': 7,
            'coverFocalY': 'x',
            'coverZoom': 0.1,
          }),
          const CoverFocus(x: 1, y: 0, zoom: 1));
      expect(const CoverFocus(zoom: 9).clamped().zoom, CoverFocus.maxZoom);
    });

    test('community / event / experience models read and write the fields', () {
      const f = CoverFocus(x: 0.3, y: -0.6, zoom: 2);
      final c = CommunityModel.fromJson({'id': 'c', ...f.toMap()});
      expect(c.coverFocus, f);
      expect(CommunityModel.fromEntity(c).toFirestore()['coverFocalY'], -0.6);
      final e = EventModel.fromJson({
        'id': 'e',
        'startDate': DateTime(2026, 11, 1).toIso8601String(),
        'endDate': DateTime(2026, 11, 2).toIso8601String(),
        'createdAt': DateTime(2026, 10, 1).toIso8601String(),
        ...f.toMap(),
      });
      expect(e.coverFocus, f);
      expect(EventModel.fromEntity(e).toJson()['coverZoom'], 2);
      final x =
          UserExperienceModel.fromMap('x', {'mainPhotoUrl': 'u', ...f.toMap()});
      expect(x.coverFocus, f);
      expect(UserExperienceModel.editablePayload(x)['coverFocalX'], 0.3);
    });
  });

  group('positioning drag maths', () {
    const frame = Size(320, 180); // 16:9
    test('a wide picture moves horizontally only; drag right shows its left',
        () {
      const img = Size(4000, 1000); // 4:1 -> overflows in x
      final f = CoverPositionerScreen.applyDrag(
          CoverFocus.center, const Offset(40, 40), frame, img);
      expect(f.x, lessThan(0));
      expect(f.y, 0, reason: 'nothing to reveal vertically');
    });

    test('a tall picture moves vertically; zoom unlocks the other axis', () {
      const img = Size(1000, 2000);
      final f = CoverPositionerScreen.applyDrag(
          CoverFocus.center, const Offset(30, -50), frame, img);
      expect(f.x, 0);
      expect(f.y, greaterThan(0), reason: 'drag up shows the lower part');
      final z = CoverPositionerScreen.applyDrag(
          const CoverFocus(zoom: 2), const Offset(30, 0), frame, img);
      expect(z.x, lessThan(0));
    });

    test('a full drag reaches the edge and is clamped', () {
      const img = Size(4000, 1000);
      final f = CoverPositionerScreen.applyDrag(
          CoverFocus.center, const Offset(-5000, 0), frame, img);
      expect(f.x, 1);
    });
  });

  group('crop rectangle (= what a frame shows)', () {
    test('centre of a wide picture in a square', () {
      final r = coverSourceRect(const Size(2000, 1000), 1, CoverFocus.center);
      expect(r, const Rect.fromLTWH(500, 0, 1000, 1000));
    });
    test('left edge + zoom 2', () {
      final r = coverSourceRect(
          const Size(2000, 1000), 1, const CoverFocus(x: -1, zoom: 2));
      expect(r, const Rect.fromLTWH(0, 250, 500, 500));
    });
  });

  group('recommended size rules', () {
    test('16:9 banner: 1920 x 1080, small below 1200 px wide', () {
      const s = CoverImageSpec.banner;
      expect([s.width, s.height, s.ratioLabel], [1920, 1080, '16:9']);
      expect(s.evaluate(const Size(1920, 1080)), isNull);
      expect(s.evaluate(const Size(1600, 900)), isNull);
      expect(s.evaluate(const Size(4032, 3024)), isNull, reason: '4:3 is fine');
      final small = s.evaluate(const Size(600, 400))!;
      expect(small.small, isTrue);
      expect(small.badShape, isFalse);
      final portrait = s.evaluate(const Size(3024, 4032))!;
      expect(portrait.badShape, isTrue);
      expect(portrait.small, isFalse);
    });
    test('square logo: 1080 x 1080, circle', () {
      const s = CoverImageSpec.square;
      expect([s.width, s.height, s.ratioLabel, s.circular],
          [1080, 1080, '1:1', true]);
      expect(s.evaluate(const Size(1080, 1080)), isNull);
      expect(s.evaluate(const Size(400, 400))!.small, isTrue);
      expect(s.evaluate(const Size(1920, 1080))!.badShape, isTrue);
    });
    test('the upload ceiling is the storage.rules validUpload limit', () {
      expect(CoverImageSpec.maxUploadMb, 50);
    });
  });
}
