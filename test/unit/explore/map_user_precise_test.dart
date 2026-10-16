import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/explore_map/data/models/map_user_model.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';

/// Explore map pins: approxLocation snapped to 3 decimals by default; the
/// ±100 m preciseLocation of users who chose 'exact' is used as is.
void main() {
  Future<MapUserModel> load(Map<String, dynamic> data) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('profiles').doc('u').set(data);
    return MapUserModel.fromFirestore(
        await fs.collection('profiles').doc('u').get());
  }

  final base = <String, dynamic>{
    'location': {'city': 'Rome', 'country': 'Italy'},
    kApproxLocationField: {'lat': 41.90123, 'lng': 12.49987},
  };

  test('default: approxLocation snapped, not precise', () async {
    final u = await load(base);
    expect(u.approximateLatitude, 41.901);
    expect(u.approximateLongitude, 12.5);
    expect(u.hasPreciseLocation, isFalse);
  });

  test('exact: preciseLocation as is, flagged precise', () async {
    final u = await load({
      ...base,
      'globeDiscoverability': 'exact',
      kPreciseLocationField: {'lat': 41.89934, 'lng': 12.47321},
    });
    expect(u.approximateLatitude, 41.89934);
    expect(u.approximateLongitude, 12.47321);
    expect(u.hasPreciseLocation, isTrue);
    expect(u.copyWith(distanceKm: 1.234).hasPreciseLocation, isTrue);
  });
}
