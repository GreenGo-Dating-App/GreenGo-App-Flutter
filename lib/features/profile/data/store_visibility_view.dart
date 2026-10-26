import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/own_profile_store.dart';
import '../domain/entities/store_visibility.dart';

/// Profile keys that make up the store face. Dropped (with `isBusiness`
/// forced false) when a fully hidden store is read by anyone but its owner.
const kStoreFaceKeys = <String>[
  'businessName', 'businessLegalName', 'businessLogoUrl', 'businessAddress',
  'businessCategory', 'businessWhatsapp', 'businessGeohash', 'storefrontBio',
  'storefrontLinks', 'businessVerified', 'isBusinessVerified', 'businessPromotedUntil',
];

/// The signed-in viewer, or null (tests, signed out). Overridable in tests.
String? Function() storeViewerUid = _defaultViewer;

String? _defaultViewer() {
  final own = OwnProfileStore.instance.uid;
  if (own != null && own.isNotEmpty) return own;
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null; // Firebase not initialised (unit tests).
  }
}

/// [json] as the viewer may see it: a [StoreVisibility.fullyHidden] store
/// reads as a personal profile for everyone except its owner, so every
/// screen that checks `isBusiness` shows the person, never the store. The
/// owner always gets the real document (Business Center keeps working).
Map<String, dynamic> storeViewFor(Map<String, dynamic> json) {
  if (json['isBusiness'] != true) return json;
  if (StoreVisibility.fromWire(json['storeVisibility']) != StoreVisibility.fullyHidden) return json;
  final viewer = storeViewerUid();
  if (viewer != null && viewer == json['userId']) return json;
  final out = Map<String, dynamic>.of(json)..['isBusiness'] = false;
  for (final k in kStoreFaceKeys) {
    out.remove(k);
  }
  return out;
}
