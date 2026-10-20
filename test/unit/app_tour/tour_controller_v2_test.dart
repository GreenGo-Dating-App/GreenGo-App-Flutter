import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/app_tour/presentation/tour_controller.dart';
import 'package:greengo_chat/features/app_tour/presentation/widgets/tours_replay_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const uid = 'user-1';

  setUp(() {
    TourController.debugResetPrefsCache();
    SharedPreferences.setMockInitialValues({});
  });

  test('tour ids are unique and include every v2 page tour', () {
    const ids = TourController.allTourIds;
    expect(ids.toSet().length, ids.length);
    expect(ids.first, TourController.mainTourId);
    for (final id in [
      TourController.discoverTourId,
      TourController.eventTicketsTourId,
      TourController.businessCenterTourId,
      TourController.storefrontEditorTourId,
      TourController.followersOwnTourId,
      TourController.followersPublicTourId,
      TourController.chatExtrasTourId,
      TourController.communityDetailTourId,
      TourController.experienceGuestTourId,
      TourController.experienceHostTourId,
      TourController.experienceDatesTourId,
      TourController.coinShopTourId,
      TourController.privacyLocationTourId,
      TourController.getPaidTourId,
      TourController.mySpaceTourId,
      TourController.promoteTourId,
      TourController.safetyCenterTourId,
      TourController.safetyAppealTourId,
      TourController.verificationTourId,
      TourController.inviteFriendsTourId,
      TourController.attractionsTourId,
    ]) {
      expect(ids, contains(id));
    }
  });

  test('prefs are per user (and per device): tour_<id>_done_<uid>', () {
    expect(TourController.prefKeyFor('discover', uid),
        'tour_discover_done_user-1');
  });

  test('isTourDone / resetTour / resetAllTours on the new ids', () async {
    SharedPreferences.setMockInitialValues({
      'tour_discover_done_$uid': true,
      'tour_business_center_done_$uid': true,
      'tour_discover_done_other': true,
    });
    expect(await TourController.isTourDone('discover', uid), isTrue);
    expect(TourController.isPendingSync('discover', uid), isFalse);
    expect(TourController.isPendingSync('world_map', uid), isTrue);

    String? notified;
    void listener() => notified = TourController.instance.replayRequests.value;
    TourController.instance.replayRequests.addListener(listener);
    await TourController.instance.resetTour('discover', uid);
    TourController.instance.replayRequests.removeListener(listener);
    expect(notified, 'discover');
    expect(await TourController.isTourDone('discover', uid), isFalse);

    await TourController.resetAllTours(uid);
    expect(await TourController.isTourDone('business_center', uid), isFalse);
    // Another user's flags are untouched.
    expect(await TourController.isTourDone('discover', 'other'), isTrue);
  });

  test('App Guide lists every tour (swipe only on the full build)', () {
    final listed = tourEntries().map((e) => e.id).toList();
    expect(listed.toSet().length, listed.length);
    expect(TourController.allTourIds, containsAll(listed));
    final missing = TourController.allTourIds
        .where((id) => !listed.contains(id))
        .toList();
    expect(missing, anyOf(isEmpty, equals([TourController.swipeTourId])));
  });
}
