import '../../features/attractions/domain/entities/attraction.dart';
import '../../features/events/domain/entities/event.dart';
import '../../features/events/domain/entities/external_event.dart';
import '../../features/user_experiences/domain/entities/user_experience.dart';

/// "Only elements with pictures are shown to the final user."
///
/// ONE predicate per browsable type, used by every pager / datasource / cache
/// that feeds a public list (Events tabs, Attractions, Experiences, Explore
/// carousels, globe pins, search). Lists of the viewer's OWN items (My events,
/// My experiences) and detail pages opened by direct link do NOT apply it.
///
/// Rules:
///  * the item's MAIN image (the one its card renders) must be a non-empty,
///    absolute http(s) URL with a host;
///  * a URL from a placeholder GENERATOR (flat colour + text/initials, e.g.
///    placehold.co, via.placeholder.com, dummyimage.com, ui-avatars.com)
///    counts as no picture. Random-photo services (picsum.photos, unsplash)
///    render a real photograph, so they count as a picture, and so do
///    Ticketmaster's category "fallback" images (a real event photo of the
///    genre; the ingester now prefers the event's own image when one exists).
class DisplayImage {
  DisplayImage._();

  /// Hosts that only ever serve generated placeholder graphics.
  static const Set<String> placeholderHosts = {
    'placehold.co',
    'placehold.it',
    'placeholder.com',
    'via.placeholder.com',
    'dummyimage.com',
    'fakeimg.pl',
    'ui-avatars.com',
  };

  /// True when [url] can be shown as an item's picture.
  static bool isUsableUrl(String? url) {
    if (url == null) return false;
    final s = url.trim();
    if (s.isEmpty) return false;
    final uri = Uri.tryParse(s);
    if (uri == null) return false;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    for (final p in placeholderHosts) {
      if (host == p || host.endsWith('.$p')) return false;
    }
    return true;
  }
}

/// Community / business event: its cover ([Event.imageUrl]) — the image every
/// event card and tile renders. Extra gallery photos alone don't count (the
/// card would still show a blank cover).
bool eventHasPicture(Event e) => DisplayImage.isUsableUrl(e.imageUrl);

/// Partner item (ticketmaster / viator / tiqets / wikipedia): its imageUrl.
bool externalEventHasPicture(ExternalEvent e) =>
    DisplayImage.isUsableUrl(e.imageUrl);

/// Curated attraction: the image URL is composed from {base, hash, token}
/// (see [Attraction.imageUrl]), so all three must be present.
bool attractionHasPicture(Attraction a) =>
    a.imgBase.trim().isNotEmpty &&
    a.imgHash.trim().isNotEmpty &&
    a.imgToken.trim().isNotEmpty;

/// Member-hosted experience: its main photo (required by the editor and the
/// createUserExperience callable, so this only drops legacy/broken docs).
bool experienceHasPicture(UserExperience e) =>
    DisplayImage.isUsableUrl(e.mainPhotoUrl);
