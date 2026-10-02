import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/display_image.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/external_event.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';

/// "Only elements with pictures are shown": one predicate per type.
void main() {
  group('DisplayImage.isUsableUrl', () {
    test('accepts absolute http(s) URLs with a host', () {
      for (final u in [
        'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg?alt=media',
        'http://s1.ticketm.net/dam/a/123/abc_RETINA_PORTRAIT_16_9.jpg',
        '  https://images.unsplash.com/photo-1?w=800  ',
        'https://picsum.photos/seed/x/800/600', // a real (random) photo
        'https://x/a.jpg',
      ]) {
        expect(DisplayImage.isUsableUrl(u), isTrue, reason: u);
      }
    });

    test('rejects null, blank, relative, non-http and host-less values', () {
      for (final u in <String?>[
        null,
        '',
        '   ',
        'null',
        '/images/a.jpg',
        'assets/images/event.png',
        'gs://bucket/a.jpg',
        'data:image/png;base64,AAAA',
        'file:///tmp/a.jpg',
        'https://',
        'https:///a.jpg',
        'not a url',
      ]) {
        expect(DisplayImage.isUsableUrl(u), isFalse, reason: '$u');
      }
    });

    test('rejects placeholder generators (and their subdomains)', () {
      for (final u in [
        'https://via.placeholder.com/600x400',
        'https://placehold.co/600x400?text=Event',
        'https://placehold.it/300',
        'https://dummyimage.com/600x400/000/fff',
        'https://fakeimg.pl/300/',
        'https://ui-avatars.com/api/?name=Ana',
        'https://CDN.PLACEHOLDER.COM/x.png',
      ]) {
        expect(DisplayImage.isUsableUrl(u), isFalse, reason: u);
      }
    });
  });

  group('per-type predicates', () {
    test('community event: its cover imageUrl only', () {
      Map<String, dynamic> ev(String? image, [List<String> photos = const []]) =>
          {'id': 'e', 'title': 't', 'imageUrl': image, 'photoUrls': photos};
      expect(eventHasPicture(EventModel.fromJson(ev('https://a/b.jpg'))),
          isTrue);
      expect(eventHasPicture(EventModel.fromJson(ev(null))), isFalse);
      expect(eventHasPicture(EventModel.fromJson(ev(''))), isFalse);
      // Gallery photos alone don't count: the card would show a blank cover.
      expect(
          eventHasPicture(
              EventModel.fromJson(ev(null, const ['https://a/extra.jpg']))),
          isFalse);
    });

    test('partner item (any source): imageUrl', () {
      ExternalEvent ext(String? image, [String source = 'ticketmaster']) =>
          ExternalEvent(
              id: 'x',
              source: source,
              title: 't',
              bookingUrl: 'https://b',
              imageUrl: image);
      expect(externalEventHasPicture(ext('https://s1.ticketm.net/a.jpg')),
          isTrue);
      expect(externalEventHasPicture(ext(null)), isFalse);
      expect(externalEventHasPicture(ext(' ', 'viator')), isFalse);
      expect(
          externalEventHasPicture(ext('https://via.placeholder.com/1', 'tiqets')),
          isFalse);
    });

    test('attraction: base + hash + token all present', () {
      Attraction attr({String b = 'attractions/IT/1', String h = 'abc', String tk = 't'}) =>
          Attraction.fromIndex(
              {'i': 1, 'n': 'Colosseum', 'iso': 'IT', 'b': b, 'h': h, 'tk': tk});
      expect(attractionHasPicture(attr()), isTrue);
      expect(attractionHasPicture(attr(b: '')), isFalse);
      expect(attractionHasPicture(attr(h: '')), isFalse);
      expect(attractionHasPicture(attr(tk: '')), isFalse);
    });

    test('member experience: mainPhotoUrl', () {
      expect(
          experienceHasPicture(UserExperienceModel.fromMap(
              'x', {'mainPhotoUrl': 'https://a/main.jpg'})),
          isTrue);
      expect(experienceHasPicture(UserExperienceModel.fromMap('x', {})),
          isFalse);
      expect(
          experienceHasPicture(
              UserExperienceModel.fromMap('x', {'mainPhotoUrl': 'blob:abc'})),
          isFalse);
    });
  });
}
