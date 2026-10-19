import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/data/private_profile.dart';
import '../../profile/domain/entities/business_address.dart';
import '../domain/entities/globe_user.dart';
import 'models/globe_user_model.dart';

/// Caps of the network map reads (newest / most recent first). Bounded so a
/// popular account never pulls its whole graph on every open.
const int kGlobeFollowingCap = 300;
const int kGlobeFollowersCap = 300;
const int kGlobeChatsCap = 300;

/// One followed account: its id and the server's `isStore` mirror flag.
typedef GlobeFollowEdge = ({String id, bool isStore});

/// The network map's pins from the user's relations and the PUBLIC profiles
/// of those accounts. Pure (no I/O) so the rules are unit-tested:
///
///  * one pin per account; an account in several groups carries all of its
///    [GlobeRelation]s (badges), never a second pin;
///  * each group is capped ([kGlobeFollowingCap], [kGlobeFollowersCap],
///    [kGlobeChatsCap]) in the order given (newest first);
///  * the user, blocked accounts and accounts without a profile are skipped;
///  * BUSINESS accounts (`isBusiness`, or the follow mirror's `isStore`) are
///    pinned at their public business address with the business picture and
///    name; without a usable address they fall back to the people rules;
///  * PEOPLE keep the map's privacy positioning ([personPinFrom]): inactive,
///    incognito, ghost mode, "Hidden" and location-less users are left out.
List<GlobeUser> assembleNetworkPins({
  required String userId,
  required List<GlobeFollowEdge> following,
  required List<String> followers,
  required List<String> chats,
  required Map<String, Map<String, dynamic>> profiles,
  Set<String> blocked = const {},
  Random? random,
}) {
  final rng = random ?? Random();
  final relations = <String, Set<GlobeRelation>>{};
  final storeFlag = <String>{};

  void add(String id, GlobeRelation r) {
    if (id.isEmpty || id == userId || blocked.contains(id)) return;
    (relations[id] ??= <GlobeRelation>{}).add(r);
  }

  for (final c in chats.take(kGlobeChatsCap)) {
    add(c, GlobeRelation.chatted);
  }
  for (final e in following.take(kGlobeFollowingCap)) {
    add(e.id, GlobeRelation.following);
    if (e.isStore) storeFlag.add(e.id);
  }
  for (final f in followers.take(kGlobeFollowersCap)) {
    add(f, GlobeRelation.follower);
  }

  final pins = <GlobeUser>[];
  relations.forEach((id, rels) {
    final data = profiles[id];
    if (data == null) return;
    final isBusiness = data['isBusiness'] == true || storeFlag.contains(id);
    final pin = isBusiness
        ? (businessPinFrom(data, id, rng) ?? personPinFrom(data, id, rng))
        : personPinFrom(data, id, rng);
    if (pin == null) return;
    pins.add(pin.copyWith(relations: Set.unmodifiable(rels)));
  });
  return pins;
}

/// A business's pin at its PUBLIC business address (shown on its
/// storefront), or null when it has no usable address or is not active.
/// Picture: business logo, else storefront cover, else first gallery image,
/// else the first profile photo. Name: the business name, else the display
/// name.
GlobeUser? businessPinFrom(Map<String, dynamic> data, String id, Random rng) {
  if (data['accountStatus'] != 'active' || data['isBanned'] == true) {
    return null;
  }
  final address = BusinessAddress.fromMap(data['businessAddress']);
  if (address == null) return null;
  String? firstUrl(Object? v) {
    if (v is String) return v.trim().isEmpty ? null : v.trim();
    if (v is List) {
      for (final u in v) {
        if (u is String && u.trim().isNotEmpty) return u.trim();
      }
    }
    return null;
  }

  final photo = firstUrl(data['businessLogoUrl']) ??
      firstUrl(data['coverImageUrl']) ??
      firstUrl(data['galleryImages']) ??
      firstUrl(data['photoUrls']);
  final businessName = (data['businessName'] as String? ?? '').trim();
  final displayName = (data['displayName'] as String? ?? '').trim();
  final name = businessName.isNotEmpty
      ? businessName
      // i18n-ignore: data placeholder, shown localized by GlobeScreen
      : (displayName.isNotEmpty ? displayName : 'Unknown');
  return GlobeUser(
    userId: id,
    displayName: name,
    photoUrl: photo,
    pinLatitude: address.latitude,
    pinLongitude: address.longitude,
    country: address.country.isEmpty ? 'Unknown' : address.country,
    city: address.city.isEmpty ? 'Unknown' : address.city,
    pinType: GlobePinType.business,
    isOnline: data['isOnline'] as bool? ?? false,
    discoverability: GlobeDiscoverability.exact,
    isBusiness: true,
  );
}

/// A person's pin, or null when they must not be shown (inactive,
/// incognito, ghost mode, hidden from the map, unknown location). Other
/// users: public location only (security P1-4) — approxLocation, or the
/// ±100 m preciseLocation of users who chose exact discoverability.
GlobeUser? personPinFrom(
  Map<String, dynamic> profileData,
  String otherUserId,
  Random rng, {
  String? matchId,
}) {
  profileData = publicProfileView(profileData);
  try {
    if (profileData['accountStatus'] != 'active') return null;

    final isIncognito = profileData['isIncognito'] as bool? ?? false;
    if (isIncognito) {
      final incognitoExpiryTs = profileData['incognitoExpiry'] as Timestamp?;
      if (incognitoExpiryTs == null ||
          incognitoExpiryTs.toDate().isAfter(DateTime.now())) {
        return null;
      }
    }

    if (profileData['isGhostMode'] as bool? ?? false) return null;

    // "Hidden" (Globe Discoverability) promises "not discoverable on the
    // map", followers and chats included.
    if (profileData['globeDiscoverability'] == 'hidden') return null;

    final loc = profileData['location'] as Map<String, dynamic>?;
    final hasLocation = loc != null &&
        loc['latitude'] != null &&
        loc['longitude'] != null &&
        loc['country'] != null &&
        (loc['country'] as String?) != 'Unknown';
    if (!hasLocation) return null;

    return GlobeUserModel.fromFirestore(
      data: profileData,
      odcId: otherUserId,
      pinType: GlobePinType.matched,
      matchId: matchId,
      random: rng,
    );
  } catch (_) {
    return null; // Skip profiles that can't be parsed
  }
}

/// The other participant of a 1:1 conversation doc the user is in, when it
/// counts as a chat for the map: at least one message, not a support / group
/// thread, not deleted (for everyone or for the user), visible to the user.
String? chatPartnerOf(Map<String, dynamic> conv, String userId) {
  if (conv['lastMessage'] == null) return null;
  final type = conv['conversationType'] as String?;
  if (type == 'support' || type == 'group') return null;
  if (conv['isDeleted'] == true) return null;
  final deletedFor = conv['deletedFor'];
  if (deletedFor is Map && deletedFor.containsKey(userId)) return null;
  final visibleTo = conv['visibleTo'];
  if (visibleTo is List && !visibleTo.contains(userId)) return null;
  final u1 = conv['userId1'] as String?;
  final u2 = conv['userId2'] as String?;
  final other = u1 == userId ? u2 : (u2 == userId ? u1 : null);
  return (other == null || other.isEmpty || other == userId) ? null : other;
}
