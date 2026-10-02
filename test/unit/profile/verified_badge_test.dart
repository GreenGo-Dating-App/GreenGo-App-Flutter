import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/core/widgets/verified_badge.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';

/// The ONE "Verified" badge means: GreenGo approved an ID document
/// (server-owned profiles.isAgeVerified) on an active account. The onboarding
/// account approval (verificationStatus / Profile.isVerified) never shows it.
void main() {
  group('UserVerifiedBadge.isVisible', () {
    test('unresolved brief -> hidden', () {
      expect(UserVerifiedBadge.isVisible(null), isFalse);
    });
    test('ID verified + active -> shown', () {
      expect(
          UserVerifiedBadge.isVisible(
              const UserBrief(name: 'Ana', idVerified: true)),
          isTrue);
    });
    test('ID verified but inactive (banned/deleted) -> hidden', () {
      expect(
          UserVerifiedBadge.isVisible(
              const UserBrief(name: 'Ana', idVerified: true, isActive: false)),
          isFalse);
    });
    test('not ID verified -> hidden', () {
      expect(UserVerifiedBadge.isVisible(const UserBrief(name: 'Ana')),
          isFalse);
    });
  });

  group('Profile.isIdVerified', () {
    Map<String, dynamic> json({Object? ageVerified, String status = 'approved'}) {
      final j = ProfileModel.fromEntity(buildProfile()).toJson();
      j['verificationStatus'] = status;
      if (ageVerified != null) j['isAgeVerified'] = ageVerified;
      return j;
    }

    test('parsed from the server-owned isAgeVerified flag', () {
      expect(ProfileModel.fromJson(json(ageVerified: true)).isIdVerified,
          isTrue);
      expect(ProfileModel.fromJson(json(ageVerified: false)).isIdVerified,
          isFalse);
      expect(ProfileModel.fromJson(json()).isIdVerified, isFalse);
      expect(ProfileModel.fromJson(json(ageVerified: 'true')).isIdVerified,
          isFalse);
    });

    test('account approval alone does NOT make the badge', () {
      final p = ProfileModel.fromJson(json(status: 'approved'));
      expect(p.isVerified, isTrue); // access gate unchanged
      expect(p.showVerifiedBadge, isFalse);
    });

    test('banned or inactive accounts never show it', () {
      final j = json(ageVerified: true);
      expect(ProfileModel.fromJson(j).showVerifiedBadge, isTrue);
      expect(ProfileModel.fromJson({...j, 'isBanned': true}).showVerifiedBadge,
          isFalse);
      expect(
          ProfileModel.fromJson({...j, 'accountStatus': 'suspended'})
              .showVerifiedBadge,
          isFalse);
    });

    test('never written by the client', () {
      final p = ProfileModel.fromEntity(
          buildProfile().copyWith(isIdVerified: true));
      final out = p.toJson();
      expect(out.containsKey('isIdVerified'), isFalse);
      expect(out.containsKey('isAgeVerified'), isFalse);
    });

    test('Profile entity defaults to not verified', () {
      expect(buildProfile().isIdVerified, isFalse);
      expect(buildProfile(), isA<Profile>());
    });
  });

  testWidgets('VerifiedBadge shows a localized tooltip and label',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: VerifiedBadge(showLabel: true)),
    ));
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.byTooltip('ID verified by GreenGo'), findsOneWidget);
  });
}
