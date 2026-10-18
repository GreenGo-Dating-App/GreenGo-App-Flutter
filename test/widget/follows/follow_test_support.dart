import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Shared fakes for the follow widget tests: an in-memory Firestore behind a
/// real [FollowService] (registered in GetIt) and a seeded
/// [UserDirectoryService] (temp Hive dir, no network).
class FollowWorld {
  FollowWorld() : fs = FakeFirebaseFirestore() {
    // LastResultCache (list screen) opens a Hive box: give it a temp dir.
    if (!_hiveReady) {
      Hive.init(Directory.systemTemp.createTempSync('follow_test_').path);
      _hiveReady = true;
    }
    GetIt.instance.registerSingleton<FollowService>(
      FollowService(firestore: fs, overlay: FollowCountOverlay()),
    );
    UserDirectoryService.instance.debugReset();
  }

  static bool _hiveReady = false;

  final FakeFirebaseFirestore fs;
  int _t = 1000;

  /// Server counters - PRIVATE, in the owner-only `follow_counts/{uid}`.
  Future<void> counts(String uid,
          {int followers = 0, int following = 0, int stores = 0}) =>
      fs.collection('follow_counts').doc(uid).set({
        'followersCount': followers,
        'followingCount': following,
        'storesCount': stores,
      }, SetOptions(merge: true));

  /// [follower] follows [followee]; later calls are NEWER. Names are stamped
  /// the way the server does (already normalized).
  Future<void> follow(String follower, String followee,
      {String? followerName, String? followeeName}) async {
    final at = Timestamp.fromMillisecondsSinceEpoch(_t += 1000);
    await fs
        .collection('business_followers')
        .doc(followee)
        .collection('followers')
        .doc(follower)
        .set({
      'createdAt': at,
      if (followerName != null) 'followerNameLower': followerName,
    });
    await fs
        .collection('user_business_following')
        .doc(follower)
        .collection('businesses')
        .doc(followee)
        .set({
      'createdAt': at,
      if (followeeName != null) 'followeeNameLower': followeeName,
    });
  }

  void briefs(Map<String, UserBrief> b) =>
      UserDirectoryService.instance.debugSeed(b);

  Future<void> dispose() async {
    UserDirectoryService.instance.debugReset();
    await GetIt.instance.reset();
  }
}

Widget wrapForTest(Widget child, {double width = 320}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
