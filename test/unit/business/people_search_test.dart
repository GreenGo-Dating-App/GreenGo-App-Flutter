import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/services/followers_audience_service.dart';
import 'package:greengo_chat/features/business/presentation/company_checklist.dart';
import 'package:greengo_chat/features/business/presentation/widgets/people_search.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';

import '../../support/profile_fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 15);
  final anna = PersonFacts(
    uid: 'a',
    name: 'Anna Rossi',
    profile: buildProfile(languages: const ['it', 'en']).copyWith(
        location: const Location(latitude: 1, longitude: 1, city: 'Roma', country: 'Italy', displayAddress: 'Roma')),
    addedAt: DateTime(2026, 10, 10),
    leadType: 'contact',
  );
  final joao = PersonFacts(
    uid: 'j',
    name: 'João Silva',
    profile: buildProfile(languages: const ['pt']).copyWith(
        location: const Location(latitude: 1, longitude: 1, city: 'Rio', country: 'Brazil', displayAddress: 'Rio')),
    addedAt: DateTime(2026, 6, 1),
    leadType: 'saved_event',
  );

  group('advanced search', () {
    test('name, case-insensitive, partial', () {
      const q = PeopleQuery(text: 'ross');
      expect(matchesPeopleQuery(anna, q, now), isTrue);
      expect(matchesPeopleQuery(joao, q, now), isFalse);
    });

    test('country, language, period, kind of contact', () {
      expect(matchesPeopleQuery(joao, const PeopleQuery(country: 'brazil'), now), isTrue);
      expect(matchesPeopleQuery(anna, const PeopleQuery(country: 'Brazil'), now), isFalse);
      expect(matchesPeopleQuery(anna, const PeopleQuery(language: 'en'), now), isTrue);
      expect(matchesPeopleQuery(joao, const PeopleQuery(language: 'en'), now), isFalse);
      expect(matchesPeopleQuery(anna, const PeopleQuery(sinceDays: 30), now), isTrue);
      expect(matchesPeopleQuery(joao, const PeopleQuery(sinceDays: 30), now), isFalse);
      expect(matchesPeopleQuery(joao, const PeopleQuery(leadType: 'saved_event'), now), isTrue);
      expect(matchesPeopleQuery(anna, const PeopleQuery(leadType: 'saved_event'), now), isFalse);
    });

    test('filters combine; empty query matches everyone', () {
      expect(matchesPeopleQuery(anna, const PeopleQuery(text: 'anna', country: 'Italy', sinceDays: 7), now), isTrue);
      expect(matchesPeopleQuery(anna, const PeopleQuery(text: 'anna', country: 'Brazil'), now), isFalse);
      expect(matchesPeopleQuery(joao, const PeopleQuery(), now), isTrue);
      expect(const PeopleQuery().isActive, isFalse);
      expect(const PeopleQuery(country: 'x', sinceDays: 7).filterCount, 2);
    });
  });

  test('listings: upcoming / active first, then past; events by date', () {
    final sorted = sortListings([
      AudienceListing(kind: 'event', id: 'old', title: 'Old', past: true, date: DateTime(2026, 1, 1)),
      AudienceListing(kind: 'event', id: 'later', title: 'Later', past: false, date: DateTime(2026, 12, 1)),
      const AudienceListing(kind: 'experience', id: 'tour', title: 'Tour', past: false),
      AudienceListing(kind: 'event', id: 'soon', title: 'Soon', past: false, date: DateTime(2026, 11, 1)),
      AudienceListing(kind: 'event', id: 'recent', title: 'Recent', past: true, date: DateTime(2026, 9, 1)),
      const AudienceListing(kind: 'experience', id: 'class', title: 'Class', past: true),
    ]);
    expect(sorted.map((l) => l.id), ['soon', 'later', 'tour', 'recent', 'old', 'class']);
  });

  group('company checklist', () {
    test('missing required items; unknown billing/payments are not reported missing', () {
      final p = buildBusinessProfile();
      final c = companyChecklist(p);
      expect(c[CompanyItem.name], isTrue);
      expect(c[CompanyItem.invoiceDetails], isNull);
      final missing = missingRequired(c);
      expect(missing, containsAll([CompanyItem.description, CompanyItem.address]));
      expect(missing, isNot(contains(CompanyItem.invoiceDetails)));
    });

    test('complete company', () {
      final p = buildBusinessProfile().copyWith(
        businessCategory: 'cafe',
        storefrontBio: 'Coffee and cake',
        businessAddress: const BusinessAddress(address: 'Rua A 1', latitude: -23.5, longitude: -46.6),
        galleryImages: const ['https://example.com/g1.jpg'],
        businessLogoUrl: 'https://example.com/logo.jpg',
      );
      expect(missingRequired(companyChecklist(p, billingComplete: true, paymentsConnected: true)), isEmpty);
      expect(missingRequired(companyChecklist(p, billingComplete: false, paymentsConnected: true)),
          [CompanyItem.invoiceDetails]);
    });
  });
}
